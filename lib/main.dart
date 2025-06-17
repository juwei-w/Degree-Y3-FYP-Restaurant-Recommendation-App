import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'firebase_options.dart'; // Import the generated Firebase options
// import 'package:smart_food_v1/screens/profile_screen.dart';
import 'package:smart_food_v1/screens/welcome_screen.dart';
// import 'package:smart_food_v1/screens/make_user_admin_screen.dart'; // Import your location screen

Future<void> main() async { // Make main asynchronous
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter bindings are initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Use the generated options
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp( 
      title: 'FoodieFy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        fontFamily: 'Roboto',
      ),
      home: const WelcomeScreen(),
      // home: const MyLocationScreen(), // Set MyLocationScreen as the home screen
    );
  }
}