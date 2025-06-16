// filepath: lib/screens/verification_screen.dart
import 'dart:async'; // For Timer
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// Removed: import 'package:flutter/services.dart'; // No longer using OTP text fields
import 'select_preferences_screen.dart';
import 'login_screen.dart'; // For back navigation if user wants to cancel

class VerificationScreen extends StatefulWidget {
  final User user;
  final String name;

  const VerificationScreen({
    super.key,
    required this.user,
    required this.name,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isLoading = false;
  Timer? _timer; // Timer to periodically check email verification status

  @override
  void initState() {
    super.initState();
    // Start a timer to periodically check if the email has been verified
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkEmailVerified();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  Future<void> _checkEmailVerified({bool manualCheck = false}) async {
    if (mounted) {
      setState(() {
        if (manualCheck) _isLoading = true;
      });
    }

    await widget.user.reload(); // Refresh user data from Firebase
    final User? currentUser = FirebaseAuth.instance.currentUser; // Get the latest user status

    if (currentUser != null && currentUser.emailVerified) {
      _timer?.cancel(); // Stop the timer
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SelectPreferencesScreen(
              user: currentUser, // Pass the verified user
              name: widget.name,
            ),
          ),
        );
      }
    } else {
      if (manualCheck && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not verified yet. Please check your inbox and click the link.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    }
    if (mounted && manualCheck) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    try {
      await widget.user.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email resent. Please check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = "Could not resend verification email.";
        if (e.code == 'too-many-requests') {
          message = "Too many requests. Please try again later.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
        if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('An unexpected error occurred while resending email.'),
                    backgroundColor: Colors.redAccent,
                ),
            );
        }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Adhering to Figma Design Guidelines
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F2), // Consistent background
      body: SafeArea(
        child: Stack(
          children: [
            // Background decorative circles (consistent with other screens)
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
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Back button - navigates to LoginScreen if user wants to cancel/go back
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: () {
                        _timer?.cancel();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 60), // Spacing as per Figma
                  const Text(
                    'Verify Your Email', // Title updated
                    style: TextStyle(
                      fontFamily: 'SofiaSans',
                      fontSize: 32, // Match Figma
                      fontWeight: FontWeight.bold,
                      color: Colors.black87, // Match Figma
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'A verification link has been sent to your email address:\n${widget.user.email}\n\nPlease click the link to verify your account. This window will automatically update once verified.',
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontFamily: 'SofiaSans',
                      fontSize: 16, // Match Figma
                      color: Colors.grey, // Match Figma
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40), // Spacing
                  Center(
                    child: _isLoading && !_timer!.isActive // Show loading only on manual check
                        ? const CircularProgressIndicator(color: Color(0xFFFF7F59))
                        : const Icon(Icons.mark_email_read_outlined, size: 80, color: Color(0xFFFF7F59)), // Placeholder icon
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Didn't receive the email?", // Match Figma
                        style: TextStyle(fontFamily: 'SofiaSans', color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: _isLoading ? null : _resendVerificationEmail,
                        child: const Text(
                          'Resend Email', // Match Figma
                          style: TextStyle(
                            fontFamily: 'SofiaSans',
                            color: Color(0xFFFF7F59), // Match Figma
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(), // Pushes button to the bottom
                  SizedBox(
                    width: double.infinity,
                    height: 56, // Match Figma
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _checkEmailVerified(manualCheck: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7F59), // Match Figma
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // Match Figma
                        ),
                      ),
                      child: _isLoading && _timer!.isActive // Show "Checking..." if timer is active and button is pressed
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
                                SizedBox(width: 10),
                                Text('CHECKING STATUS...', style: TextStyle(fontFamily: 'SofiaSans', fontSize: 18, fontWeight: FontWeight.w600)),
                              ],
                            )
                          : const Text(
                              'REFRESH STATUS', // Button text updated
                              style: TextStyle(
                                fontFamily: 'SofiaSans',
                                fontSize: 18, // Match Figma
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20), // Bottom padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}