import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/cupertino.dart';

class NotificationService {
  static Future<void> initialize() async {
    // Request notification permission for iOS
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("User granted permission for notifications");
    } else {
      print("User declined or has not accepted permission");
    }

    // Initialize local notifications
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings androidInitializationSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(android: androidInitializationSettings);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Handling foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Received message: ${message.notification?.title}');
      if (message.notification != null) {
        await flutterLocalNotificationsPlugin.show(
          0,
          message.notification?.title,
          message.notification?.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'your_channel_id', 'your_channel_name',
              importance: Importance.max,
              priority: Priority.high,
              showWhen: false,
            ),
          ),
        );
      }
    });

    // Handling background notifications
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print("Handling a background message: ${message.messageId}");
  }
}
