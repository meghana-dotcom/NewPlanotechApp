import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:planotech/baseurl.dart';


class Addsalary extends StatefulWidget {
  const Addsalary({super.key});

  @override
  _AddsalaryState createState() => _AddsalaryState();
}

class _AddsalaryState extends State<Addsalary> {
  bool isLoading = false;
  String? errorMessage;
  final TextEditingController searchController = TextEditingController();
  String? selectedDepartment;
  List<Map<String, dynamic>> employeeData = [];
  List<Map<String, dynamic>> filteredData = [];

  final List<String> departments = [
    'IT',
    'Administration',
    'HR',
    'Sales and Marketing',
    'Design',
    'Finance and Accounts',
    'Production',
    'Operations-Support',
    'Interns',
  ];

  @override
  void initState() {
    super.initState();
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse(baseurl+'/admin/fetchallemployee'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status']) {
          setState(() {
            employeeData = List<Map<String, dynamic>>.from(data['userList']);
            filteredData = employeeData; // Initialize filteredData with all employees
          });
        } else {
          throw Exception('Failed to load employee data');
        }
      } else {
        throw Exception('Failed to load employee data');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
      print("API Exception: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _filterData() {
    String query = searchController.text.toLowerCase();
    String? departmentQuery =
        selectedDepartment != null && selectedDepartment != 'All Departments'
            ? selectedDepartment!.toLowerCase()
            : null;

    setState(() {
      filteredData = employeeData.where((employee) {
        String name = employee['userName']?.toString().toLowerCase() ?? '';
        String department =
            employee['userDepartment']?.toString().toLowerCase() ?? '';

        bool matchesName = name.contains(query);
        bool matchesDepartment =
            departmentQuery == null || department.contains(departmentQuery);

        return matchesName && matchesDepartment;
      }).toList();
    });
  }

Future<void> _updateSalary(String employeeId, String newSalary) async {
  setState(() {
    isLoading = true;
    errorMessage = null;
  });

  try {
    final url = Uri.parse(
        baseurl+'/admin/setemployeesalary?empId=$employeeId&salary=$newSalary');

    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;

    final request = await httpClient.postUrl(url);
    final response = await request.close();

    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final data = json.decode(responseBody);

      setState(() {
        // Update the employee's salary in the local list
        final index = employeeData.indexWhere((emp) => emp['userId']?.toString() == employeeId);
        if (index != -1) {
          employeeData[index]['salary'] = newSalary;
        }
        
        _filterData(); // Apply filtering again to maintain selection
      });

      print("API Response: $data"); // Print API response to console
    } else {
      setState(() {
        errorMessage = 'Failed to update salary. Status Code: ${response.statusCode}';
      });
      print("API Error: Status Code ${response.statusCode}");
      print("API Response Body: ${await response.transform(utf8.decoder).join()}");
    }
  } catch (e) {
    setState(() {
      errorMessage = 'Error: $e';
    });
    print("API Exception: $e");
  } finally {
    setState(() => isLoading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Salary Update'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: 'Search by Name',
                        hintText: 'Enter Name',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) => _filterData(),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedDepartment,
                      hint: const Text('Select Department'),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedDepartment = newValue;
                          _filterData();
                        });
                      },
                      items: departments
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelText: 'Filter by Department',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (errorMessage != null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            if (isLoading) const Center(child: CircularProgressIndicator()),
            if (!isLoading && errorMessage == null)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredData.length,
                itemBuilder: (context, index) {
                  final employee = filteredData[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left Side: Logo, Name, and Department
                        Flexible(
                          child: Row(
                            children: [
                              // Logo (CircleAvatar)
                              const CircleAvatar(
                                radius: 20,
                                backgroundImage: AssetImage(
                                    'assets/download.png'), // Your logo
                              ),
                              const SizedBox(width: 12),
                              // Name and Department
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      employee['userName']?.toString() ?? 'N/A',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                      maxLines: 2, // Allow text to wrap
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Department: ${employee['userDepartment']?.toString() ?? 'N/A'}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Right Side: Salary and Edit Button
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${employee['salary']?.toString() ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => _showEditSalaryDialog(employee),
                              child: const Text('Edit Salary'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showEditSalaryDialog(Map<String, dynamic> employee) {
    final TextEditingController salaryController = TextEditingController(
      text: employee['salary']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Salary'),
          content: TextField(
            controller: salaryController,
            decoration: InputDecoration(
              labelText: 'New Salary',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newSalary = salaryController.text;
                if (newSalary.isNotEmpty) {
                  // Show confirmation dialog
                  bool confirm = await _showConfirmationDialog(context);
                  if (confirm) {
                    _updateSalary(
                        employee['userId']?.toString() ?? '', newSalary);
                    Navigator.pop(context); // Close the edit salary dialog
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Confirm Update'),
              content:
                  const Text('Are you sure you want to update the salary?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        ) ??
        false; // Return false if the dialog is dismissed
  }
}