import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomepageAdmin extends StatefulWidget {
  const HomepageAdmin({super.key});

  @override
  State<HomepageAdmin> createState() => _HomepageAdminState();
}

class _HomepageAdminState extends State<HomepageAdmin> {

  final user= FirebaseAuth.instance.currentUser;

  signout() async{
    await FirebaseAuth.instance.signOut();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Welcome"),),
      body: Center(
        child: Text('${user!.email}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (()=> signout()),
        child: Icon(Icons.logout_rounded),
      ),
    );
  }
}
