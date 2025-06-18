import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer'; // For log()

// Import your screen widgets
import 'screens/profile_screen.dart'; // Make sure this path is correct
import 'screens/login_screen.dart';   // Make sure this path is correct
// Import other screens if needed for routes, e.g.:
// import 'screens/admin_home_screen.dart';
// import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ensure Firebase is initialized.
  // If you used Firebase CLI and have firebase_options.dart, uncomment the next line:
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Firebase.initializeApp(); // Use this if you don't have options file or for basic init

  User? user;
  bool autoLoginSuccess = false;

  try {
    // Attempt to sign out any existing user for a clean test slate
    await FirebaseAuth.instance.signOut();
    log('Previous user signed out for testing.');

    // Attempt to sign in with the specified credentials
    UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: "payardgt@gmail.com",
      password: "nimama",
    );
    user = userCredential.user;
    if (user != null) {
      autoLoginSuccess = true;
      log('Auto-login successful for: ${user.email}');
    }
  } on FirebaseAuthException catch (e) {
    log('Auto-login failed: ${e.code} - ${e.message}');
  } catch (e) {
    log('An unexpected error occurred during auto-login: $e');
  }

  runApp(MyApp(isAutoLoginSuccessful: autoLoginSuccess));
}

class MyApp extends StatelessWidget {
  final bool isAutoLoginSuccessful;

  const MyApp({super.key, required this.isAutoLoginSuccessful});

  @override
  Widget build(BuildContext context) {
    // Adhering to Figma Guidelines for Theme
    // (Font: SofiaSans, Primary Color: Based on previous interactions)
    return MaterialApp(
      title: 'Restaurant Recommendation App', // Replace with your actual app name
      theme: ThemeData(
        primaryColor: const Color(0xFFFF7F59), // Figma Guideline: Primary Color
        scaffoldBackgroundColor: Colors.white, // Figma Guideline: Background Color (adjust if needed)
        fontFamily: 'SofiaSans', // Figma Guideline: Default Font
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFFFF7F59), // Figma Guideline: Primary Color
          secondary: const Color(0xFFFF7F59), // Figma Guideline: Accent/Secondary Color (adjust as needed)
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFF7F59), // Figma Guideline: AppBar Color
          titleTextStyle: TextStyle(
            fontFamily: 'SofiaSans', // Figma Guideline: Font
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(
            color: Colors.white, // Figma Guideline: AppBar Icon Color
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF7F59), // Figma Guideline: Button Color
            foregroundColor: Colors.white, // Figma Guideline: Button Text Color
            textStyle: const TextStyle(
              fontFamily: 'SofiaSans', // Figma Guideline: Font
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24), // Figma Guideline: Button Padding
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30), // Figma Guideline: Button Shape
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme( // Figma Guideline: Input Field Style
          labelStyle: const TextStyle(fontFamily: 'SofiaSans', color: Colors.grey),
          hintStyle: const TextStyle(fontFamily: 'SofiaSans', color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), // Figma Guideline: Input Shape
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF7F59), width: 2), // Figma Guideline: Input Focus Color
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      // If auto-login was successful, navigate to ProfileScreen.
      // Otherwise, fall back to LoginScreen.
      home: isAutoLoginSuccessful ? const ProfileScreen() : const LoginScreen(),
      routes: {
        // Define your named routes here if you use them
        // This ensures ProfileScreen can be navigated to if it's not the initial home
        '/profile': (context) => const ProfileScreen(),
        '/login': (context) => const LoginScreen(),
        // Example other routes based on previous discussions:
        // '/adminDashboard': (context) => const AdminHomeScreen(),
        // '/userHome': (context) => const HomeScreen(),
      },
    );
  }
}