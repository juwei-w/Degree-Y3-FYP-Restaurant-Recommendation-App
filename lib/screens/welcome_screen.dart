import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../widgets/custom_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/welcome_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 180), // Increased top padding
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Welcome to\n',
                        style: TextStyle(
                          fontFamily: 'SofiaSans',
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: 'FoodieFy',
                        style: TextStyle(
                          fontFamily: 'Basic',
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Find your next favourite bite.',
                  style: TextStyle(
                    fontFamily: 'SofiaSans',
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const Spacer(),                
                const SizedBox(height: 40),
                CustomButton(
                  text: 'Log In',
                  backgroundColor: Colors.white,
                  textColor: Colors.black,
                  onPressed: () => _navigateToLogin(context),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Register',
                  backgroundColor: Colors.transparent,
                  textColor: Colors.white,
                  onPressed: () => _navigateToRegister(context),
                  hasBorder: true,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account?',
                      style: TextStyle(
                        fontFamily: 'SofiaSans',
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _navigateToLogin(context),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontFamily: 'SofiaSans',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _navigateToRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }
}