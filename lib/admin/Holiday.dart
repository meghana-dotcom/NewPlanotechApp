import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:planotech/baseurl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class HolidayDeclaration extends StatefulWidget {
  const HolidayDeclaration({super.key});

  @override
  State<HolidayDeclaration> createState() => _HolidayDeclarationState();
}

class _HolidayDeclarationState extends State<HolidayDeclaration> {
 RefreshController _refreshController = RefreshController(initialRefresh: false);
 void _onRefresh() async {
    await Future.delayed(Duration(seconds: 4));
    _refreshController.refreshCompleted();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HolidayDeclaration()),
    );
  }
  


  DateTime? selectedDate;
  String? selectedDay;
  List<dynamic> holidayList = [];
  bool isSubmitting = false;
  bool isLoading = false;
  Map<String, bool> loadingMap = {}; 

  Future<void> _fetchHolidays() async {
    String url = baseurl+'/admin/fetchallholiday';

    try {
      final response = await http.post(Uri.parse(url));

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        print('Response from backend: $jsonResponse');

        if (jsonResponse['status']) {
          List<dynamic> holidays = jsonResponse['userList'];
          holidays.sort((a, b) {
            DateTime dateA = DateFormat('dd-MM-yyyy').parse(a['date']);
            DateTime dateB = DateFormat('dd-MM-yyyy').parse(b['date']);
            return dateB.compareTo(dateA);
          });

          setState(() {
            holidayList = holidays;
          });
        } else {
          print('Failed to fetch holidays: ${jsonResponse['statusMessage']}');
        }
      } else {
        print('Failed to fetch holidays. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred while fetching holidays: $e');
    }
  }

  Future<void> _submitHoliday() async {
    if (selectedDate != null && selectedDay != null) {
      setState(() {
        isSubmitting = true;
      });
      String formattedDate = DateFormat('dd-MM-yyyy').format(selectedDate!);
      String url =
          baseurl+'/admin/holidaydateregistor?date=$formattedDate&day=$selectedDay';
      try {
        final response = await http.post(Uri.parse(url));

        if (response.statusCode == 200) {
          var jsonResponse = jsonDecode(response.body);
          print('Response from backend: $jsonResponse');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  jsonResponse['message'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Colors.green[700],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: const Duration(seconds: 5),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
          _fetchHolidays();
        } else {
          print('Failed to declare holiday. Status code: ${response.statusCode}');
        }
      } catch (e) {
        print('Error occurred while declaring holiday: $e');
      } finally {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  Future<void> _deleteHoliday(String date) async {
    String url = baseurl+'/admin/deleteholiday?date=$date';

    setState(() {
      loadingMap[date] = true; 
    });

    try {
      final response = await http.post(Uri.parse(url));

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        print('Response from backend: $jsonResponse');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                jsonResponse['message'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 5),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        _fetchHolidays();
      } else {
        print('Failed to delete holiday. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred while deleting holiday: $e');
    } finally {
      setState(() {
        loadingMap[date] = false; 
      });
    }
  }

  Future<void> _confirmDelete(String date) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this holiday?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _deleteHoliday(date);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        selectedDay = DateFormat('EEEE').format(picked);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchHolidays();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Holiday Declaration',
          style: TextStyle(
            color: Colors.white,
           fontWeight: FontWeight.bold
          ),
        ),
  leading: IconButton(
    icon: const Icon(
      Icons.arrow_back,
      color: Colors.white,
    ),
    onPressed: () {
      Navigator.pop(context);
    },
  ),        
        centerTitle: true,
        elevation: 0,
         backgroundColor: const Color.fromARGB(255, 139, 12, 3),
      ),
      extendBodyBehindAppBar: true,
body: Container(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Color.fromARGB(255, 199, 62, 119),
        Color.fromARGB(255, 238, 13, 25),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  ),
  child: Column(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      const SizedBox(height: 100),
      if (selectedDate != null)
        Container(
          width: 300,
          height: 170,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Selected Date:',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                DateFormat('dd-MM-yyyy').format(selectedDate!),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Day: $selectedDay',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      const SizedBox(height: 30),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () => _selectDate(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              shadowColor: Colors.purpleAccent.withOpacity(0.5),
              elevation: 10,
            ),
            child: const Text(
              'Select Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
          const SizedBox(width: 20),
          if (selectedDate != null)
            const SizedBox(width: 20),
                if (selectedDate != null)
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null 
                        : () async {
                            final bool? confirm = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Confirm Submission'),
                                  content: const Text('Are you sure you want to submit this holiday declaration?'),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(false);
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(true);
                                      },
                                      child: const Text('Submit'),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirm == true) {
                              await _submitHoliday();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      shadowColor: Colors.purpleAccent.withOpacity(0.5),
                      elevation: 10,
                    ),
                    child: isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Submit Holiday',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
        ],
      ),
      const SizedBox(height: 20),
      Expanded(
        child: SmartRefresher(
          controller: _refreshController, 
          onRefresh: _onRefresh,          
          enablePullDown: true,            
          enablePullUp: true,           
          child: ListView.builder(
            itemCount: holidayList.length,
            itemBuilder: (context, index) {
              var holiday = holidayList[index];
              String date = holiday['date'];
              String day = holiday['day'];
              bool isDeleting = loadingMap[date] ?? false;

              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  title: Text(
                    'Date: $date',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    'Day: $day',
                    style: const TextStyle(fontSize: 16),
                  ),
                  trailing: isDeleting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 28,
                          ),
                          onPressed: () {
                            _confirmDelete(date);
                          },
                        ),
                ),
              );
            },
          ),
        ),
      ),
    ],
  ),
)
    );
  }
}