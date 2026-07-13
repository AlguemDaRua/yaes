// Firebase options for the shared YA backend project: ya-app-z.
//
// Web values come from the Firebase web app configuration. Mobile values are
// kept in sync with ya-app so the panel can reuse the same backend.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAvA6C5_rS4HI8lyakHUSrdYe0Iemlrqlg',
    authDomain: 'ya-app-z.firebaseapp.com',
    databaseURL: 'https://ya-app-z-default-rtdb.firebaseio.com',
    projectId: 'ya-app-z',
    storageBucket: 'ya-app-z.firebasestorage.app',
    messagingSenderId: '432248591325',
    appId: '1:432248591325:web:cbd8db1e69395e88a89c34',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCZUfA5L6poVTO2c6xANv-oW3lK4TDQ8xQ',
    appId: '1:432248591325:android:a94a81ddf2a53f2fa89c34',
    messagingSenderId: '432248591325',
    projectId: 'ya-app-z',
    databaseURL: 'https://ya-app-z-default-rtdb.firebaseio.com',
    storageBucket: 'ya-app-z.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCZUfA5L6poVTO2c6xANv-oW3lK4TDQ8xQ',
    appId: '1:432248591325:ios:placeholder',
    messagingSenderId: '432248591325',
    projectId: 'ya-app-z',
    databaseURL: 'https://ya-app-z-default-rtdb.firebaseio.com',
    storageBucket: 'ya-app-z.firebasestorage.app',
    iosClientId:
        '432248591325-b4dcl43ei148np46j5nsrepot4d3d17g.apps.googleusercontent.com',
    iosBundleId: 'com.example.limousineexecutive',
  );
}
