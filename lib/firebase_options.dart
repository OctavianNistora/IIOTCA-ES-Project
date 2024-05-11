import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    // Update with your web Firebase configuration
    apiKey: 'ADDHERE YOUR API KEY',
    appId: '1:884253830844:web:3a881604b0b521d1d86ab9',
    messagingSenderId: '884253830844',
    projectId: 'ot-project-48691',
    authDomain: 'iot-project-48691.firebaseapp.com',
    databaseURL: 'https://iot-project-48691-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'iot-project-48691.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    // Update with your Android Firebase configuration
    apiKey: 'ADD HERE YOUR API KEY',
    appId: '1:884253830844:android:ededfa0fb300bd70d86ab9',
    messagingSenderId: '884253830844',
    projectId: 'ot-project-48691',
    databaseURL: 'https://iot-project-48691-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'iot-project-48691.appspot.com',
  );
}
