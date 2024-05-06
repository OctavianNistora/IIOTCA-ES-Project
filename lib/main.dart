import 'dart:async';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:real_time_chart/real_time_chart.dart';
import 'firebase_options.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the default app if needed
  if (!kIsWeb) {
    await Firebase.initializeApp(
      name: "android",
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Initialize additional app for web if needed
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
  Widget build(BuildContext context) => MaterialApp(
    title: 'Real-time Data',
    home: const MyHomePage(),
  );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DatabaseReference _databaseReference =
  FirebaseDatabase.instance.reference().child('/');
  int _value1 = 0;
  int _value2 = 0;
  int _value3 = 0;
  String _value4 = "false";
  late Stream<double> stream;
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _databaseReference.onValue.listen((event) {
      try {
        setState(() {
          final data = event.snapshot.value.toString();
          final List<String> values = data.split(',');

          if (values.length >= 4) {
            _value1 = int.tryParse(
                values[0].trim().replaceAll(RegExp(r'[^0-9]'), '')) ??
                0;
            _value2 = int.tryParse(
                values[1].trim().replaceAll(RegExp(r'[^0-9]'), '')) ??
                0;
            _value3 = int.tryParse(
                values[2].trim().replaceAll(RegExp(r'[^0-9]'), '')) ??
                0;
            List<String> clean = values[3].split(':');
            _value4 =
                clean[1].trim().toLowerCase().replaceAll(RegExp(r'}'), "");
          }
        });
      } catch (e) {
        print('Error: $e');
      }
    });
    stream = Stream.periodic(const Duration(milliseconds: 500), (_) {
      return _value1.toDouble();
    }).asBroadcastStream();
  }

  Future<void> speak() async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setSpeechRate(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak("Please slow down, you stupid fuck! slow the fuck, down.");
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Real-time Data'),
    ),
    body: SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Real-time Data:',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 16),
            Text(
              'Value 1: $_value1',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Value 2: $_value2',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Value 3: $_value3',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Value 4: $_value4',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.width * 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: RealTimeGraph(
                  stream: stream,
                  supportNegativeValuesDisplay: false,
                  xAxisColor: Colors.black12,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: speak,
              child: Text('Press me for text to speech'),
            ),
          ],
        ),
      ),
    ),
  );
}
