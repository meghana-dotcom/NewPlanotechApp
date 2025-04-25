import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

import 'package:planotech/baseurl.dart';

class Reportpage extends StatefulWidget {
  final int empId;
  Reportpage(this.empId);
  @override
  _ReportpageState createState() => _ReportpageState();
}

class _ReportpageState extends State<Reportpage> {
  List<dynamic> _userList = [];
  List<dynamic> _filteredUserList = [];
  bool _isLoading = false;
  DateTime? _selectedDate;
  final DateTime today = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      _isLoading = true;
    });

    final response = await http.post(                                                                                              
      Uri.parse(baseurl+'/admin/fetchdailyemployeereportbyid?empId=${widget.empId}'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{'empId': widget.empId}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      setState(() {
        _userList = data['userList'] ?? [];
        _filteredUserList = _userList;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      throw Exception('Failed to load data');
    }
  }


  void filterByDate(DateTime? selectedDate) {
    setState(() {
      _selectedDate = selectedDate;
      if (_selectedDate == null) {
        _filteredUserList = List.from(_userList);
      } else {
        _filteredUserList = _userList.where((user) {
          try {
            final dateParts = (user['date'] ?? '').split('-');
            if (dateParts.length == 3) {
              final day = int.tryParse(dateParts[0]);
              final month = int.tryParse(dateParts[1]);
              final year = int.tryParse(dateParts[2]);
              if (day != null && month != null && year != null) {
                final userDate = DateTime(year, month, day);
                return userDate.toLocal().isAtSameMomentAs(_selectedDate!.toLocal());
              }
            }
            return false;
          } catch (e) {
            print('Error parsing date: $e');
            return false;
          }
        }).toList();
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      filterByDate(picked);
    }
  }

  void _openImageViewer(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen(imageUrl: imageUrl),
      ),
    );
  }


    void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }


  Future<void> _launchURL(String url) async {
    try {
      final tempDir = await getTemporaryDirectory();
      String fileName = url.split('/').last;
      String filePath = '${tempDir.path}/$fileName';

      // Download the file
      await Dio().download(url, filePath);

      // Open the file
      await OpenFile.open(filePath);
    } catch (e) {
      _showSnackbar('Error opening file: $e');
    }
  }

Widget _buildReportItem(dynamic user) {
  final dateStr = user['date'] ?? 'No date';
  final timeStr = user['time'] ?? '';
  final report = user['report'] ?? '';
  final imageUrl = user['imageLink'];
  final documentLink = user['documentLink'];

  DateTime? parsedDate;
  try {
    final dateParts = dateStr.split('-');
    if (dateParts.length == 3) {
      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final year = int.parse(dateParts[2]);
      parsedDate = DateTime(year, month, day);
    }
  } catch (e) {
    print('Error parsing date: $e');
  }

  final formattedDate = parsedDate != null
      ? '${parsedDate.day}-${parsedDate.month}-${parsedDate.year}'
      : 'Invalid date';
  final formattedTime = timeStr.isNotEmpty ? timeStr : 'Invalid time';

  return Card(
    color: Colors.grey.shade200,
    margin: EdgeInsets.all(8.0),
    elevation: 3.0,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text('Date: $formattedDate'),
          subtitle: Text('Time: $formattedTime\nReport: $report'),
        ),
        
        if (imageUrl != null && imageUrl.isNotEmpty)
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '➮ Click  :  Image: ${imageUrl.split('/').last}',
                        style: TextStyle(
                          color: Color.fromARGB(255, 63, 148, 218),
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            _openImageViewer(imageUrl);
                          },
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        if (documentLink != null && documentLink.isNotEmpty)
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '➮ Click  :  Document: ${documentLink.split('/').last}',
                        style: TextStyle(
                          color: Color.fromARGB(255, 63, 148, 218),
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            _launchURL(documentLink);
                          },
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        SizedBox(height: 16.0),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    readOnly: true,
                    onTap: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (selectedDate != null) {
                        _selectDate(context);
                      }
                    },
                    controller: TextEditingController(
                      text: _selectedDate != null
                          ? '${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}'
                          : '',
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Filter by Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredUserList.isEmpty
                      ? Center(
                          child: Text(
                            'No data available',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredUserList.length,
                          itemBuilder: (context, index) {
                            return _buildReportItem(_filteredUserList[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;

  ImageViewerScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Viewer'),
      ),
      body: Center(
        child: Image.network(imageUrl),
      ),
    );
  }
}


