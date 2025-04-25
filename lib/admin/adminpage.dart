import 'package:flutter/material.dart';
import 'package:planotech/Customer/viewcontact.dart';
import 'package:planotech/Employee/add_employee.dart';
import 'package:planotech/Employee/employeedetail.dart';
import 'package:planotech/Employee/sendnotification.dart';
import 'package:planotech/admin/Addsalary.dart';
import 'package:planotech/admin/Holiday.dart';
import 'package:planotech/admin/SalarySlipPage.dart';
import 'package:planotech/admin/SetLocation.dart';
import 'package:planotech/admin/allanalytics.dart';
import 'package:planotech/admin/allattendance.dart';
import 'package:planotech/admin/compoff.dart';
import 'package:planotech/admin/viewallreport.dart';
import 'package:planotech/admin/viewcustreg.dart';
import 'package:planotech/admin/viewleads.dart';
import 'package:planotech/dashboard.dart';
import 'package:planotech/logout.dart';
import 'package:planotech/profile.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (_selectedIndex == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const Dashboard(),
          ),
        );
      } else if (_selectedIndex == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfilePage(),
          ),
        );
      } else if (_selectedIndex == 2) {
        _showLogoutConfirmationDialog();
      }
    });
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Logout(),
                  ),
                );
              },
              child: Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/san.jpg',
            fit: BoxFit.cover,
          ),
          SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Image.asset(
                    'assets/pp.png',
                    height: 80,
                    width: 400,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20.0),
                  const Text(
                    'Welcome to the Admin Dashboard!',
                    style: TextStyle(
                      fontSize: 24.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40.0),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    crossAxisSpacing: 15.0,
                    mainAxisSpacing: 20.0,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildCustomButton(
                        icon: Icons.leaderboard_sharp,
                        label: 'View Leads',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewLeadsPage(),
                            ),
                          );
                        },
                      ),
                      _buildCustomButton(
                        icon: Icons.co_present_outlined,
                        label: 'View Contact Us',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewContactPage(),
                            ),
                          );
                        },
                      ),
                      _buildCustomButton(
                        icon: Icons.group_add_rounded,
                        label: 'Add Employee',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddEmployee(),
                            ),
                          );
                        },
                      ),
                      _buildCustomButton(
                        icon: Icons.view_quilt,
                        label: 'View Employee Details',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ViewAllEmployeePage(),
                            ),
                          );
                        },
                      ),
                      _buildCustomButton(
                        icon: Icons.notification_add,
                        label: 'Notification',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SelectNotificationPage(),
                            ),
                          );
                        },
                      ),
                      _buildCustomButton(
                        icon: Icons.reviews_rounded,
                        label: 'View All Reports',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Viewallreport(),
                            ),
                          );
                        },
                      ),
                      _buildCustomButton(
                        icon: Icons.view_comfortable,
                        label: 'View All Attendance',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AttendancePage1(),
                            ),
                          );
                        },
                      ),
                      _buildCustomButton(
                        icon: Icons.preview_sharp,
                        label: 'View Customer Details',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewAllCustomerRegister(),
                            ),
                          );
                        },
                      ),
                      _buildCustomButton(
                        icon: Icons.analytics,
                        label: 'View all analytics',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AnalyticsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildCustomButton(
                        icon: Icons.post_add,
                        label: 'Holidays Declaration',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HolidayDeclaration(),
                            ),
                          );
                        },
                      ),
                      _buildCustomButton(
                        icon: Icons.location_on,
                        label: 'Set Location',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SetLocation(),
                            ),
                          );
                        },
                      ),
                      _buildCustomButton(
                        icon: Icons.money,
                        label: 'Add Salary',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Addsalary(),
                            ),
                          );
                        },
                      ),
                      _buildCustomButton(
                        icon: Icons.money_off_csred,
                        label: 'Non working \n days',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Compoff(),
                            ),
                          );
                        },
                      ),
                       _buildCustomButton(
                        icon: Icons.save,
                        label: 'Add Salary \n Slip',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SalarySlipPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color.fromARGB(255, 139, 12, 3),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildCustomButton({
    required IconData icon,
    required String label,
    required Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2), // Lighter button background
        borderRadius: BorderRadius.circular(15.0), // Soft, rounded corners
        border: Border.all(color: Colors.white, width: 2),
      ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(15),
              child: Icon(
                icon,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white, // Darker red color for the text
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
