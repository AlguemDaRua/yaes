// File generated based on google-services.json for project ya-app-z
// Project ID: ya-app-z
// Firebase URL: https://ya-app-z-default-rtdb.firebaseio.com

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCZUfA5L6poVTO2c6xANv-oW3lK4TDQ8xQ',
    appId: '1:432248591325:android:2cd70d8e5d9b3958a89c34',
    messagingSenderId: '432248591325',
    projectId: 'ya-app-z',
    databaseURL: 'https://ya-app-z-default-rtdb.firebaseio.com',
    storageBucket: 'ya-app-z.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCZUfA5L6poVTO2c6xANv-oW3lK4TDQ8xQ',
    appId: '1:432248591325:ios:84b362f0065603bda89c34',
    messagingSenderId: '432248591325',
    projectId: 'ya-app-z',
    databaseURL: 'https://ya-app-z-default-rtdb.firebaseio.com',
    storageBucket: 'ya-app-z.firebasestorage.app',
    iosClientId: '432248591325-b4dcl43ei148np46j5nsrepot4d3d17g.apps.googleusercontent.com',
    iosBundleId: 'mz.co.ya.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCZUfA5L6poVTO2c6xANv-oW3lK4TDQ8xQ',
    appId: '1:432248591325:web:placeholder',
    messagingSenderId: '432248591325',
    projectId: 'ya-app-z',
    databaseURL: 'https://ya-app-z-default-rtdb.firebaseio.com',
    storageBucket: 'ya-app-z.firebasestorage.app',
    authDomain: 'ya-app-z.firebaseapp.com',
  );
}
