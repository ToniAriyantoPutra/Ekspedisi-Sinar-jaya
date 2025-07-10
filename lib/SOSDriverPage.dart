import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:app_projekskripsi/services/notification_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:app_projekskripsi/SosSupirPage.dart';

class SOSDriverPage extends StatefulWidget {
  @override
  _SOSDriverPageState createState() => _SOSDriverPageState();
}

class _SOSDriverPageState extends State<SOSDriverPage> {
  final String deviceToken = 'fdmtzRu8Tram-Wi51dfAIr:APA91bF657x-X7SilaoQ4vyypiZ3XEHtIwqRvVuZDAXABt57w-NZj-89auK4nqaz95XRuLueCZHQpEiCilRz5Dc6ZmsFqvZx_nj6WHAv0-_tFxqVVAo-OXA';
  final String deviceToken2 = 'euHps3jFSeeaTZYqtzpMY6:APA91bHxus_7jFKnHLVvsgyHEKVFOJIUjMOpXYOkS8v2SQ0mLZnN2SjpPbOl_PkymW3NIXhSTgwXA6E4Sw5_wmP0FgDXGRZe9e8dVO2cWgzyBKzaMEyve9k';
  final String deviceToken3 = 'fDjD3x0TRWGdpmC-cSEUrD:APA91bHedrHyPT90xt1ntr7e8moIHTHJ9jUPIOSaK-jm6Jbtd1dMUPuJZuLhlyoXRxlbQQxl1CqMDrCKP-bFp5G43hc3rG0lxKeabJFlYj-uPzp3c_fa0_s';
  String? _token = "No Token";
  String _location = "";
  NotificationScreen _notificationScreen = NotificationScreen();

  Future<String> _getUserLocation() async {
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

      return "Alamat: ${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}";
    } catch (e) {
      return "Gagal mendapatkan lokasi: $e";
    }
  }
  void getDeviceToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    setState(() {
      _token = token;
    });
    print("Firebase Messaging Token: $_token");
  }
  void _sendSOSNotification() async {
    String userLocation = await _getUserLocation();

    setState(() {
      _location = userLocation;
      getDeviceToken();
    });

    String title = 'Pengemudi Butuh Bantuan \n';
    String body = ' Lokasi saat ini: $_location';
    try {
      NotificationService.sendNotification(deviceToken, title, body);
      NotificationService.sendNotification(deviceToken2, title, body);
      NotificationService.sendNotification(deviceToken3, title, body);
      //await NotificationService.sendNotification(deviceToken, title, body);
      //await NotificationService.sendNotification(deviceToken2, title, body);
      //await NotificationService.sendNotification(deviceToken3, title, body);

      print('Notification sent successfully');
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SOS Driver Page'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _sendSOSNotification();

          },
          child: Text('Send SOS Notification'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,  // Set the background color to red
          ),
        ),
      ),
    );
  }

}

