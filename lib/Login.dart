import 'package:app_projekskripsi/AdminPage.dart';
import 'package:app_projekskripsi/ForgotPassword.dart';
import 'package:app_projekskripsi/Signup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_projekskripsi/AdminDaerahPage.dart';
import 'package:app_projekskripsi/SupirPage.dart';
import 'package:app_projekskripsi/UserPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscureText = true;

  Future<void> signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Call the route function to handle navigation based on user role
      await route(userCredential);
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Error',
        e.message ?? 'Login failed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        borderRadius: 10,
        margin: EdgeInsets.all(10),
        duration: Duration(seconds: 3),
        icon: Icon(Icons.error, color: Colors.white),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> route(UserCredential userCredential) async {
    User? user = userCredential.user;
    if (user != null) {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        String role = userDoc.get('role');

        switch (role) {
          case 'User':
            Get.off(() => UserPage());
            break;
          case 'Supir':
            Get.off(() => SupirPage());
            break;
          case 'SuperAdmin':
            Get.off(() => AdminPage());
            break;
          case 'AdminDaerah':
            Get.off(() => AdminDaerahPage());
            break;
          default:
            Get.snackbar(
              'Success',
              'Logged in successfully!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green.withOpacity(0.8),
              colorText: Colors.white,
              icon: Icon(Icons.check_circle, color: Colors.white),
            );
        }
      } else {
        Get.snackbar(
          'Error',
          'User document does not exist',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
          icon: Icon(Icons.error, color: Colors.white),
        );
      }
    } else {
      Get.snackbar(
        'Error',
        'User not found',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        icon: Icon(Icons.error, color: Colors.white),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[100]!, Colors.blue[400]!],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
                        child: Column(
                          children: [
                            Text(
                              'Ekspedisi Sinar Jaya',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                            SizedBox(height: 30),
                            TextFormField(
                              controller: emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'Enter your email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                prefixIcon: Icon(Icons.email, color: Colors.blue[700]),
                                filled: true,
                                fillColor: Colors.blue[50],
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!GetUtils.isEmail(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            TextFormField(
                              controller: passwordController,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                prefixIcon: Icon(Icons.lock, color: Colors.blue[700]),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureText ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.blue[700],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureText = !_obscureText;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: Colors.blue[50],
                              ),
                              obscureText: _obscureText,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 30),
                            _isLoading
                                ? CircularProgressIndicator(color: Colors.blue[700])
                                : ElevatedButton(
                              onPressed: signIn,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                                backgroundColor: Colors.blue[700],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                              ),
                              child: Text(
                                "Login",
                                style: TextStyle(fontSize: 18, color: Colors.white),
                              ),
                            ),
                            SizedBox(height: 20),
                            TextButton(
                              onPressed: () => Get.to(() => ForgotPassword()),
                              child: Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Get.to(() => Signup()),
                      child: Text(
                        "Don't have an account? Register Now",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(GetMaterialApp(
    debugShowCheckedModeBanner: false,
    home: Login(),
    theme: ThemeData(
      primarySwatch: Colors.blue,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    ),
  ));
}
