import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:planotech/baseurl.dart';

class Employeesalaryslip extends StatefulWidget {
  final String empId;

  const Employeesalaryslip({Key? key, required this.empId}) : super(key: key);

  @override
  State<Employeesalaryslip> createState() => _EmployeesalaryslipState();
}

class _EmployeesalaryslipState extends State<Employeesalaryslip> {
  String selectedMonth = 'All';
  String selectedYear = 'All';
  bool isLoading = false;

  List<Map<String, dynamic>> allSlips = [];
  List<Map<String, dynamic>> filteredSlips = [];
  Set<String> downloadingLinks = {};

  final List<String> months = [
    'All',
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  // Updated years list from 2022 to 2030
  final List<String> years = [
    'All',
    for (int year = 2022; year <= 2030; year++) year.toString()
  ];

  @override
  void initState() {
    super.initState();
    fetchAllSalarySlips();
  }

  Future<void> fetchAllSalarySlips() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(
        '${baseurl}/admin/fetchallsalaryslipbyempid?empId=${widget.empId}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['statusCode'] == 'FOUND' && data['userList'] != null) {
          allSlips = List<Map<String, dynamic>>.from(data['userList']);
          
          // Initially show all slips without filtering
          filteredSlips = List.from(allSlips);
          
          // Sort by date (newest first)
          filteredSlips.sort((a, b) {
            final dateA = '${a['date']} ${a['time']}';
            final dateB = '${b['date']} ${b['time']}';
            return dateB.compareTo(dateA);
          });
        } else {
          allSlips = [];
          filteredSlips = [];
        }
      } else {
        print('Server error: ${response.statusCode}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Server error: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      print('Error fetching slips: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void onFilterChange(String? month, String? year) {
    if (month != null) selectedMonth = month;
    if (year != null) selectedYear = year;

    setState(() {
      if (selectedMonth == 'All' && selectedYear == 'All') {
        filteredSlips = List.from(allSlips);
      } else {
        filteredSlips = allSlips.where((slip) {
          final monthMatch = selectedMonth == 'All' || 
                          slip['salaryMonth'] == selectedMonth;
          final yearMatch = selectedYear == 'All' || 
                          slip['salaryYear'].toString() == selectedYear;
          return monthMatch && yearMatch;
        }).toList();
      }
      
      // Sort by date (newest first)
      filteredSlips.sort((a, b) {
        final dateA = '${a['date']} ${a['time']}';
        final dateB = '${b['date']} ${b['time']}';
        return dateB.compareTo(dateA);
      });
    });
  }

  void openDocument(String url) async {
    setState(() {
      downloadingLinks.add(url);
    });

    try {
      Directory? dir;

      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir == null) throw Exception("Cannot find valid download directory.");

      final fileName = url.split('/').last;
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);

      if (!await file.exists()) {
        final response = await Dio().download(url, filePath);
        if (response.statusCode != 200) {
          throw Exception('Failed to download file');
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded Successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      await OpenFile.open(filePath);
    } catch (e) {
      print('Error downloading document: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not open or download document"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        downloadingLinks.remove(url);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Salary Slip',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 30, 93, 209),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filters
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Month',
                      border: OutlineInputBorder(),
                    ),
                    items: months.map((month) {
                      return DropdownMenuItem(
                        value: month,
                        child: Text(month),
                      );
                    }).toList(),
                    onChanged: (value) => onFilterChange(value, null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                    ),
                    items: years.map((year) {
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year),
                      );
                    }).toList(),
                    onChanged: (value) => onFilterChange(null, value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Display slips
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (filteredSlips.isEmpty)
              Text(
                selectedMonth == 'All' && selectedYear == 'All'
                  ? 'No salary slips available'
                  : 'No slips found for selected filters',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: filteredSlips.length,
                  itemBuilder: (context, index) {
                    final slip = filteredSlips[index];
                    final slipUrl = slip['salarySlipLink'];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.picture_as_pdf,
                            color: Colors.red, size: 32),
                        title: Text(
                          '${slip['salaryMonth']} ${slip['salaryYear']} Slip',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle:
                            Text('Date: ${slip['date']} | Time: ${slip['time']}'),
                        trailing: downloadingLinks.contains(slipUrl)
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : IconButton(
                                icon: const Icon(Icons.download_rounded,
                                    color: Colors.deepPurple),
                                onPressed: () => openDocument(slipUrl),
                              ),
                        onTap: () => openDocument(slipUrl),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
