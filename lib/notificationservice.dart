import 'dart:io';
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:planotech/dashboard.dart';

class NotificationServices {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationServices() {
    _initializeTimeZone();
  }

  void _initializeTimeZone() {
    tz.initializeTimeZones();
    tz.setLocalLocation(
        tz.getLocation('America/Detroit')); // Set to your local time zone
  }

  Future<void> requestNotificationPermission(BuildContext context) async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      print("User granted permission");
      await requestExactAlarmPermission(); // Request exact alarm permission for Android 12+
      await firebaseInit(context);
    } else {
      print("User denied permission");
    }
  }

  Future<String?> getDeviceToken() async {
    try {
      String? token = await messaging.getToken();
      return token;
    } catch (e) {
      print('Error getting device token: $e');
      return null;
    }
  }

  void isTokenRefreshed(Function(String) onTokenRefreshCallback) {
    messaging.onTokenRefresh.listen((String newToken) {
      print("Token refreshed: $newToken");
      onTokenRefreshCallback(
          newToken); // Call the provided callback with the new token
    });
  }

  Future<void> firebaseInit(BuildContext context) async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (Platform.isAndroid) {
        handleMessage(context, message);
        initLocalNotification(context, message);
        showNotification(message);
      }
    });

    // Handle notification when the app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleMessage(context, message);
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  void initLocalNotification(
      BuildContext context, RemoteMessage message) async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings(
            '@mipmap/ic_launcher'); // Ensure this matches your icon name
    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings();

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveBackgroundNotificationResponse:
          backgroundNotificationResponse,
    );
  }

  Future<void> showNotification(RemoteMessage message) async {
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      Random.secure().nextInt(1000).toString(),
      "high importance",
      importance: Importance.max,
    );

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: 'Your channel description',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/launcher_icon', // Ensure this matches your icon name
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? 'No Title',
      message.notification?.body ?? 'No Body',
      notificationDetails,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      channelDescription: 'your channel description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/launcher_icon', // Ensure this matches your icon name
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  void handleMessage(BuildContext context, RemoteMessage message) {
    if (true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Dashboard(),
        ),
      );
    }
  }

  // Top-level function for handling background notifications
  Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    // Handle the background notification here
  }

  void backgroundNotificationResponse(
      NotificationResponse notificationResponse) {
    // Handle the background notification response here
    print('Notification Response: ${notificationResponse.payload}');
  }

  Future<void> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    }
  }

  void initialize(BuildContext context) {}
}
