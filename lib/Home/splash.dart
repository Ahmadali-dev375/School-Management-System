// ignore_for_file: use_build_context_synchronously, file_names

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:workit/Auth/Login.dart';
import 'package:workit/Home/NavBar.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Simulate splash screen delay
    await Future.delayed(const Duration(seconds: 2));

    if (auth.currentUser == null) {
      // Navigate to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TeacherLoginScreen()),
      );
    } else {
      // Navigate to home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BottomNavBar()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/econ.jpg', width: 300, height: 300),
            SizedBox(height: 19),
            Text(
              'Noble School System & College',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'Way to Success',
              style: TextStyle(
                fontSize: 22,
                fontStyle: FontStyle.italic,
                color: Color(0xFF8A0204),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
