import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:planotech/baseurl.dart';
import 'package:planotech/screen1.dart';


class ViewAllEmployee {
  final int userId;
  final String userName;
  final String userEmail;
  final int userPhone;
  final String userDepartment;
  final String notificationToken;
  bool isSelected;

  ViewAllEmployee({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.userDepartment,
    required this.notificationToken,
    this.isSelected = false,
  });
}

class SelectNotificationPage extends StatefulWidget {
  const SelectNotificationPage({Key? key}) : super(key: key);

  @override
  State<SelectNotificationPage> createState() => _SelectNotificationPageState();
}

class _SelectNotificationPageState extends State<SelectNotificationPage> {
  List<ViewAllEmployee> employeeList = [];
  List<ViewAllEmployee> filteredEmployeeList = [];
  String? responseMessage;
  bool? responseStatus;
  String? selectedDepartment;
  bool selectAllChecked = false; 
// Track the state of Select All checkbox

  final List<Color> avatarColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
    Colors.blueGrey,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
     setState(() {
    });
    final String apiUrl = baseurl+'/admin/fetchallemployee';

    try {
      final http.Response response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({}),
      );

      var data = jsonDecode(response.body);

      if (data != null && data['userList'] != null) {
        setState(() {
          employeeList = List<ViewAllEmployee>.from(
            data['userList'].map((user) => ViewAllEmployee(
                  userId: user['userId'] ?? 0,
                  userName: user['userName'] ?? 'N/A',
                  userEmail: user['userEmail'] ?? 'N/A',
                  userPhone: user['userPhone'] ?? 0,
                  userDepartment: user['userDepartment'] ?? 'N/A',
                  notificationToken: user['notificationToken'] ?? 'N/A',
                )),
          );
          filteredEmployeeList = List<ViewAllEmployee>.from(employeeList);
          responseMessage = data['message'];
          responseStatus = data['status'];
        });
      } else {
        print('Failed to load data: Invalid response format');
      }
    } catch (e) {
      print('Failed to load data: $e');
    }
  }

  void filterEmployees(String searchText, String? selectedDepartment) {
    setState(() {
      filteredEmployeeList = employeeList.where((employee) {
        final nameLower = employee.userName.toLowerCase();
        final departmentMatches = selectedDepartment == null ||
            selectedDepartment.isEmpty ||
            selectedDepartment == 'ALL' ||
            employee.userDepartment == selectedDepartment;
        final nameMatches = nameLower.contains(searchText.toLowerCase());
        return departmentMatches && nameMatches;
      }).toList();
    });
  }

  void navigateToScreen1() {
    final selectedTokens = filteredEmployeeList
        .where((employee) => employee.isSelected)
        .map((employee) => employee.notificationToken)
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>  Screen1(notificationTokens: selectedTokens),
      ),
    );
  }

  void selectAll(bool isSelected) {
    setState(() {
      selectAllChecked = isSelected;
      filteredEmployeeList.forEach((employee) {
        employee.isSelected = isSelected;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('All Employees'),
        backgroundColor: Color.fromARGB(255, 139, 12, 3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.send),
            onPressed: navigateToScreen1,
          ),
        ],
      ),
      body: Column(
        children: [
          
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                filterEmployees(value, selectedDepartment);
              },
              decoration: InputDecoration(
                labelText: 'Search by name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              value: selectedDepartment,
              hint: Text('Filter by department'),
              onChanged: (value) {
                setState(() {
                  selectedDepartment = value;
                  filterEmployees('', selectedDepartment);
                });
              },
              items: <String>[
                'ALL', // Add ALL option
                'IT',
                'Administration',
                'HR',
                'Sales and Marketing',
                'Design',
                'Finance and Accounts',
                'Production',
                'Operations-Support',
                'Interns',
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
                    Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 40),
                child: Row(
                  children: [
                    Checkbox(
                      value: selectAllChecked,
                      onChanged: (bool? value) {
                        selectAll(value ?? false);
                      },
                    ),
                    Text('Select All'),
                  ],
                ),
              ),
            ],
          ),

          Expanded(
            child: ListView.builder(
              itemCount: filteredEmployeeList.length,
              itemBuilder: (context, index) {
                Color color = avatarColors[index % avatarColors.length];

                return ListTile(
                  title: Text(filteredEmployeeList[index].userName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${filteredEmployeeList[index].userEmail}'),
                      Text('Phone: ${filteredEmployeeList[index].userPhone}'),
                      Text(
                        'Department: ${filteredEmployeeList[index].userDepartment}',
                      ),
                    ],
                  ),
                  leading: CircleAvatar(
                    backgroundColor: color,
                    child: Text(
                      filteredEmployeeList[index].userName[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  trailing: Checkbox(
                    value: filteredEmployeeList[index].isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        filteredEmployeeList[index].isSelected = value ?? false;
                      });
                    },
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