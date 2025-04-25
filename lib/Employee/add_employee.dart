import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:planotech/baseurl.dart'; 

class AddEmployee extends StatefulWidget {
  const AddEmployee({Key? key}) : super(key: key);

  @override
  State<AddEmployee> createState() => _AddEmployeeState();
}

class _AddEmployeeState extends State<AddEmployee> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController employeeNameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController userDepartmentController = TextEditingController();
  TextEditingController dobController = TextEditingController(); 
  List<dynamic> userList = [];
  String? responseMessage;
  bool? responseStatus;
  String? selectedDepartment;
  bool _isLoading = false; 

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
    fetchData();
    selectedDepartment = departments[0]; 
  }

  void fetchData() async {
  }

  void showSnackBar(String message, bool isSuccess) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: isSuccess ? Colors.green : Colors.red,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void addUser() async {
    setState(() {
      _isLoading = true; 
    });

    try {
      Map<String, dynamic> userData = {
        'userName': employeeNameController.text.trim(),
        'userPhone': phoneNumberController.text.trim(),
        'userEmail': emailController.text.trim(),
        'userDepartment': selectedDepartment,
        'userPassword': phoneNumberController.text.trim(),
        'dob': dobController.text.trim(), 
      };

      String jsonData = jsonEncode(userData);

      final http.Response response = await http.post(
        Uri.parse(baseurl+'/admin/addemployee'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonData,
      );

      var responseData = jsonDecode(response.body);
      bool isSuccess = responseData['status'];

      showSnackBar(isSuccess
          ? 'User added successfully'
          : 'Failed to add user', isSuccess);

      if (isSuccess) {
        employeeNameController.clear();
        phoneNumberController.clear();
        emailController.clear();
        dobController.clear(); 

        setState(() {
          selectedDepartment = departments[0]; 
        });
      }

      if (isSuccess) {
        fetchData();
      }
    } catch (e) {
      print('Failed to add member: $e');
    } finally {
      setState(() {
        _isLoading = false; 
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      String formattedDate = DateFormat('dd-MM-yyyy').format(pickedDate);
      setState(() {
        dobController.text = formattedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Add Employee',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 139, 12, 3),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 25),
                    TextFormField(
                      maxLength: 30,
                      controller: employeeNameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelText: 'Name',
                        hintText: 'Enter Employee name',
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 25),
                    TextFormField(
                      controller: phoneNumberController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelText: 'Phone Number',
                        hintText: 'Enter your mobile number',
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your mobile number';
                        }
                        if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                          return 'Please enter a valid 10-digit mobile number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    TextFormField(
                      maxLength: 35,
                      controller: emailController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: const Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        } else if (!RegExp(
                            r"^[a-zA-Z0-9.a-zA-Z0-9,!#$%&'*+-/=?^_`{|~}]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                            .hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 25),
                    TextFormField(
                      controller: dobController,
                      readOnly: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelText: 'Date of Birth',
                        hintText: 'Select Date of Birth',
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      onTap: () => _selectDate(context),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select date of birth';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 25),
                    DropdownButtonFormField(
                      value: selectedDepartment,
                      items: departments.map((String department) {
                        return DropdownMenuItem(
                          value: department,
                          child: Text(department),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDepartment = value as String?;
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelText: 'Department',
                        prefixIcon: const Icon(Icons.work),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a department';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            addUser();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 139, 12, 3),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}