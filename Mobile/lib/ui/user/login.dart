import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/ui/uihelper.dart';
import 'package:flutter_application_2/ui/homepage/home_page.dart';
import 'package:flutter_application_2/ui/user/signapp.dart';
import 'project_description_popup.dart'; // Import the popup widget

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController emailControler = TextEditingController();
  TextEditingController passwordControler = TextEditingController();

  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      return UiHelper.CustomAlertBox(context, "Enter Required Fields");
    } else {
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        print('User signed in: ${userCredential.user?.email}');

        // Retrieve the Raspberry Pi ID from Firestore
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('raspberryIds')
            .doc(email)
            .get();

        if (snapshot.exists) {
          String raspberryPiId = snapshot.get('raspberryPiId');
          print('Raspberry Pi ID found: $raspberryPiId');
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => HomePage(raspberryPiId: raspberryPiId)));
        } else {
          await FirebaseAuth.instance.signOut();
          UiHelper.CustomAlertBox(context, "Raspberry Pi ID not found. Please sign up again.");
        }
      } on FirebaseAuthException catch (ex) {
        print('FirebaseAuthException: ${ex.code}');
        return UiHelper.CustomAlertBox(context, ex.code.toString());
      } on FirebaseException catch (ex) {
        print('FirebaseException: ${ex.code} - ${ex.message}');
        return UiHelper.CustomAlertBox(context, "Firebase error: ${ex.message}");
      } catch (e) {
        print('Error: $e');
        return UiHelper.CustomAlertBox(context, "An error occurred: $e");
      }
    }
  }

  void _showProjectDescription(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ProjectDescriptionPopup(
          description: 'This project was made by Octavian Nistora and Prindii Gabriel in the scope of making a solution to assist cars with older technology to integrate in this era of IoT.',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData  = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Car Assist"),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          UiHelper.CustomTextField(
            emailControler,
            "Email",
            Icons.mail,
            false,
            placeholder: "Enter your email",
            placeholderColor: Colors.grey, // Placeholder color
          ),
          UiHelper.CustomTextField(
            passwordControler,
            "Password",
            Icons.password,
            true,
            placeholder: "Enter your password",
            placeholderColor: Colors.grey, // Placeholder color
          ),
          const SizedBox(height: 20),
          UiHelper.CustomButton(() {
            login(emailControler.text, passwordControler.text);
          }, "Login"),
          const SizedBox(height: 40),
          Row(
            children: [
              const Text(
                "            Don't have an Account?",
                style: TextStyle(fontSize: 16),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpPage()));
                },
                child: Text(
                  "Sign Up",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: themeData.primaryColor, // Set the color to green
                  ),
                ),
              )
            ],
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProjectDescription(context),
        child: const Icon(Icons.help_outline),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
