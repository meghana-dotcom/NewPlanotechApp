import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:planotech/admin/analytics.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart'; // For accessing device storage
import 'package:open_file/open_file.dart';
import 'package:planotech/baseurl.dart'; // For opening the saved file

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> employees = [];
  List<Map<String, dynamic>> filteredEmployees = [];
  Map<String, Map<String, dynamic>> attendanceData = {};
  bool isLoading = true;

  final AttendanceAnalytics _attendanceService = AttendanceAnalytics();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  TextEditingController _searchController = TextEditingController();

  String? selectedMonth;
  int? selectedYear;

  final List<String> monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _searchController.addListener(_filterEmployees);
    fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    try {
      final employeeList = await fetchEmployees();
      final now = DateTime.now();

      employeeList.sort((a, b) => a['userName'].compareTo(b['userName']));

      final futures = employeeList.map((employee) async {
        final userId = employee['userId'].toString();
        final monthIndex = selectedMonth != null
            ? monthNames.indexOf(selectedMonth!) + 1
            : now.month;
        final analytics = await _attendanceService.getAttendanceAnalytics(
            userId, monthIndex, selectedYear ?? now.year);
        return MapEntry(userId, analytics);
      }).toList();

      final results = await Future.wait(futures);

      setState(() {
        employees = employeeList;
        filteredEmployees = employeeList;
        attendanceData = Map.fromEntries(results);
        isLoading = false;
      });

      _animationController.forward(); // Start the fade animation
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchEmployees() async {
    final response = await http
        .post(Uri.parse(baseurl+'/admin/fetchallemployee'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status']) {
        return List<Map<String, dynamic>>.from(data['userList']);
      } else {
        throw Exception('Failed to load employee data');
      }
    } else {
      throw Exception('Failed to load employee data');
    }
  }

  void _filterEmployees() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredEmployees = employees.where((employee) {
        final userName = employee['userName'].toLowerCase();
        return userName.contains(query);
      }).toList();
    });
  }

  void _selectMonth(String? month) {
    if (month != null) {
      setState(() {
        selectedMonth = month;
        isLoading = true; // Set loading to true
        fetchData(); // Fetch new data based on the selected month
      });
    }
  }

  void _selectYear(int? year) {
    if (year != null) {
      setState(() {
        selectedYear = year;
        isLoading = true; // Set loading to true
        fetchData(); // Fetch new data based on the selected year
      });
    }
  }

  Future<void> _exportToExcel() async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      // Add headers
      sheet.appendRow([
        'Employee Name',
        'Present',
        'Absent',
        'Late',
      ]);

      // Add data rows
      for (final employee in filteredEmployees) {
        final userId = employee['userId'].toString();
        final analytics = attendanceData[userId] ?? {};
        sheet.appendRow([
          employee['userName'],
          analytics['Present'] ?? 0,
          analytics['Absent'] ?? 0,
          analytics['Late'] ?? 0,
        ]);
      }

      // Save the Excel file to device storage
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/attendance_analytics.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      // Open the file after saving
      OpenFile.open(filePath);

      // Show success message
      _showSnackbar('Excel file downloaded successfully.');
    } catch (e) {
      _showSnackbar('Error exporting to Excel: $e');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 139, 12, 3),
        title: Text('Attendance Analytics',
            style:
                TextStyle(fontWeight: FontWeight.normal, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _exportToExcel,
            tooltip: 'Download Excel',
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search Employees...',
                        prefixIcon: Icon(Icons.search,
                            color: Color.fromARGB(255, 139, 12, 3)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      DropdownButton<String?>(
                        value: selectedMonth,
                        hint: Text('Month'),
                        items: monthNames.map((String month) {
                          return DropdownMenuItem<String>(
                            value: month,
                            child: Text(month),
                          );
                        }).toList(),
                        onChanged: _selectMonth,
                      ),
                      DropdownButton<int?>(
                        value: selectedYear,
                        hint: Text('Year'),
                        items: List.generate(5, (index) {
                          int year = DateTime.now().year - index;
                          return DropdownMenuItem(
                            value: year,
                            child: Text('$year'),
                          );
                        }),
                        onChanged: _selectYear,
                      ),
                    ],
                  ),
                  Expanded(
                    child: filteredEmployees.isEmpty
                        ? Center(
                            child: Text('No data available.',
                                style: TextStyle(fontSize: 18.0)))
                        : ListView.builder(
                            padding: EdgeInsets.all(16.0),
                            itemCount: filteredEmployees.length,
                            itemBuilder: (context, index) {
                              final employee = filteredEmployees[index];
                              final userId = employee['userId'].toString();
                              final analytics = attendanceData[userId] ?? {};

                              return Card(
                                margin: EdgeInsets.symmetric(vertical: 12.0),
                                elevation:
                                    8.0, // Increased elevation for a more prominent shadow
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      16.0), // Rounded corners
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.all(20.0),
                                  title: Text(
                                    employee['userName'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize:
                                          18.0, // Larger font size for title
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'Present: ${analytics['Present'] ?? 0}, Absent: ${analytics['Absent'] ?? 0}, Late: ${analytics['Late'] ?? 0}',
                                      style: TextStyle(
                                          fontSize:
                                              16.0), // Slightly larger font for subtitle
                                    ),
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        Color.fromARGB(255, 139, 12, 3),
                                    child: Text(
                                      employee['userName'][0].toUpperCase(),
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
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