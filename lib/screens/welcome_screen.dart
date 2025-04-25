import 'package:flutter/material.dart';
import 'package:planotech/dashboard.dart';
import 'package:planotech/screens/employee_login.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/hd.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 40.0,
              left: 10.0,
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Dashboard(),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            Column(
              children: [
                SizedBox(height: 180),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40.0),
                  child: const Text(
                    'Welcome to Planotech Events And Marketing',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 8.0,
                          color: Colors.black,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                // const Spacer(), // Pushes the buttons down but not all the way to the bottom
                SizedBox(height: 240,),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => EmployeeLogin()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                backgroundColor: const Color.fromARGB(255, 150, 38, 219),
                              ),
                              child: const Text(
                                'Employee Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          // Expanded(
                          //   child: ElevatedButton(
                          //     onPressed: () {
                          //       Navigator.push(
                          //         context,
                          //         MaterialPageRoute(
                          //             builder: (context) =>
                          //                 const Customer_login(email: '')),
                          //       );
                          //     },
                          //     style: ElevatedButton.styleFrom(
                          //       padding:
                          //           const EdgeInsets.symmetric(vertical: 14),
                          //       shape: RoundedRectangleBorder(
                          //         borderRadius: BorderRadius.circular(15),
                          //       ),
                          //       backgroundColor: const Color(0xFF6A1B9A),
                          //     ),
                          //     child: const Text(
                          //       'Customer Login',
                          //       style: TextStyle(
                          //         fontSize: 16,
                          //         color: Colors.white,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Dashboard(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6A1B9A),
                        ),
                        child: const Text(
                          'Go to Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30), // Adds some space below the buttons
              ],
            ),
          ],
        ),
      ),
    );
  }
}
