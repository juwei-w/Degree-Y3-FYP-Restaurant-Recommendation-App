import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/welcome_screen.dart'; // Import the welcome screen

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load();

  // Run the app with the WelcomeScreen as the home screen (no auto-login logic)
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Foodiefy',
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
      home: WelcomeScreen(),
    );
  }
}