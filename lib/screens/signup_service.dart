import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:planotech/baseurl.dart';

class Signup_Service {
  var mail = "";

  Future<http.Response> saveUser(
      BuildContext context,
      TextEditingController nameController,
      TextEditingController emailController,
      TextEditingController mobileController,
      TextEditingController passwordController,
      ) async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Center(
          child: CircularProgressIndicator(color: Colors.blueAccent,backgroundColor: Colors.blueGrey,),
        );
      },
    );

    var uri = Uri.parse(baseurl+"/customer/customersignup");

    Map<String, String> headers = {"Content-Type": "application/json"};

    Map data = {
      'userName': '${nameController.text}',
      'userEmail': '${emailController.text}',
      'userPhone': '${mobileController.text}',
      "userPassword": '${passwordController.text}',
    };

    mail = emailController.text;

    var body = json.encode(data);
    var response = await http.post(uri, headers: headers, body: body);

    // Close the dialog after getting the response
    Navigator.of(context).pop();

    // Check if response is successful
    if (response.statusCode == 200) {
      // Parse the response JSON
      var responseData = json.decode(response.body);
      // Check if status is false
      if (responseData['status'] == false) {
        // Handle the case where status is false, for example, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(child: Text(responseData['message'],)),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // Perform your action on successful response
        // For example, you might want to navigate to a new screen
        // You can add your navigation code here.
      }
    } else {
      // If the response is not successful, you can handle it here.
      // For example, you might want to show an error message to the user.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to register. Please try again later.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    return response;
  }

  String getMail() {
    return mail;
  }
}