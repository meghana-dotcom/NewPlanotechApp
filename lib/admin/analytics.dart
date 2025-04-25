import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:planotech/baseurl.dart';

class AttendanceAnalytics {
  Future<Map<String, int>> getAttendanceAnalytics(
      String employeeId, int month, int year) async {
    final startDate = DateTime(year, month, 1);
    final currentDate = DateTime.now();
    final lastDay = (month == currentDate.month && year == currentDate.year)
        ? currentDate.day
        : DateTime(year, month + 1, 0).day;

    try {
      final responseAttendance = await http.post(Uri.parse(
          baseurl+'/admin/fetchallattendancebystartandenddate?startingdate=${startDate.day}-${startDate.month}-${startDate.year}&enddate=$lastDay-$month-$year'));

      if (responseAttendance.statusCode == 200) {
        final Map<String, dynamic> attendanceData =
            json.decode(responseAttendance.body);
        final body = attendanceData['body'];

        if (body == null || body is! List) {
          return {'Present': 0, 'Absent': 0, 'Late': 0, 'Holiday': 0};
        }

        int presentCount = 0;
        int absentCount = 0;
        int lateCount = 0;
        int holidayCount = 0;

        // Track days with attendance records
        List<DateTime> attendedDays = [];

        // Process attendance for the specific employee
        for (var employee in body) {
          if (employee['emp_Code'].toString() == employeeId) {
            final dayAndDate = employee['dayAndDate'];
            if (dayAndDate != null && dayAndDate is List) {
              for (var dayEntry in dayAndDate) {
                final date = dayEntry['date'];
                final attendance = (dayEntry['attendance'] ?? '').toLowerCase();
                final attendanceDetails = dayEntry['attendance_Details'] ?? [];
                final dateObj = DateTime.parse(
                    "${date.split('-')[2]}-${date.split('-')[1]}-${date.split('-')[0]}");

                // Track attended days
                attendedDays.add(dateObj);

                if (dateObj.month == month && dateObj.year == year) {
                  if (attendance == 'absent') {
                    // Exclude Sundays from absent count
                    if (dateObj.weekday != DateTime.sunday) {
                      absentCount++;
                    }
                  } else if (attendance == 'holiday') {
                    // Count holidays but exclude Sundays
                    if (dateObj.weekday != DateTime.sunday) {
                      holidayCount++;
                    }
                  } else {
                    bool firstPunchInIsLate = false;

                    for (var i = 0; i < attendanceDetails.length; i++) {
                      var detail = attendanceDetails[i];
                      if (detail['attendance_status'] != null &&
                          detail['attendance_status']
                              .toLowerCase()
                              .contains('punch in')) {
                        final punchInTime = parseTime(date, detail['time']);

                        // Only consider the first punch-in status
                        if (i == 0) {
                          firstPunchInIsLate =
                              getInStatus(punchInTime) == 'Late';
                        }
                      }
                    }

                    // Increment present count for all valid punch-ins, including late
                    presentCount++;
                    if (firstPunchInIsLate) {
                      lateCount++;
                    }
                  }
                }
              }
            }
          }
        }

        // Calculate absent days excluding Sundays without attendance
        for (int day = 1; day <= lastDay; day++) {
          final currentDay = DateTime(year, month, day);
          if (!attendedDays.any((d) => d.day == currentDay.day)) {
            // Count as absent only if it's not a Sunday
            if (currentDay.weekday != DateTime.sunday) {
              absentCount++;
            }
          }
        }

        // Return the computed values for present (including late), absent, late, and holiday counts
        return {
          'Present': presentCount, // Includes late as well
          'Absent': absentCount, // Excludes Sundays
          'Late': lateCount, // Separate late count
          'Holiday': holidayCount, // Separate holiday count, excluding Sundays
        };
      } else {
        print(
            'Failed to load attendance data. Status Code: ${responseAttendance.statusCode}');
        return {'Present': 0, 'Absent': 0, 'Late': 0, 'Holiday': 0};
      }
    } catch (e) {
      print("Error fetching analytics: $e");
      return {'Present': 0, 'Absent': 0, 'Late': 0, 'Holiday': 0};
    }
  }

  DateTime parseTime(String date, String time) {
    try {
      time = time.trim().replaceAll(RegExp(r'\s+'), ' ');
      final timeParts =
          RegExp(r'(\d{1,2}:\d{2})\s?(AM|PM)', caseSensitive: false)
              .firstMatch(time);

      if (timeParts == null || timeParts.groupCount < 2) {
        throw FormatException('Invalid time format: $time');
      }

      final hourMinute = timeParts.group(1)!.split(':');
      final hour = int.parse(hourMinute[0]);
      final minute = int.parse(hourMinute[1]);
      final timeOfDay = timeParts.group(2)!.toUpperCase();
      final isAM = timeOfDay == 'AM';

      return DateTime(
        int.parse(date.split('-')[2]),
        int.parse(date.split('-')[1]),
        int.parse(date.split('-')[0]),
        hour == 12 ? (isAM ? 0 : 12) : (isAM ? hour : hour + 12),
        minute,
      );
    } catch (e) {
      throw FormatException('Error parsing time: $e');
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
}
