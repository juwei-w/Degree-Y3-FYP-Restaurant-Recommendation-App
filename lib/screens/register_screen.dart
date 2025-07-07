import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'verification_screen.dart'; // Will navigate here after sending Firebase verification email
// Removed: import 'dart:math'; // No longer needed for mock OTP

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // Removed: final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  // Removed: bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    // Removed: _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;
      String name = _nameController.text.trim();

      if (user != null) {
        // Send Firebase's built-in email verification
        if (!user.emailVerified) {
          await user.sendEmailVerification();
          // Optionally, show a quick SnackBar here, though the VerificationScreen will give more info
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Verification email sent. Please check your inbox.')),
            );
          }
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationScreen(
                user: user, // Pass the created User object
                name: name,   // Pass the entered name
                // Removed: expectedOtp: mockOtp, // No longer passing mock OTP
              ),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = 'An error occurred. Please try again.';
        if (e.code == 'weak-password') {
          errorMessage = 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'The account already exists for that email.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'The email address is not valid.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: ${e.toString()}'), backgroundColor: Colors.redAccent),
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

  @override
  Widget build(BuildContext context) {
    // Adhering to Figma Design Guidelines
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F2),
      body: SafeArea(
        child: Stack(
          children: [
            // Background circles (matching existing style from Figma/Register.png)
            Positioned(
              top: 10, left: -50,
              child: Container(width: 100, height: 100, decoration: const BoxDecoration(color: Color(0xFFFF6F3C), shape: BoxShape.circle)),
            ),
            Positioned(
              top: 0, left: -40,
              child: Container(width: 60, height: 60, decoration: const BoxDecoration(color: Color(0xFFFFF5F2), shape: BoxShape.circle)),
            ),
            Positioned(
              top: -80, left: 0,
              child: Container(width: 180, height: 180, decoration: const BoxDecoration(color: Color(0xFFFFBFAE), shape: BoxShape.circle)),
            ),
            Positioned(
              top: -40, right: -80,
              child: Container(width: 160, height: 160, decoration: const BoxDecoration(color: Color(0xFFFF6F3C), shape: BoxShape.circle)),
            ),
            // Main content
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0), // Consistent padding
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40), // Spacing from top
                      Container( // Back button styling from Figma
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(height: 40), // Spacing
                      const Text(
                        'Registration', // Title from Figma/Register.png
                        style: TextStyle(fontFamily: 'SofiaSans', fontSize: 40, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Create your account to get started.', // Subtitle from Figma/Register.png
                        style: TextStyle(fontFamily: 'SofiaSans', fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 30), // Spacing

                      // Full Name Field
                      const Text(
                        'Full name',
                        style: TextStyle(fontFamily: 'SofiaSans', fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Enter your full name', // Placeholder from Figma
                          hintStyle: const TextStyle(fontFamily: 'SofiaSans', color: Colors.grey), // Updated hint text color
                          filled: true,
                          fillColor: Colors.white, // Field background from Figma
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter your full name' : null,
                      ),
                      const SizedBox(height: 20),

                      // Email Field
                      const Text(
                        'E-mail',
                        style: TextStyle(fontFamily: 'SofiaSans', fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Enter your email address', // Placeholder from Figma
                          hintStyle: const TextStyle(fontFamily: 'SofiaSans', color: Colors.grey), // Updated hint text color
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter your email';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      const Text(
                        'Password',
                        style: TextStyle(fontFamily: 'SofiaSans', fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Enter your password', // Placeholder from Figma
                          hintStyle: const TextStyle(fontFamily: 'SofiaSans', color: Colors.grey), // Updated hint text color
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter a password';
                          if (value.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 30), // Spacing before button, was 20, then confirm password, then 30

                      // Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        height: 56, // Button height from Figma
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _registerUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7F59), // Button color from Figma
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // Button shape from Figma
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'SIGN UP', // Button text from Figma
                                  style: TextStyle(fontFamily: 'SofiaSans', fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Login Link
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Already have an account?', style: TextStyle(fontFamily: 'SofiaSans', color: Colors.grey)),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                );
                              },
                              child: const Text('Login', style: TextStyle(fontFamily: 'SofiaSans', color: Color(0xFFFF7F59), fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                       const SizedBox(height: 20), // Bottom padding
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
