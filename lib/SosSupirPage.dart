import 'package:app_projekskripsi/SOSDriverPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_projekskripsi/services/Notif_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String? _token = "No Token";
  String _location = "Tekan tombol untuk mendapatkan lokasi";
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    NotificationService.initialize();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    initializeLocalNotifications();
    getDeviceToken();
  }

  // Initialize local notifications
  void initializeLocalNotifications() {
    const AndroidInitializationSettings androidInitializationSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(android: androidInitializationSettings);
    flutterLocalNotificationsPlugin.initialize(initializationSettings, onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
  }

  // Handle notification tap
  void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) {
    if (notificationResponse.payload != null) {
      print('Notification payload: ${notificationResponse.payload}');
      // Navigate to NotificationDetailScreen with the payload as content
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NotificationDetailScreen(payload: notificationResponse.payload!)),
      );
    }
  }

  // Fetch Firebase token
  void getDeviceToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    setState(() {
      _token = token;
    });
    print("Firebase Messaging Token: $_token");
  }

  // Method to get user location
  Future<void> _getUserLocation() async {
    try {
      // Request permission and get user position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Retrieve address information from latitude and longitude
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      // Use the first placemark to get detailed address
      Placemark place = placemarks[0];

      setState(() {
        _location = "Alamat: ${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}";
      });
    } catch (e) {
      setState(() {
        _location = "Gagal mendapatkan lokasi: $e";
      });
    }
  }

  // Method to send notification with user location
  void sendNotification() async {
    await _getUserLocation();
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'SOS Butuh Bantuan',
      'Lokasi saat ini: $_location',
      platformChannelSpecifics,
      payload: _location,
    );
    print("SOS Button");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("SOS button"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Tombol ini akan mengarahkan anda ke page SOS Jika Hanya Keadaan Darurat"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SOSDriverPage()), // Berpindah ke SecondPage
                );
              },
              child: Text("Selanjutnya"),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationDetailScreen extends StatelessWidget {
  final String payload;

  NotificationDetailScreen({required this.payload});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notification Detail"),
      ),
      body: Center(
        child: Text("Notification Payload: $payload"),
      ),
    );
  }
}
