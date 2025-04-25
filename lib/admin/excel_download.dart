// import 'package:http/http.dart' as http;
// import 'package:planotech/baseurl.dart';
// import 'package:syncfusion_flutter_xlsio/xlsio.dart';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'package:open_file/open_file.dart';
// import 'dart:convert';

// Future<String> downloadExcel(DateTime startDate, DateTime endDate) async {
//   final startingdate =
//       "${startDate.day.toString().padLeft(2, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.year}";
//   final enddate =
//       "${endDate.day.toString().padLeft(2, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.year}";

//   final dateRange = <String>{};

//   try {
//     final responseAttendance = await http.post(Uri.parse(
//         baseurl+'/admin/fetchallattendancebystartandenddate?startingdate=$startingdate&enddate=$enddate'));

//     final responseEmployees = await http
//         .post(Uri.parse(baseurl+'/admin/fetchallemployee'));

//     if (responseAttendance.statusCode == 200 &&
//         responseEmployees.statusCode == 200) {
//       final Map<String, dynamic> attendanceData =
//           json.decode(responseAttendance.body);
//       final Map<String, dynamic> employeeData =
//           json.decode(responseEmployees.body);

//       final Workbook workbook = Workbook();
//       final Worksheet sheet = workbook.worksheets[0];

//       // Set headers
//       const headers = [
//         'Employee Name',
//         'Employee Department',
//         'Employee Code',
//         'Date',
//         'Day',
//         'Attendance Status',
//         'Punch In Time',
//         'Punch In Address',
//         'Punch In Status',
//         'Punch Out Time',
//         'Punch Out Address',
//         'Punch Out Status',
//         'Working Hours' // New column for working hours
//       ];

//       for (int i = 0; i < headers.length; i++) {
//         sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
//       }

//       int rowIndex = 2;
//       final body = attendanceData['body'];

//       List<Map<String, dynamic>> sortedData = [];

//       if (body != null && body is List) {
//         sortedData = List.from(body);
//         sortedData.sort((a, b) =>
//             a['dayAndDate'][0]['date'].compareTo(b['dayAndDate'][0]['date']));

//         // Create a set of all dates within the range
//         for (var date = startDate;
//             date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
//             date = date.add(Duration(days: 1))) {
//           dateRange.add(
//               "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}");
//         }

//        for (var date in dateRange) {
//   DateTime currentDate = DateTime.parse(
//       "${date.split('-')[2]}-${date.split('-')[1]}-${date.split('-')[0]}");
//   String dayOfWeek = [
//     'Sunday',
//     'Monday',
//     'Tuesday',
//     'Wednesday',
//     'Thursday',
//     'Friday',
//     'Saturday'
//   ][currentDate.weekday % 7];

//   bool isSunday = dayOfWeek == 'Sunday';
  
//   for (var employee in sortedData) {
//     final empCode = employee['emp_Code']?.toString() ?? '';
//     final empName = employee['name_of_the_Employee'] ?? '';
//     final empDepartment = employee['department'] ?? '';
//     final dayAndDate = employee['dayAndDate'];

//     bool hasAttendanceForDate = false;

//     // Check if there's any attendance record for this date
//     if (dayAndDate != null && dayAndDate is List) {
//       for (var dayEntry in dayAndDate) {
//         final entryDate = dayEntry['date'] ?? '';
//         if (entryDate == date) {
//           hasAttendanceForDate = true;
//           final attendance = dayEntry['attendance'] ?? '';

//           // If attendance shows 'Holiday', mark the day as Holiday
//           if (attendance == 'Holiday') {
//             sheet.getRangeByIndex(rowIndex, 1).setText(empName);
//             sheet.getRangeByIndex(rowIndex, 2).setText(empDepartment);
//             sheet.getRangeByIndex(rowIndex, 3).setText(empCode);
//             sheet.getRangeByIndex(rowIndex, 4).setText(date);
//             sheet.getRangeByIndex(rowIndex, 5).setText(dayOfWeek);
//             sheet.getRangeByIndex(rowIndex, 6).setText('Holiday');
//             rowIndex++;
//             break;
//           }

//           // Process In and Out times, calculate working hours
//           List<Map<String, String>> inTimes = [];
//           List<Map<String, String>> outTimes = [];
//           String workingHours = '';

//           final attendanceDetails = dayEntry['attendance_Details'];
//           if (attendanceDetails != null && attendanceDetails is List) {
//             DateTime? firstInTime;
//             DateTime? lastOutTime;

//             for (var detail in attendanceDetails) {
//               if (detail != null && detail['time'] != null) {
//                 final time = detail['time'];
//                 final dateTime = parseTime(date, time);

//                 final attendanceStatus = detail['attendance_status'];
                
//                 if (attendanceStatus != null && attendanceStatus.contains('Punch In')) {
//                   if (firstInTime == null || dateTime.isBefore(firstInTime)) {
//                     inTimes = [{
//                       'time': time,
//                       'address': detail['address'] ?? '',
//                       'status': getInStatus(dateTime),
//                     }];
//                     firstInTime = dateTime;
//                   }
//                 }

//                 else if (attendanceStatus != null && attendanceStatus.contains('Punch Out')) {
//                   if (lastOutTime == null || dateTime.isAfter(lastOutTime)) {
//                     outTimes = [{
//                       'time': time,
//                       'address': detail['address'] ?? '',
//                       'status': getOutStatus(dateTime),
//                     }];
//                     lastOutTime = dateTime;
//                   }
//                 }
//               }
//             }

//             if (firstInTime != null && lastOutTime != null) {
//               final duration = lastOutTime.difference(firstInTime);
//               workingHours =
//                   '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
//             }

//             int maxLength = inTimes.length > outTimes.length
//                 ? inTimes.length
//                 : outTimes.length;
//             for (int i = 0; i < maxLength; i++) {
//               sheet.getRangeByIndex(rowIndex, 1).setText(empName);
//               sheet.getRangeByIndex(rowIndex, 2).setText(empDepartment);
//               sheet.getRangeByIndex(rowIndex, 3).setText(empCode);
//               sheet.getRangeByIndex(rowIndex, 4).setText(date);
//               sheet.getRangeByIndex(rowIndex, 5).setText(dayOfWeek);
//               sheet.getRangeByIndex(rowIndex, 6).setText(attendance);

//               if (i < inTimes.length) {
//                 var inEntry = inTimes[i];
//                 sheet.getRangeByIndex(rowIndex, 7).setText(inEntry['time']);
//                 sheet.getRangeByIndex(rowIndex, 8).setText(inEntry['address']);
//                 sheet.getRangeByIndex(rowIndex, 9).setText(inEntry['status']);
//               }

//               if (i < outTimes.length) {
//                 var outEntry = outTimes[i];
//                 sheet.getRangeByIndex(rowIndex, 10).setText(outEntry['time']);
//                 sheet.getRangeByIndex(rowIndex, 11).setText(outEntry['address']);
//                 sheet.getRangeByIndex(rowIndex, 12).setText(outEntry['status']);
//               }

//               if (i == 0 && workingHours.isNotEmpty) {
//                 sheet.getRangeByIndex(rowIndex, 13).setText(workingHours);
//               } else {
//                 sheet.getRangeByIndex(rowIndex, 13).setText('');
//               }

//               rowIndex++;
//             }
//           }
//         }
//       }
//     }

//     // Mark as "Holiday" if no attendance found on Sunday
//     if (isSunday && !hasAttendanceForDate) {
//       sheet.getRangeByIndex(rowIndex, 1).setText(empName);
//       sheet.getRangeByIndex(rowIndex, 2).setText(empDepartment);
//       sheet.getRangeByIndex(rowIndex, 3).setText(empCode);
//       sheet.getRangeByIndex(rowIndex, 4).setText(date);
//       sheet.getRangeByIndex(rowIndex, 5).setText(dayOfWeek);
//       sheet.getRangeByIndex(rowIndex, 6).setText('Holiday');
//       rowIndex++;
//     }

//     // Mark as "Absent" if no attendance found and it's not a Sunday
//     else if (!isSunday && !hasAttendanceForDate) {
//       sheet.getRangeByIndex(rowIndex, 1).setText(empName);
//       sheet.getRangeByIndex(rowIndex, 2).setText(empDepartment);
//       sheet.getRangeByIndex(rowIndex, 3).setText(empCode);
//       sheet.getRangeByIndex(rowIndex, 4).setText(date);
//       sheet.getRangeByIndex(rowIndex, 5).setText(dayOfWeek);
//       sheet.getRangeByIndex(rowIndex, 6).setText('Absent');
//       rowIndex++;
//     }
//   }
// }



//       }

//       // Check for employees not present in the attendance data and mark them as absent
//       if (employeeData['userList'] != null &&
//           employeeData['userList'] is List) {
//         final List<String> attendanceEmployeeCodes =
//             sortedData.map((e) => e['emp_Code']?.toString() ?? '').toList();
//         for (var employee in employeeData['userList']) {
//           final empCode = employee['userId'].toString();
//           final empName = employee['userName'] ?? '';
//           final empDepartment = employee['userDepartment'] ?? '';

//           if (!attendanceEmployeeCodes.contains(empCode)) {
//             for (var date in dateRange) {
//               DateTime currentDate = DateTime.parse(
//                   "${date.split('-')[2]}-${date.split('-')[1]}-${date.split('-')[0]}");
//               String dayOfWeek = [
//                 'Sunday',
//                 'Monday',
//                 'Tuesday',
//                 'Wednesday',
//                 'Thursday',
//                 'Friday',
//                 'Saturday'
//               ][currentDate.weekday % 7];

//               sheet.getRangeByIndex(rowIndex, 1).setText(empName);
//               sheet.getRangeByIndex(rowIndex, 2).setText(empDepartment);
//               sheet.getRangeByIndex(rowIndex, 3).setText(empCode);
//               sheet.getRangeByIndex(rowIndex, 4).setText(date);
//               sheet.getRangeByIndex(rowIndex, 5).setText(dayOfWeek);
//               sheet
//                   .getRangeByIndex(rowIndex, 6)
//                   .setText(dayOfWeek == 'Sunday' ? 'Holiday' : 'Absent');
//               rowIndex++;
//             }
//           }
//         }
//       }

//       final List<int> bytes = workbook.saveAsStream();
//       final String path = (await getApplicationSupportDirectory()).path;
//       final String fileName =
//           Platform.isWindows ? '$path\\Output.xlsx' : '$path/Output.xlsx';
//       final File file = File(fileName);
//       await file.writeAsBytes(bytes, flush: true);
//       OpenFile.open(fileName);

//       workbook.dispose();
//       print('Excel file created and opened successfully.');
//       return 'Excel file created and opened successfully.';
//     } else {
//       print(
//           'Failed to load attendance or employee data: ${responseAttendance.statusCode} - ${responseAttendance.reasonPhrase}');
//       return 'Failed to load attendance or employee data';
//     }
//   } catch (e) {
//     print("Error creating Excel file: $e");
//     return 'Failed to create Excel file';
//   }
// }

// DateTime parseTime(String date, String time) {
//   try {
//     final timeParts = time.split(' ');
//     if (timeParts.length != 2) {
//       throw FormatException('Invalid time format');
//     }

//     final hourMinute = timeParts[0].split(':');
//     if (hourMinute.length != 2) {
//       throw FormatException('Invalid hour-minute format');
//     }

//     final hour = int.parse(hourMinute[0]);
//     final minute = int.parse(hourMinute[1]);
//     final timeOfDay = timeParts[1].toUpperCase();

//     if (timeOfDay != 'AM' && timeOfDay != 'PM') {
//       throw FormatException('Invalid AM/PM format');
//     }

//     final isAM = timeOfDay == 'AM';

//     return DateTime(
//       int.parse(date.split('-')[2]), // Year
//       int.parse(date.split('-')[1]), // Month
//       int.parse(date.split('-')[0]), // Day
//       hour == 12 ? (isAM ? 0 : 12) : (isAM ? hour : hour + 12),
//       minute,
//     );
//   } catch (e) {
//     print('Error parsing time: $e');
//     return DateTime.now(); // or handle the error appropriately
//   }
// }

// String getInStatus(DateTime dateTime) {
//   final hour = dateTime.hour;
//   final minute = dateTime.minute;

//   if (hour < 9 || (hour == 9 && minute <= 45)) {
//     return 'Present';
//   } else {
//     return 'Late';
//   }
// }

// String getOutStatus(DateTime dateTime) {
//   final hour = dateTime.hour;
//   final minute = dateTime.minute;

//   if ((hour > 18 || (hour == 18 && minute >= 30)) ||
//       (hour < 3 && minute == 0)) {
//     return 'Punch Out';
//   } else {
//     return 'Early';
//   }
// }



import 'package:http/http.dart' as http;
import 'package:planotech/baseurl.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:convert';

Future<String> downloadExcel(DateTime startDate, DateTime endDate) async {
  final startingdate =
      "${startDate.day.toString().padLeft(2, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.year}";
  final enddate =
      "${endDate.day.toString().padLeft(2, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.year}";

  final dateRange = <String>{};

  try {
    final responseAttendance = await http.post(Uri.parse(
        baseurl+'/admin/fetchallattendancebystartandenddate?startingdate=$startingdate&enddate=$enddate'));

    final responseEmployees = await http
        .post(Uri.parse(baseurl+'/admin/fetchallemployee'));

    if (responseAttendance.statusCode == 200 &&
        responseEmployees.statusCode == 200) {
      final Map<String, dynamic> attendanceData =
          json.decode(responseAttendance.body);
      final Map<String, dynamic> employeeData =
          json.decode(responseEmployees.body);

      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];

      // Set headers with all columns
      const headers = [
        'Employee Name',
        'Employee Department',
        'Employee Code',
        'Date',
        'Day',
        'Attendance Status',
        'Punch In Time',
        'Punch In Address',
        'Punch In Status',
        'Punch Out Time',
        'Punch Out Address',
        'Punch Out Status',
        'Working Hours',
        'Reason',
        'Out Of Location',
        'Comp Off',
        'Comp Off Reason',
        'Comp Off Status'
      ];

      for (int i = 0; i < headers.length; i++) {
        sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
      }

      int rowIndex = 2;
      final body = attendanceData['body'];

      List<Map<String, dynamic>> sortedData = [];

      if (body != null && body is List) {
        sortedData = List.from(body);
        sortedData.sort((a, b) =>
            a['dayAndDate'][0]['date'].compareTo(b['dayAndDate'][0]['date']));

        // Create a set of all dates within the range
        for (var date = startDate;
            date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
            date = date.add(Duration(days: 1))) {
          dateRange.add(
              "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}");
        }

        for (var date in dateRange) {
          DateTime currentDate = DateTime.parse(
              "${date.split('-')[2]}-${date.split('-')[1]}-${date.split('-')[0]}");
          String dayOfWeek = [
            'Sunday',
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday'
          ][currentDate.weekday % 7];

          bool isSunday = dayOfWeek == 'Sunday';
          
          for (var employee in sortedData) {
            final empCode = employee['emp_Code']?.toString() ?? '';
            final empName = employee['name_of_the_Employee'] ?? '';
            final empDepartment = employee['department'] ?? '';
            final dayAndDate = employee['dayAndDate'];

            bool hasAttendanceForDate = false;

            if (dayAndDate != null && dayAndDate is List) {
              for (var dayEntry in dayAndDate) {
                final entryDate = dayEntry['date'] ?? '';
                if (entryDate == date) {
                  hasAttendanceForDate = true;
                  final attendance = dayEntry['attendance'] ?? '';
                  final outOfLocation = dayEntry['outOfLocation']?.toString() ?? '';
                  final compOff = dayEntry['compOff']?.toString() ?? '';

                  if (attendance == 'Holiday') {
                    sheet.getRangeByIndex(rowIndex, 1).setText(empName);
                    sheet.getRangeByIndex(rowIndex, 2).setText(empDepartment);
                    sheet.getRangeByIndex(rowIndex, 3).setText(empCode);
                    sheet.getRangeByIndex(rowIndex, 4).setText(date);
                    sheet.getRangeByIndex(rowIndex, 5).setText(dayOfWeek);
                    sheet.getRangeByIndex(rowIndex, 6).setText('Holiday');
                    // Set additional fields
                    sheet.getRangeByIndex(rowIndex, 14).setText('');
                    sheet.getRangeByIndex(rowIndex, 15).setText(outOfLocation);
                    sheet.getRangeByIndex(rowIndex, 16).setText(compOff);
                    sheet.getRangeByIndex(rowIndex, 17).setText('');
                    sheet.getRangeByIndex(rowIndex, 18).setText('');
                    rowIndex++;
                    break;
                  }

                  List<Map<String, dynamic>> inTimes = [];
                  List<Map<String, dynamic>> outTimes = [];
                  String workingHours = '';
                  String reason = '';
                  String compOffReason = '';
                  String compOffStatus = '';

                  final attendanceDetails = dayEntry['attendance_Details'];
                  if (attendanceDetails != null && attendanceDetails is List) {
                    DateTime? firstInTime;
                    DateTime? lastOutTime;

                    for (var detail in attendanceDetails) {
                      if (detail != null && detail['time'] != null) {
                        final time = detail['time'];
                        final dateTime = parseTime(date, time);

                        // Extract reason-related fields from the first punch in
                        if ((detail['attendance_status'] as String).contains('Punch In')) {
                          reason = detail['reason']?.toString() ?? '';
                          compOffReason = detail['compOffReason']?.toString() ?? '';
                          compOffStatus = detail['compOffStatus']?.toString() ?? '';
                        }

                        final attendanceStatus = detail['attendance_status'];
                        
                        if (attendanceStatus != null && attendanceStatus.contains('Punch In')) {
                          if (firstInTime == null || dateTime.isBefore(firstInTime)) {
                            inTimes = [{
                              'time': time,
                              'address': detail['address'] ?? '',
                              'status': getInStatus(dateTime),
                            }];
                            firstInTime = dateTime;
                          }
                        }
                        else if (attendanceStatus != null && attendanceStatus.contains('Punch Out')) {
                          if (lastOutTime == null || dateTime.isAfter(lastOutTime)) {
                            outTimes = [{
                              'time': time,
                              'address': detail['address'] ?? '',
                              'status': getOutStatus(dateTime),
                            }];
                            lastOutTime = dateTime;
                          }
                        }
                      }
                    }

                    if (firstInTime != null && lastOutTime != null) {
                      final duration = lastOutTime.difference(firstInTime);
                      workingHours =
                          '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
                    }

                    int maxLength = inTimes.length > outTimes.length
                        ? inTimes.length
                        : outTimes.length;
                    for (int i = 0; i < maxLength; i++) {
                      sheet.getRangeByIndex(rowIndex, 1).setText(empName);
                      sheet.getRangeByIndex(rowIndex, 2).setText(empDepartment);
                      sheet.getRangeByIndex(rowIndex, 3).setText(empCode);
                      sheet.getRangeByIndex(rowIndex, 4).setText(date);
                      sheet.getRangeByIndex(rowIndex, 5).setText(dayOfWeek);
                      sheet.getRangeByIndex(rowIndex, 6).setText(attendance);

                      if (i < inTimes.length) {
                        var inEntry = inTimes[i];
                        sheet.getRangeByIndex(rowIndex, 7).setText(inEntry['time']);
                        sheet.getRangeByIndex(rowIndex, 8).setText(inEntry['address']);
                        sheet.getRangeByIndex(rowIndex, 9).setText(inEntry['status']);
                      }

                      if (i < outTimes.length) {
                        var outEntry = outTimes[i];
                        sheet.getRangeByIndex(rowIndex, 10).setText(outEntry['time']);
                        sheet.getRangeByIndex(rowIndex, 11).setText(outEntry['address']);
                        sheet.getRangeByIndex(rowIndex, 12).setText(outEntry['status']);
                      }

                      if (i == 0 && workingHours.isNotEmpty) {
                        sheet.getRangeByIndex(rowIndex, 13).setText(workingHours);
                      } else {
                        sheet.getRangeByIndex(rowIndex, 13).setText('');
                      }
                      
                      // Set additional fields only in first row for this date
                      if (i == 0) {
                        sheet.getRangeByIndex(rowIndex, 14).setText(reason);
                        sheet.getRangeByIndex(rowIndex, 15).setText(outOfLocation);
                        sheet.getRangeByIndex(rowIndex, 16).setText(compOff);
                        sheet.getRangeByIndex(rowIndex, 17).setText(compOffReason);
                        sheet.getRangeByIndex(rowIndex, 18).setText(compOffStatus);
                      } else {
                        sheet.getRangeByIndex(rowIndex, 14).setText('');
                        sheet.getRangeByIndex(rowIndex, 15).setText('');
                        sheet.getRangeByIndex(rowIndex, 16).setText('');
                        sheet.getRangeByIndex(rowIndex, 17).setText('');
                        sheet.getRangeByIndex(rowIndex, 18).setText('');
                      }

                      rowIndex++;
                    }
                  }
                }
              }
            }

            if (isSunday && !hasAttendanceForDate) {
              sheet.getRangeByIndex(rowIndex, 1).setText(empName);
              sheet.getRangeByIndex(rowIndex, 2).setText(empDepartment);
              sheet.getRangeByIndex(rowIndex, 3).setText(empCode);
              sheet.getRangeByIndex(rowIndex, 4).setText(date);
              sheet.getRangeByIndex(rowIndex, 5).setText(dayOfWeek);
              sheet.getRangeByIndex(rowIndex, 6).setText('Holiday');
              // Set empty additional fields
              sheet.getRangeByIndex(rowIndex, 14).setText('');
              sheet.getRangeByIndex(rowIndex, 15).setText('');
              sheet.getRangeByIndex(rowIndex, 16).setText('');
              sheet.getRangeByIndex(rowIndex, 17).setText('');
              sheet.getRangeByIndex(rowIndex, 18).setText('');
              rowIndex++;
            }
            else if (!isSunday && !hasAttendanceForDate) {
              sheet.getRangeByIndex(rowIndex, 1).setText(empName);
              sheet.getRangeByIndex(rowIndex, 2).setText(empDepartment);
              sheet.getRangeByIndex(rowIndex, 3).setText(empCode);
              sheet.getRangeByIndex(rowIndex, 4).setText(date);
              sheet.getRangeByIndex(rowIndex, 5).setText(dayOfWeek);
              sheet.getRangeByIndex(rowIndex, 6).setText('Absent');
              // Set empty additional fields
              sheet.getRangeByIndex(rowIndex, 14).setText('');
              sheet.getRangeByIndex(rowIndex, 15).setText('');
              sheet.getRangeByIndex(rowIndex, 16).setText('');
              sheet.getRangeByIndex(rowIndex, 17).setText('');
              sheet.getRangeByIndex(rowIndex, 18).setText('');
              rowIndex++;
            }
          }
        }
      }

      // Handle employees not in attendance data
      if (employeeData['userList'] != null && employeeData['userList'] is List) {
        final List<String> attendanceEmployeeCodes =
            sortedData.map((e) => e['emp_Code']?.toString() ?? '').toList();
        for (var employee in employeeData['userList']) {
          final empCode = employee['userId'].toString();
          final empName = employee['userName'] ?? '';
          final empDepartment = employee['userDepartment'] ?? '';

          if (!attendanceEmployeeCodes.contains(empCode)) {
            for (var date in dateRange) {
              DateTime currentDate = DateTime.parse(
                  "${date.split('-')[2]}-${date.split('-')[1]}-${date.split('-')[0]}");
              String dayOfWeek = [
                'Sunday',
                'Monday',
                'Tuesday',
                'Wednesday',
                'Thursday',
                'Friday',
                'Saturday'
              ][currentDate.weekday % 7];

              sheet.getRangeByIndex(rowIndex, 1).setText(empName);
              sheet.getRangeByIndex(rowIndex, 2).setText(empDepartment);
              sheet.getRangeByIndex(rowIndex, 3).setText(empCode);
              sheet.getRangeByIndex(rowIndex, 4).setText(date);
              sheet.getRangeByIndex(rowIndex, 5).setText(dayOfWeek);
              sheet.getRangeByIndex(rowIndex, 6).setText(
                  dayOfWeek == 'Sunday' ? 'Holiday' : 'Absent');
              // Set empty additional fields
              sheet.getRangeByIndex(rowIndex, 14).setText('');
              sheet.getRangeByIndex(rowIndex, 15).setText('');
              sheet.getRangeByIndex(rowIndex, 16).setText('');
              sheet.getRangeByIndex(rowIndex, 17).setText('');
              sheet.getRangeByIndex(rowIndex, 18).setText('');
              rowIndex++;
            }
          }
        }
      }

      final List<int> bytes = workbook.saveAsStream();
      final String path = (await getApplicationSupportDirectory()).path;
      final String fileName =
          Platform.isWindows ? '$path\\Output.xlsx' : '$path/Output.xlsx';
      final File file = File(fileName);
      await file.writeAsBytes(bytes, flush: true);
      OpenFile.open(fileName);

      workbook.dispose();
      print('Excel file created and opened successfully.');
      return 'Excel file created and opened successfully.';
    } else {
      print(
          'Failed to load attendance or employee data: ${responseAttendance.statusCode} - ${responseAttendance.reasonPhrase}');
      return 'Failed to load attendance or employee data';
    }
  } catch (e) {
    print("Error creating Excel file: $e");
    return 'Failed to create Excel file';
  }
}

DateTime parseTime(String date, String time) {
  try {
    final timeParts = time.split(' ');
    if (timeParts.length != 2) {
      throw FormatException('Invalid time format');
    }

    final hourMinute = timeParts[0].split(':');
    if (hourMinute.length != 2) {
      throw FormatException('Invalid hour-minute format');
    }

    final hour = int.parse(hourMinute[0]);
    final minute = int.parse(hourMinute[1]);
    final timeOfDay = timeParts[1].toUpperCase();

    if (timeOfDay != 'AM' && timeOfDay != 'PM') {
      throw FormatException('Invalid AM/PM format');
    }

    final isAM = timeOfDay == 'AM';

    return DateTime(
      int.parse(date.split('-')[2]), // Year
      int.parse(date.split('-')[1]), // Month
      int.parse(date.split('-')[0]), // Day
      hour == 12 ? (isAM ? 0 : 12) : (isAM ? hour : hour + 12),
      minute,
    );
  } catch (e) {
    print('Error parsing time: $e');
    return DateTime.now();
  }
}

String getInStatus(DateTime dateTime) {
  final hour = dateTime.hour;
  final minute = dateTime.minute;

  if (hour < 9 || (hour == 9 && minute <= 45)) {
    return 'Present';
  } else {
    return 'Late';
  }
}

String getOutStatus(DateTime dateTime) {
  final hour = dateTime.hour;
  final minute = dateTime.minute;

  if ((hour > 18 || (hour == 18 && minute >= 30)) ||
      (hour < 3 && minute == 0)) {
    return 'Punch Out';
  } else {
    return 'Early';
  }
}

