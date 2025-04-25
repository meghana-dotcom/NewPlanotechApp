import 'package:flutter/material.dart';
import 'package:planotech/firebase_authorization_token.dart';

// Assuming your AccessTokenFirebase class is defined in a separate file

class AccessTokenWidget extends StatefulWidget {
  @override
  _AccessTokenWidgetState createState() => _AccessTokenWidgetState();
}

class _AccessTokenWidgetState extends State<AccessTokenWidget> {
  String accessToken = '';

  // Instance of your AccessTokenFirebase class
  AccessTokenFirebase accessTokenFirebase = AccessTokenFirebase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Access Token Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                // Call your method to get access token
                String token = await accessTokenFirebase.getAccessToken();
                setState(() {
                  accessToken = token;
                  print("---------------------------------------");
                  print(accessToken);
                  print("----------------------------------------");
                });
              },
              child: Text('Get Access Token'),
            ),
            SizedBox(height: 20),
            Text(
              'Access Token:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              accessToken,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

