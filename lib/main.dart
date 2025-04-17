// ignore_for_file: use_key_in_widget_constructors, avoid_print, avoid_web_libraries_in_flutter, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shri_ganesh_classes/pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCa6D2JxItosuAVZNJoWRSwEIGEL9MWWSo",
      projectId: "shreeapp-41b65",
      storageBucket: "shreeapp-41b65.firebasestorage.app",
      messagingSenderId: "267300961273",
      appId: "1:267300961273:android:5d65724175ca8318b95b28",
    ),
  ); // <<<<<<<< ✅ Semicolon हवी होती इथे

  // 🔥 याला विसरू नको!
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(), // <-- Directly using LoginPage as the home screen
    );
  }
}
