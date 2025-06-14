import 'package:flutter/material.dart';
// import 'package:smart_food_v1/screens/favourites_screen.dart';
// import 'package:smart_food_v1/screens/feedback_screen.dart';
// import 'package:smart_food_v1/screens/home_screen.dart';
// import 'package:smart_food_v1/screens/register_screen.dart';
// import 'package:smart_food_v1/screens/profile_screen.dart';
import 'package:smart_food_v1/screens/welcome_screen.dart';
// import 'package:smart_food_v1/screens/admin_home_screen.dart';

void main() {
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
      // home: const HomeScreen(),
      // home: const FeedbackScreen(),
      // home: const FavouritesScreen(),
      // home: const ProfileScreen(),
      // home: const VerificationScreen(email: "wongjuwei@gmail.com"),
    );
  }
}