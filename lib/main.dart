import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer'; // For log()

import 'screens/home_screen.dart';
import 'screens/admin_home_screen.dart'; // Add this import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load();

  User? user;
  bool autoLoginSuccess = false;

  try {
    // Attempt to sign out any existing user for a clean test slate
    await FirebaseAuth.instance.signOut();
    log('Previous user signed out for testing.');

    // Attempt to sign in as admin
    UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: "payardmmu@gmail.com",
      password: "payardmmu",
    );
    user = userCredential.user;
    if (user != null) {
      autoLoginSuccess = true;
      log('Admin auto-login successful for: ${user.email}');
    }
  } on FirebaseAuthException catch (e) {
    log('Admin auto-login failed: ${e.code} - ${e.message}');
  } catch (e) {
    log('An unexpected error occurred during admin auto-login: $e');
  }

  runApp(MyApp(isAutoLoginSuccessful: autoLoginSuccess));
}

class MyApp extends StatelessWidget {
  final bool isAutoLoginSuccessful;

  const MyApp({super.key, required this.isAutoLoginSuccessful});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant Recommendation App',
      theme: ThemeData(
        primaryColor: const Color(0xFFFF7F59),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'SofiaSans',
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFFFF7F59),
          secondary: const Color(0xFFFF7F59),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFF7F59),
          titleTextStyle: TextStyle(
            fontFamily: 'SofiaSans',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF7F59),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontFamily: 'SofiaSans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: const TextStyle(fontFamily: 'SofiaSans', color: Colors.grey),
          hintStyle: const TextStyle(fontFamily: 'SofiaSans', color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF7F59), width: 2),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      // Always go to AdminHomeScreen if auto-login is successful
      home: isAutoLoginSuccessful ? const AdminHomeScreen() : HomeScreen(),
    );
  }
}