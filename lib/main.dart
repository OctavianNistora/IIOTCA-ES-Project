import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the default app if needed
  if (!kIsWeb) {
    await Firebase.initializeApp(
      name: "android",
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Initialize additional app for web if needed s
  if (kIsWeb) {
    print("web");
    await Firebase.initializeApp(

      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real-time Data',
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DatabaseReference _databaseReference =
  FirebaseDatabase.instance.reference().child('/');


  String? _realTimeData;

  @override
  void initState() {
    super.initState();
    _databaseReference.onValue.listen((event) {
      setState(() {
        _realTimeData = event.snapshot.value.toString();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Data'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Real-time Data:',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 16),
            _realTimeData != null
                ? Text(
              _realTimeData!,
              style: const TextStyle(fontSize: 18),
            )
                : CircularProgressIndicator(), // Display a loading indicator while data is being fetched
          ],
        ),
      ),
    );
  }
}
