import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:planotech/admin/adminpage.dart';
import 'package:planotech/notificationservice.dart';
import 'package:planotech/firebase_authorization_token.dart';

class Screen1 extends StatefulWidget {
  final List<String> notificationTokens;

  const Screen1({Key? key, required this.notificationTokens}) : super(key: key);

  @override
  State<Screen1> createState() => _Screen1State();
}

class _Screen1State extends State<Screen1> {
  final _formKey = GlobalKey<FormState>(); // GlobalKey for form validation
  NotificationServices notificationServices = NotificationServices();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  AccessTokenFirebase accessTokenFirebase = AccessTokenFirebase();
  String accessToken = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> getAccessToken() async {
    String token = await accessTokenFirebase.getAccessToken();
    setState(() {
      accessToken = token;
      print("---------------------------------------");
      print(accessToken);
      print("----------------------------------------");
    });
  }

  void sendNotification() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Validate the form
      if (accessToken.isEmpty) {
        await getAccessToken();
        if (accessToken.isEmpty) {
          print('Failed to get access token.');
          return;
        }
      }

      setState(() {
        isLoading = true;
      });

      String title = _titleController.text;
      String body = _bodyController.text;

      for (String token in widget.notificationTokens) {
        if (token.isEmpty) {
          print('Skipping empty token.');
          continue;
        }
        var data = {
          "message": {
            "notification": {
              "body": body,
              "title": title,
            },
            "token": token, // Use individual token here
          }
        };
        print(token);
        print(
            "--------------------------------------------------------------------------++++++");
        print("---------" + body + "" + title);

        try {
          final response = await http.post(
            Uri.parse(
                'https://fcm.googleapis.com/v1/projects/notification-86c27/messages:send'),
            body: jsonEncode(data),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $accessToken',
            },
          );

          if (kDebugMode) {
            print('Response: ${response.body}');
          }
        } catch (error) {
          if (kDebugMode) {
            print('Error sending notification: $error');
          }
        }
      }

      setState(() {
        isLoading = false; // Stop showing loader
      });

      // Show snackbar and navigate after a delay
      Get.snackbar(
        'Success',
        'Notifications sent successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[400],
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Wait for the snackbar to be displayed and then navigate
      Future.delayed(const Duration(seconds: 2), () {
        Get.to(() => AdminPage());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Notification',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 139, 12, 3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: Form(
              key: _formKey, // Assign the key to the form
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTextFieldContainer(
                    labelText: 'Notification Title',
                    child: TextFormField(
                      controller: _titleController, // Assigning controller
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please Add Title';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextFieldContainer(
                    labelText: 'Notification Message',
                    child: TextFormField(
                      controller: _bodyController, // Assigning controller
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please Add Message';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            sendNotification(); // Call sendNotification on press
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 139, 12, 3),
                        ),
                        child: const Text(
                          'Send Notification',
                          style: TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextFieldContainer(
      {required String labelText, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labelText,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          child,
        ],
      ),
    );
  }
}
