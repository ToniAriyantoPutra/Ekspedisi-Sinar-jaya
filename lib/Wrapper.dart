import 'package:app_projekskripsi/AdminPage.dart';
import 'package:app_projekskripsi/AdminDaerahPage.dart';
import 'package:app_projekskripsi/SupirPage.dart';
import 'package:app_projekskripsi/Login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            User? user = snapshot.data;
            if (user != null) {
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (userSnapshot.hasData) {
                    var userDoc = userSnapshot.data;
                    if (userDoc != null && userDoc.exists) {
                      String role = userDoc.get('role');
                      if (role == 'User') {
                        return AdminPage();
                      } else if (role == 'Supir') {
                        return SupirPage();
                      } else if (role == 'AdminDaerah') {
                        return AdminDaerahPage();
                      } else {
                        return Login(); // Default case if role is not recognized
                      }
                    } else {
                      return Login(); // If the document does not exist
                    }
                  } else {
                    return Login(); // If there is an error retrieving the document
                  }
                },
              );
            } else {
              return Login(); // If user is null
            }
          } else {
            return Login(); // If snapshot has no data
          }
        },
      ),
    );
  }
}

