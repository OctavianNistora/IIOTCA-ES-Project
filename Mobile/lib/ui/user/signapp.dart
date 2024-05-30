import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/ui/homepage/home_page.dart';
import 'package:flutter_application_2/ui/uihelper.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  TextEditingController emailControler = TextEditingController();
  TextEditingController passwordControler = TextEditingController();
  TextEditingController raspberryPiIdControler = TextEditingController();

  signUp(String email, String password, String raspberryPiId) async {
    if (email == "" || password == "" || raspberryPiId == "") {
      return UiHelper.CustomAlertBox(context, "Enter Required Fields");
    } else {
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        // Store the Raspberry Pi ID in Firestore
        await FirebaseFirestore.instance
            .collection('raspberryIds')
            .doc(email)
            .set({'raspberryPiId': raspberryPiId});

        Navigator.push(
            context, MaterialPageRoute(builder: (context) => HomePage(raspberryPiId: raspberryPiId)));
      } on FirebaseAuthException catch (ex) {
        return UiHelper.CustomAlertBox(context, ex.code.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign Up on Car Assist"),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          UiHelper.CustomTextField(emailControler, "Email", Icons.mail, false),
          UiHelper.CustomTextField(
              passwordControler, "Password", Icons.password, true),
          UiHelper.CustomTextField(
              raspberryPiIdControler, "Raspberry Pi ID", Icons.memory, false),
          const SizedBox(height: 30),
          UiHelper.CustomButton(() {
            signUp(emailControler.text.toString(), passwordControler.text.toString(), raspberryPiIdControler.text.toString());
          }, "SignUp"),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
