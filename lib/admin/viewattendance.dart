import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:planotech/baseurl.dart';

var Id;

class ViewAttendanceById extends StatefulWidget {
  ViewAttendanceById(var empId, {Key? key}) : super(key: key) {
    Id = empId;
    print(Id);
  }

  @override
  _ViewAttendanceByIdState createState() => _ViewAttendanceByIdState();
}

class _ViewAttendanceByIdState extends State<ViewAttendanceById> {
  late List<Map<String, dynamic>> _attendanceData;
  late List<Map<String, dynamic>> _filteredAttendanceData;
  late TextEditingController _searchController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _attendanceData = [];
    _filteredAttendanceData = [];
    _searchController = TextEditingController();
    fetchData();
  }

  Future<void> fetchData() async {
  var url = Uri.parse(
      baseurl+'/admin/fetchemployeeattendancebyemployeeid?empId=$Id');

  try {
    var response = await http.post(url);
    print(response.body);
    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == true) {
        setState(() {
          _attendanceData = List<Map<String, dynamic>>.from(jsonResponse['userList'] ?? [])
              // Filter out entries where the 'attendance' field is 'Holiday'
              .where((entry) => entry['attendance'] != 'Holiday')
              .toList();

          // Sort the attendance data by date in descending order
          _attendanceData.sort((a, b) {
            DateTime dateA = _parseCustomDate(a['date']);
            DateTime dateB = _parseCustomDate(b['date']);
            return dateB.compareTo(dateA); // For descending order
          });

          _filteredAttendanceData = _attendanceData;
          _isLoading = false; // Data is loaded, so set isLoading to false
        });
      }
    } else {
      throw Exception('Failed to fetch data');
    }
  } catch (error) {
    print('Error: $error');
  }
}


  DateTime _parseCustomDate(String date) {
    final parts = date.split('-');
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);
    return DateTime(year, month, day);
  }

  void _searchAttendanceData(String query) {
    setState(() {
      _filteredAttendanceData = _attendanceData.where((attendance) {
        return attendance['date'].contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'View Attendance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 30, 93, 209),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by Date',
                hintText: 'Enter a date...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchAttendanceData,
            ),
          ),
          _isLoading
              ? Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : Expanded(
                  child: _filteredAttendanceData.isEmpty
                      ? Center(
                          child: Text('No data found'),
                        )
                      : ListView.builder(
                          itemCount: _filteredAttendanceData.length,
                          itemBuilder: (context, index) {
                            var attendance = _filteredAttendanceData[index];
                            return Card(
                              elevation: 4,
                              margin: EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16.0),
                              child: ListTile(
                                title: Text(
                                  'Date: ${attendance['date']}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'day: ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(' ${attendance['day']}'),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'Time: ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text('${attendance['time']}'),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'Location: ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Expanded(
                                          child:
                                              Text('${attendance['address']}'),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'attendanceStatus: ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                              '${attendance['attendanceStatus']}'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ],
      ),
    );
  }
}
