import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:firebase_database/firebase_database.dart';

class AudioService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isServiceEnabled = false;
  final DatabaseReference _databaseReference;
  final BuildContext context;
  final String raspberryPiId;

  AudioService(this._databaseReference, this.context, this.raspberryPiId) {
    _flutterTts.setLanguage("en-US");
  }

  void toggleService() {
    _isServiceEnabled = !_isServiceEnabled;
    if (_isServiceEnabled) {
      print('AudioService enabled');
      _databaseReference.child('signs-detected').onValue.listen(_onDataEvent);
    } else {
      print('AudioService disabled');
      _databaseReference.child('signs-detected').onValue.listen(null);
    }
  }

  void _onDataEvent(DatabaseEvent event) {
    if (!_isServiceEnabled) return;

    // Check if the data exists and is not null
    if (event.snapshot.value != null) {
      try {
        List<dynamic> signs = event.snapshot.value as List<dynamic>;
        print('Signs detected: $signs');
        if (signs.contains(0)) {
          _speakAndShowImage("STOP", "assets/stop.png");
          _removeSignFromDatabase(signs, 0);
        } else if (signs.contains(1)) {
          _speakAndShowImage("SLOW DOWN", "assets/slow_down.png");
          _removeSignFromDatabase(signs, 1);
        }
      } catch (e) {
        print('Error casting data to List<dynamic>: $e');
      }
    } else {
      print('No signs detected data available.');
    }
  }


  void _removeSignFromDatabase(List<dynamic> signs, int valueToRemove) {
    signs.remove(valueToRemove);
    _databaseReference.child('signs-detected').set(signs);
  }

  void _speakAndShowImage(String message, String imagePath) async {
    print('Speaking: $message');
    await _flutterTts.speak(message);
    _showImagePopup(imagePath);
  }

  void _showImagePopup(String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pop(true);
        });
        return Dialog(
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }
}
