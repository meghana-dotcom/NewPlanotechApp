import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:planotech/baseurl.dart';
import 'package:planotech/logout.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic> response = {};

  @override
  void initState() {
    super.initState();
    fetchStoredResponse();
  }

  Future<void> fetchStoredResponse() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedResponse = prefs.getString('response');
    if (storedResponse != null) {
      try {
        setState(() {
          response = json.decode(storedResponse);
        });
      } catch (e) {
        print("Error decoding stored response: $e");
      }
    } else {
      print("No stored response found.");
    }
  }

  Future<void> deleteAccount() async {
    if (response['body'] != null && response['body']['userEmail'] != null) {
      String url =
          baseurl+'/customer/customerdeleteaccount?email=${response['body']['userEmail']}';

      try {
        final response = await http.post(Uri.parse(url));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          if (data['status'] == true) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Account Deleted'),
                  content: Text(data['message']),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => Logout()),
                        );
                      },
                      child: Text('OK'),
                    ),
                  ],
                );
              },
            );
          } else {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Account Deletion Failed'),
                  content: Text(data['message']),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('OK'),
                    ),
                  ],
                );
              },
            );
          }
        } else {
          throw Exception('Failed to delete account');
        }
      } catch (e) {
        print("Error deleting account: $e");
      }
    } else {
      print("User email not found in SharedPreferences or response body is null.");
    }
  }

  Future<void> confirmDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete Account'),
          content: Text('Are you sure you want to delete your account?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != null && confirm) {
      deleteAccount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 34, 150, 243), // Blue color
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent,
                  image: DecorationImage(
                    image: AssetImage('assets/avatar.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Profile Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            _profileItem('Name', response.isNotEmpty ? response['body']['userName'] : 'N/A', Icons.person),
            const SizedBox(height: 10),
            _profileItem('Phone', response.isNotEmpty ? response['body']['userPhone'].toString() : 'N/A', Icons.phone),
            const SizedBox(height: 10),
            _profileItem('Email', response.isNotEmpty ? response['body']['userEmail'] : 'N/A', Icons.email),
            const Spacer(),
            if (response.isNotEmpty &&
                response['body'] != null &&
                response['body']['customerStatus'] != null &&
                response['body']['customerStatus'] is bool &&
                response['body']['customerStatus'])
              Center(
                child: ElevatedButton(
                  onPressed: confirmDeleteAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent, // Red color for the delete button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 30.0),
                    elevation: 5,
                  ),
                  child: Text(
                    'Delete Account',
                    style: TextStyle(fontSize: 16.0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _profileItem(String title, String subtitle, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 15.0),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        leading: Icon(
          icon,
          color: Color.fromARGB(255, 34, 150, 243), // Blue color
        ),
      ),
    );
  }
}
