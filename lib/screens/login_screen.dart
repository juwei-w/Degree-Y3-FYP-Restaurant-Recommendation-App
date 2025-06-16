import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_food_v1/screens/register_screen.dart'; // For navigation
import 'welcome_screen.dart';
import 'home_screen.dart';
// import 'admin_home_screen.dart'; // Admin home screen import can remain if you plan to use it later
import 'package:logger/logger.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // For form validation
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isUserRole = true; // Default to User - UI will reflect this, logic will ignore for now
  bool _isLoading = false; // For loading indicator
  final _logger = Logger(); // Assuming you have a logger

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        await user.reload(); // Crucial: Get the latest user status from Firebase
        _logger.i("User signed in: ${user.uid}, Email Verified: ${user.emailVerified}");

        if (user.emailVerified) {
          _logger.i("Email is verified. Navigating to HomeScreen.");
          if (mounted) {
            // Navigate to your main app screen (e.g., HomeScreen)
            // Example:
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        } else {
          _logger.w("Email not verified for user: ${user.email}. Deleting unverified account.");
          String? userEmailForMessage = user.email; // Store email for message before user object becomes invalid

          // Inform the user before deleting
          if (mounted) {
            await showDialog(
              context: context,
              barrierDismissible: false, // User must acknowledge
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  title: const Text('Email Not Verified'),
                  content: Text(
                    'Your email address ($userEmailForMessage) has not been verified. '
                    'This unverified registration will now be removed. '
                    'Please register again and complete the email verification step to access the app.',
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('OK'),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                  ],
                );
              },
            );
          }

          try {
            await user.delete();
            _logger.i('Unverified user ($userEmailForMessage) deleted successfully from Firebase Auth.');
          } catch (e) {
            _logger.e('Error deleting unverified user ($userEmailForMessage): $e. The user might have already been deleted or requires re-authentication for deletion.');
            // Even if deletion fails, ensure sign out
          }

          // Always sign out, as the user should not remain in a partially authenticated state
          await FirebaseAuth.instance.signOut();
          _logger.i('User signed out after unverified login attempt.');

          if (mounted) {
            // Optionally, show a SnackBar after dialog dismissal if needed,
            // but the dialog is usually sufficient.
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(
            //     content: Text('Previous registration for $userEmailForMessage cleared. Please register again.'),
            //     backgroundColor: Colors.orange,
            //   ),
            // );

            // Navigate back to Login or preferably Register screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const RegisterScreen()), // Or LoginScreen
            );
          }
        }
      } else {
        _logger.w("Sign in attempt resulted in a null user.");
        // Handle null user case, though typically signInWithEmailAndPassword throws if user is null
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Login failed. Please try again.'), backgroundColor: Colors.red),
            );
         }
      }
    } on FirebaseAuthException catch (e) {
      _logger.e("FirebaseAuthException during sign in: ${e.code} - ${e.message}");
      String errorMessage = 'An error occurred. Please try again.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = 'Invalid email or password.';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Too many login attempts. Please try again later.';
      }
      // ... handle other specific Firebase Auth errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      _logger.e("Generic error during sign in: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred. Please try again.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // This function is not used by _loginUser for navigation currently
  // void _navigateToHomeBasedOnRole(BuildContext context) {
  //   if (_isUserRole) {
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (context) => const HomeScreen()),
  //     );
  //   } else {
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F2),
      body: SafeArea(
        child: Stack(
          children: [
            // Background circles
            Positioned( // small orange circle
              top: 10,
              left: -50,
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6F3C), // deep orange
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned( // small white circle
              top: 0,
              left: -40,
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF5F2), // background color
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned( // large light orange circle
              top: -80,
              left: 0,
              child: Container(
                width: 180,
                height: 180,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFBFAE), // light orange
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned( // large orange circle
              top: -40,
              right: -80,
              child: Container(
                width: 160,
                height: 160,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6F3C), // deep orange
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Main content
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form( // Wrap content in a Form widget
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const SizedBox(height: 40),

                      // Back button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                          onPressed: () => _navigateToWelcome(context),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Login heading
                      const Text(
                        'Login',
                        style: TextStyle(
                          fontFamily: 'SofiaSans',
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Email field
                      const Text(
                        'E-mail',
                        style: TextStyle(
                          fontFamily: 'SofiaSans',
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField( // Changed to TextFormField
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Your email', // Updated hint
                          hintStyle: const TextStyle(
                            fontFamily: 'SofiaSans',
                            color: Colors.grey,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Password field
                      const Text(
                        'Password',
                        style: TextStyle(
                          fontFamily: 'SofiaSans',
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField( // Changed to TextFormField
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: const TextStyle(
                            fontFamily: 'SofiaSans',
                            color: Colors.grey,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters long';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: Implement forgot password functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Forgot password clicked (Not implemented yet)')),
                            );
                          },
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                              fontFamily: 'SofiaSans',
                              color: Color(0xFFFF7F59),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // User/Admin toggle - UI remains, logic does not use _isUserRole for login
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isUserRole = true;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isUserRole ? const Color(0xFFFF7F59) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    'User',
                                    style: TextStyle(
                                      fontFamily: 'SofiaSans',
                                      color: _isUserRole ? Colors.white : Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isUserRole = false;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !_isUserRole ? const Color(0xFFFF7F59) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    'Admin',
                                    style: TextStyle(
                                      fontFamily: 'SofiaSans',
                                      color: !_isUserRole ? Colors.white : Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signInWithEmailAndPassword, // Call _loginUser
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7F59),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'LOGIN',
                                  style: TextStyle(
                                    fontFamily: 'SofiaSans',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Sign up link
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Don\'t have an account?',
                              style: TextStyle(
                                fontFamily: 'SofiaSans',
                                color: Colors.grey,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontFamily: 'SofiaSans',
                                  color: Color(0xFFFF7F59),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _navigateToWelcome(BuildContext context) {
    Navigator.pushReplacement( // Use pushReplacement if coming from WelcomeScreen
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    );
  }
