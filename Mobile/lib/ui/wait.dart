import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_2/ui/user/login.dart';

import 'homepage/home_page.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    Future.delayed(const Duration(seconds: 7), () async {
      await _navigateBasedOnAuthStatus();
    });
  }

  Future<void> _navigateBasedOnAuthStatus() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      print('Current user: $user');
      if (user != null) {
        // Retrieve the Raspberry Pi ID from Firestore
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('raspberryIds')
            .doc(user.email)
            .get();

        if (snapshot.exists) {
          String raspberryPiId = snapshot.get('raspberryPiId');
          print('Raspberry Pi ID found: $raspberryPiId');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomePage(raspberryPiId: raspberryPiId)),
          );
        } else {
          print('Raspberry Pi ID not found, signing out');
          // If the Raspberry Pi ID does not exist, log the user out and show the login page
          await FirebaseAuth.instance.signOut();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      } else {
        print('No user signed in, navigating to login page');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } catch (e) {
      print('Error: $e');
      // If there is any error (e.g., network issues, Firestore errors), show the login page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/finalimage.jpeg"),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
