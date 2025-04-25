import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:planotech/Employee/Employeesalaryslip.dart';
import 'package:planotech/Employee/Nonworkingday.dart';
import 'package:planotech/Employee/addleads.dart';
import 'package:planotech/Employee/addreport.dart';
import 'package:planotech/admin/allanalytics.dart';
import 'package:planotech/admin/allattendance.dart';
import 'package:planotech/admin/analytics.dart';
import 'package:planotech/admin/viewallreport.dart';
import 'package:planotech/admin/viewattendance.dart';
import 'package:planotech/admin/viewleads.dart';
import 'package:planotech/baseurl.dart';
import 'package:planotech/dashboard.dart';
import 'package:planotech/logout.dart';
import 'package:planotech/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:planotech/notificationservice.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

var attendanceStatus = '';

class EmployeeDashboard extends StatefulWidget {
  @override
  _EmployeeDashboardState createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  void _onRefresh() async {
    await Future.delayed(Duration(seconds: 4));
    _refreshController.refreshCompleted();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => EmployeeDashboard()),
    );
  }

  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _comOffReasonController = TextEditingController();

  NotificationServices notificationServices = NotificationServices();
  void initializeNotifications() async {
    await notificationServices.requestNotificationPermission(context);
    notificationServices.isTokenRefreshed((newToken) {
      _sendTokenToBackend(newToken);
    });
    String? deviceToken = await notificationServices.getDeviceToken();
    if (deviceToken != null) {
      print("==========");
      print("Device token: $deviceToken");
      print("==========");
      _sendTokenToBackend(deviceToken);
    } else {
      print("Failed to get device token.");
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _comOffReasonController.dispose();
    super.dispose();
  }

  Future<void> _sendTokenToBackend(String token) async {
    var empId = this.empId;
    var url = Uri.parse(
        baseurl+'/emp/employeenotificationtoken?empId=$empId&token=$token');

    var headers = {"Content-Type": "application/json"};

    var response = await http.post(url, headers: headers);
    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      if (responseData['status'] == true) {
        print('Token added successfully: ${responseData['message']}');
      } else {
        print('Failed to add token: ${responseData['message']}');
      }
    } else {
      print('Failed to send token. Error: ${response.reasonPhrase}');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchStoredResponse();
    _fetchApprovedLocations();
    _fetchHolidays();
    _initPrefs();
    initializeNotifications();
  }

  int _selectedIndex = 0;
  SharedPreferences? _prefs;
  late String _punchinTime;
  Map<String, dynamic> response = {};
  bool _isButtonDisabled = false;
  Map<String, dynamic>? result;
  bool _isLoading = false;
  List<dynamic> _holidays = [];
  List<dynamic> _approvedLocations = [];
  final TextEditingController _locationReasonController =
      TextEditingController();

  get empId => response['body']['userId'] ?? '';
  get name => response['body']['userName'] ?? '';
  get department => response['body']['userDepartment'] ?? '';

  Future<void> fetchAttendanceAnalytics() async {
    final attendanceAnalytics = AttendanceAnalytics();
    String Id = empId.toString();
    final now = DateTime.now();
    print("-=-=-=-=-=-");
    print(Id);
    print("-=-=-=-=-=-");

    final analytics = await attendanceAnalytics.getAttendanceAnalytics(
      Id,
      now.month,
      now.year, // Get analytics for current month and year
    );
    print(
        "------------------------------------------------------------------------------------------");
    print(analytics);
    print(
        "------------------------------------------------------------------------------------------");
    setState(() {
      result = analytics;
    });
  }

  Future<void> fetchStoredResponse() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedResponse = prefs.getString('response');
    if (storedResponse != null) {
      try {
        setState(() {
          response = json.decode(storedResponse);   
        });
        fetchAttendanceAnalytics();
      } catch (e) {
        print("Error decoding stored response: $e");
      }
    } else {
      print("No stored response found.");
    }
    print(response);
  }

  Future<void> _fetchApprovedLocations() async {
    try {
      final response = await http.get(
        Uri.parse(baseurl+'/admin/fetchalllocation'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          setState(() {
            print(data['userList']);
            _approvedLocations = data['userList'];
          });
        }
      }
    } catch (e) {
      print('Error fetching locations: $e');
    }
  }

  void _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _punchinTime = _prefs!.getString('punchinTime') ?? '';

    if (_punchinTime.isNotEmpty) {
      DateFormat('hh:mm a').parse(_punchinTime);

      if (true) {
        setState(() {});
      }
    }
  }

  Future<void> _fetchHolidays() async {
    try {
      final response = await http.post(
        Uri.parse(baseurl+'/admin/fetchallholiday'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          setState(() {
            _holidays = data['userList'];
          });
        }
      }
    } catch (e) {
      print('Error fetching holidays: $e');
    }
  }

  Future<Position> _getFreshGeoLocationPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Force fresh service check
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }

    // Force fresh permission check
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // Get fresh position with high accuracy
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
      forceAndroidLocationManager: false,
      timeLimit: Duration(seconds: 15),
    );
  }

  void _punchin() async {
    if (_prefs == null) {
      _initPrefs();
    }

    setState(() {
      _isLoading = true;
      _isButtonDisabled = true;
    });

    try {
      // Get fresh location first
      Position position = await _getFreshGeoLocationPosition();
      String location =
          'Lat: ${position.latitude}, Long: ${position.longitude}';
      print("Fresh Location on Punch In: $location");

      DateTime now = DateTime.now();
      String loginTime = DateFormat('hh:mm a').format(now);
      String dayOfWeek = DateFormat('EEEE').format(now);

      _prefs!.setString('punchinTime', loginTime);
      _prefs!.setString('punchinDay', dayOfWeek);

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];
      String address =
          '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';

      String attendanceStatus = '';
      TimeOfDay currentTime = TimeOfDay.fromDateTime(now);
      TimeOfDay specifiedTime = TimeOfDay(hour: 9, minute: 45);

      if (currentTime.hour < specifiedTime.hour ||
          (currentTime.hour == specifiedTime.hour &&
              currentTime.minute <= specifiedTime.minute)) {
        attendanceStatus = 'Punch In On Time';
      } else {
        attendanceStatus = 'Punch In Late';
      }

      await _sendDataToBackend(
          loginTime, location, address, attendanceStatus, dayOfWeek);
    } catch (e) {
      print('Error during punch in: $e');
      _showErrorDialog('Failed to get location: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
        _isButtonDisabled = false;
      });
    }
  }

  void _punchout() async {
    if (_prefs == null) {
      _initPrefs();
    }

    setState(() {
      _isLoading = true;
      _isButtonDisabled = true;
    });

    try {
      // Get fresh location first
      Position position = await _getFreshGeoLocationPosition();
      String location =
          'Lat: ${position.latitude}, Long: ${position.longitude}';
      print("Fresh Location on Punch Out: $location");

      DateTime now = DateTime.now();
      String punchoutTime = DateFormat('hh:mm a').format(now);
      String dayOfWeek = DateFormat('EEEE').format(now);

      _prefs!.setString('punchoutTime', punchoutTime);
      _prefs!.setString('punchoutDay', dayOfWeek);

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      Placemark place = placemarks[0];
      String address =
          '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';

      String attendanceStatus = '';
      TimeOfDay currentTime = TimeOfDay.fromDateTime(now);
      TimeOfDay specifiedTime = TimeOfDay(hour: 18, minute: 30);

      print("Current Time: $currentTime");
      print("Specified Time: $specifiedTime");

      if (currentTime.hour < specifiedTime.hour ||
          (currentTime.hour == specifiedTime.hour &&
              currentTime.minute <= specifiedTime.minute)) {
        attendanceStatus = 'Punch Out Early';
      } else {
        attendanceStatus = 'Punch Out On Time';
      }

      await _sendDataToBackend(
          punchoutTime, location, address, attendanceStatus, dayOfWeek);
    } catch (e) {
      print('Error during punch out: $e');
      _showErrorDialog('Failed to get location: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
        _isButtonDisabled = false;
      });
    }
  }

  bool _isLocationApproved(double currentLat, double currentLong) {
    print("Fresh Current Location: $currentLat, $currentLong");
    bool isApproved = false;

    for (var location in _approvedLocations) {
      double approvedLat =
          double.tryParse(location['latitude'].toString()) ?? 0.0;
      double approvedLong =
          double.tryParse(location['longitude'].toString()) ?? 0.0;

      double distance = Geolocator.distanceBetween(
          currentLat, currentLong, approvedLat, approvedLong);

      print("Checking against: $approvedLat, $approvedLong");
      print("Distance: ${distance.toStringAsFixed(2)} meters");

      if (distance <= 150) {
        print("MATCH FOUND");
        isApproved = true;
        // Don't return yet - continue checking others for logging
      }
    }

    return isApproved;
  }

// Add these methods inside your _EmployeeDashboardState class
  void _showAttendanceSuccessDialog(String status) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Attendance Recorded',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 48),
              SizedBox(height: 16),
              Text(
                'Attendance marked successfully!',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Status: $status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Error',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendDataToBackend(
    String time,
    String location,
    String address,
    String attendanceStatus,
    String dayOfWeek,
  ) async {
    final currentDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    bool isSunday = dayOfWeek.toLowerCase() == 'sunday';
    bool isHoliday = _holidays.any((holiday) => holiday['date'] == currentDate);

    // Get current position
    Position position = await _getFreshGeoLocationPosition();
    double currentLat = position.latitude;
    double currentLong = position.longitude;

    print("Final Verification Location: $currentLat, $currentLong");

    // Check if location is approved
    bool isApprovedLocation = _isLocationApproved(currentLat, currentLong);
    print(isApprovedLocation);
    // Clear any previous reason
    _locationReasonController.clear();
    _reasonController.clear();

    // Show appropriate dialog based on location and day
    bool? shouldProceed;
    if (!isApprovedLocation) {
      shouldProceed = await _showLocationReasonDialog(context);
      if (shouldProceed != true) {
        setState(() {
          _isLoading = false;
          _isButtonDisabled = false;
        });
        return;
      }
    } else if (isSunday || isHoliday) {
      shouldProceed = await _showHolidayReasonDialog(context, isHoliday);
      if (shouldProceed != true) {
        setState(() {
          _isLoading = false;
          _isButtonDisabled = false;
        });
        return;
      }
    } else {
      shouldProceed = await _showRegularConfirmationDialog(context);
      if (shouldProceed != true) {
        setState(() {
          _isLoading = false;
          _isButtonDisabled = false;
        });
        return;
      }
    }

    // Build the request body
    var body = {
      "employeeId": empId,
      "name": name,
      "attendance": 'Present',
      "date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
      "time": time,
      "day": dayOfWeek,
      "latitude": currentLat.toString(),
      "longitude": currentLong.toString(),
      "address": address,
      "attendanceStatus": attendanceStatus,
      "department": department,
      "reason": !isApprovedLocation
          ? _locationReasonController.text
          : (isSunday || isHoliday)
              ? _reasonController.text
              : "",
      "outOfLocation": !isApprovedLocation ? "Yes" : "No",
      "compOff": (isSunday || isHoliday) ? "Yes" : "No",
      "comOffReason": "",
      "compOffStatus": (isSunday || isHoliday) ? "Pending" : "",
    };

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(child: CircularProgressIndicator());
      },
    );

    try {
      var url =
          Uri.parse(baseurl+'/emp/addemployeeattendence');
      var headers = {"Content-Type": "application/json"};
      var response =
          await http.post(url, body: jsonEncode(body), headers: headers);

      Navigator.of(context).pop(); // Dismiss loading dialog

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        if (responseData['status'] == true) {
          _showAttendanceSuccessDialog(attendanceStatus);
        } else {
          _showErrorDialog(
              responseData['message'] ?? 'Attendance submission failed');
        }
      } else {
        _showErrorDialog('Server error: ${response.statusCode}');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Dismiss loading dialog
      _showErrorDialog('Network error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
        _isButtonDisabled = false;
      });
    }
  }

  Future<bool?> _showLocationReasonDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Out off Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('You are not at an approved work location.'),
              SizedBox(height: 20),
              TextField(
                controller: _locationReasonController,
                decoration: InputDecoration(
                  labelText: 'Reason for working from this location*',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_locationReasonController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a reason')),
                  );
                  return;
                }
                Navigator.of(context).pop(true);
              },
              child: Text('SUBMIT'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showHolidayReasonDialog(
      BuildContext context, bool isHoliday) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isHoliday ? 'Holiday Attendance' : 'Sunday Attendance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isHoliday
                  ? 'You are marking attendance on a company holiday'
                  : 'You are marking attendance on Sunday'),
              SizedBox(height: 20),
              TextField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason for working*',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_reasonController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a reason')),
                  );
                  return;
                }
                Navigator.of(context).pop(true);
              },
              child: Text('SUBMIT'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showRegularConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Attendance'),
          content: Text('Mark your attendance for today?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('CONFIRM'),
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
            'assets/blue.jpg',
            fit: BoxFit.cover,
          ),
          SmartRefresher(
            controller: _refreshController,
            onRefresh: _onRefresh,
            enablePullDown: true,
            enablePullUp: true,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: 5),
                    Image.asset(
                      'assets/pp.png',
                      height: 80,
                      width: 400,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20.0),
                    Text(
                      'Welcome ${name ?? ''}',
                      style: TextStyle(
                        fontSize: 24.0,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 35.0),
                    Padding(
                      padding: const EdgeInsets.all(0.0),
                      child: result != null
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                // Present Circle
                                Column(
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          height: 70,
                                          width: 70,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.greenAccent,
                                                Colors.lightGreen
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color.fromARGB(
                                                        255, 108, 201, 156)
                                                    .withOpacity(0.4),
                                                blurRadius: 15,
                                                spreadRadius: 5,
                                                offset: Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: SizedBox(
                                            height: 100,
                                            width: 100,
                                            child: CircularProgressIndicator(
                                              value: result!['Present'] / 27,
                                              strokeWidth: 10,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.greenAccent),
                                              backgroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                        AnimatedSwitcher(
                                          duration: Duration(milliseconds: 500),
                                          child: Text(
                                            '${result!['Present']}',
                                            key: ValueKey(result!['Present']),
                                            style: TextStyle(
                                              fontSize: 19,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Present',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                // Absent Circle
                                Column(
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          height: 70,
                                          width: 70,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.redAccent,
                                                Colors.deepOrangeAccent
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.redAccent
                                                    .withOpacity(0.4),
                                                blurRadius: 15,
                                                spreadRadius: 5,
                                                offset: Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: SizedBox(
                                            height: 100,
                                            width: 100,
                                            child: CircularProgressIndicator(
                                              value: result!['Absent'] / 6,
                                              strokeWidth: 10,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.redAccent),
                                              backgroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                        AnimatedSwitcher(
                                          duration: Duration(milliseconds: 500),
                                          child: Text(
                                            '${result!['Absent']}',
                                            key: ValueKey(result!['Absent']),
                                            style: TextStyle(
                                              fontSize: 19,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Absent',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                // Late Circle
                                Column(
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          height: 70,
                                          width: 70,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.orangeAccent,
                                                Colors.amber
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.orangeAccent
                                                    .withOpacity(0.4),
                                                blurRadius: 15,
                                                spreadRadius: 5,
                                                offset: Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: SizedBox(
                                            height: 100,
                                            width: 100,
                                            child: CircularProgressIndicator(
                                              value: result!['Late'] / 27,
                                              strokeWidth: 10,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.orangeAccent),
                                              backgroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                        AnimatedSwitcher(
                                          duration: Duration(milliseconds: 500),
                                          child: Text(
                                            '${result!['Late']}',
                                            key: ValueKey(result!['Late']),
                                            style: TextStyle(
                                              fontSize: 19,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Late',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          height: 70,
                                          width: 70,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFFA12FAC),
                                                const Color.fromARGB(
                                                    255, 135, 29, 161)
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Color(0xFFA12FAC)
                                                    .withOpacity(0.4),
                                                blurRadius: 15,
                                                spreadRadius: 5,
                                                offset: Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: SizedBox(
                                            height: 100,
                                            width: 100,
                                            child: CircularProgressIndicator(
                                              value: result!['Holiday'] / 6,
                                              strokeWidth: 10,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      const Color(0xFFA12FAC)),
                                              backgroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                        AnimatedSwitcher(
                                          duration: Duration(milliseconds: 500),
                                          child: Text(
                                            '${result!['Holiday']}',
                                            key: ValueKey(result!['Holiday']),
                                            style: TextStyle(
                                              fontSize: 19,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Holiday',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blueAccent),
                              ),
                            ),
                    ),
                    const SizedBox(height: 20.0),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildCompactButton(
                          icon: Icons.add,
                          label: 'Add Leads',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EmployeeRegistrationForm(empId),
                              ),
                            );
                          },
                        ),
                        _buildCompactButton(
                          icon: Icons.leaderboard_sharp,
                          label: 'View Leads',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ViewLeadsPage(),
                              ),
                            );
                          },
                        ),
                        _buildCompactButton(
                          icon: Icons.feedback_outlined,
                          label: 'Add Report',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReportSubmissionScreen(
                                    response['body']?['userId'],
                                    response['body']?['userName'],
                                    response['body']?['userDepartment']),
                              ),
                            );
                          },
                        ),
                        _buildCompactButton(
                          icon: Icons.table_view_rounded,
                          label: '    View \nAttendance',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewAttendanceById(empId),
                              ),
                            );
                          },
                        ),
                        _buildCompactButton(
                          icon: Icons.table_view_rounded,
                          label: 'Non-Working \nDay',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    Nonworkingday(empId: empId.toString()),
                              ),
                            );
                          },
                        ),
                        _buildCompactButton(
                          icon: Icons.table_view_rounded,
                          label: 'Salary Slip',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    Employeesalaryslip(empId: empId.toString()),
                              ),
                            );
                          },
                        ),
                        // if (department == "HR")
                        //   _buildCompactButton(
                        //     icon: Icons.view_comfortable,
                        //     label: 'View All \nAttendance',
                        //     onTap: () {
                        //       Navigator.push(
                        //         context,
                        //         MaterialPageRoute(
                        //           builder: (context) => AttendancePage1(),
                        //         ),
                        //       );
                        //     },
                        //   ),
                        // if (department == "HR")
                        //   _buildCompactButton(
                        //     icon: Icons.reviews_rounded,
                        //     label: 'View All Reports',
                        //     onTap: () {
                        //       Navigator.push(
                        //         context,
                        //         MaterialPageRoute(
                        //           builder: (context) => Viewallreport(),
                        //         ),
                        //       );
                        //     },
                        //   ),
                        // if (department == "HR")
                        //   _buildCompactButton(
                        //     icon: Icons.analytics,
                        //     label: 'View all analytics',
                        //     onTap: () {
                        //       Navigator.push(
                        //         context,
                        //         MaterialPageRoute(
                        //           builder: (context) => AnalyticsScreen(),
                        //         ),
                        //       );
                        //     },
                        //   ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildCompactButton(
                            icon: Icons.login,
                            label: 'Punch In',
                            onTap: _isButtonDisabled || _isLoading
                                ? () {}
                                : _punchin,
                            isLoading: _isLoading && !_isButtonDisabled,
                            isDisabled: _isButtonDisabled || _isLoading,
                          ),
                          const SizedBox(width: 30),
                          _buildCompactButton(
                            icon: Icons.logout,
                            label: 'Punch Out',
                            onTap: _isButtonDisabled || _isLoading
                                ? () {}
                                : _punchout,
                            isLoading: _isLoading && !_isButtonDisabled,
                            isDisabled: _isButtonDisabled || _isLoading,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color.fromARGB(255, 30, 93, 209),
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
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        onTap: _onItemTapped,
      ),
    );
  }

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
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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
}

Widget _buildCompactButton({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
  bool isLoading = false,
  bool isDisabled = false,
}) {
  return GestureDetector(
    onTap: isDisabled ? null : onTap,
    child: Container(
      height: 50,
      margin: const EdgeInsets.all(8.0),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDisabled
            ? const Color.fromARGB(255, 152, 153, 152)
            : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15.0),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            )
          else
            Icon(
              icon,
              size: 26,
              color: Colors.white,
            ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12.0,
            ),
          ),
        ],
      ),
    ),
  );
}
