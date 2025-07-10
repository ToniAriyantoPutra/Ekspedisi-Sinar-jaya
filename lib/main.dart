import 'package:app_projekskripsi/Wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:app_projekskripsi/Login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase conditionally based on the platform
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyCs0G8D2yBrdCShMRCRlM0wwMzDgEEn9aY",
        authDomain: "ekspedisisinarjaya.firebaseapp.com",
        databaseURL: "https://ekspedisisinarjaya-default-rtdb.firebaseio.com",
        projectId: "ekspedisisinarjaya",
        storageBucket: "ekspedisisinarjaya.appspot.com",
        messagingSenderId: "684510713618",
        appId: "1:684510713618:web:3951bd0dc7c5b9952405cb",
        measurementId: "G-N1K76Q8LK6",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Set the Login page as the initial page that the user sees when the app launches
      home: const Login(),
    );
  }
}

// Removed the main function from Login file as it is no longer necessary.
// The app will now start with the Login page automatically.
