import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:logger/logger.dart';

class AdminMakerScreen extends StatefulWidget {
  const AdminMakerScreen({super.key});

  @override
  State<AdminMakerScreen> createState() => _AdminMakerScreenState();
}

class _AdminMakerScreenState extends State<AdminMakerScreen> {
  final _loginEmailController =
      TextEditingController(text: 'payardmmu@gmail.com'); // Pre-filled
  final _loginPasswordController = TextEditingController(text: 'payard');
  final _targetEmailController = TextEditingController(text: 'payardmmu@gmail.com');
  bool _isLoading = false;
  String? _resultMessage;

  final _logger = Logger();

  Future<void> _loginAndMakeAdmin() async {
    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    try {
      // Login with provided credentials
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text,
      );

      // Validate target email
      if (_targetEmailController.text.trim().isEmpty) {
        setState(() {
          _resultMessage = 'Please enter the user email to make admin.';
        });
        return;
      }

      // Call the Cloud Function
      final callable = FirebaseFunctions.instance.httpsCallable('makeUserAdmin');
      _logger.i('Target email: "${_targetEmailController.text.trim()}"');
      final result = await callable.call({'email': _targetEmailController.text.trim()});
      setState(() {
        _resultMessage = result.data['message'] ?? 'Success!';
      });
    } on FirebaseFunctionsException catch (e) {
      setState(() {
        _resultMessage = 'Cloud Function error: ${e.message}';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _resultMessage = 'Auth error: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _resultMessage = 'Unknown error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _targetEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Figma style: SofiaSans, orange button, rounded corners, spacing
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Maker',
          style: TextStyle(fontFamily: 'SofiaSans'),
        ),
        backgroundColor: const Color(0xFFFF7F59),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  'Login as Admin',
                  style: TextStyle(
                    fontFamily: 'SofiaSans',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _loginEmailController,
                  decoration: InputDecoration(
                    labelText: 'Your Email',
                    hintText: 'Enter your admin email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'SofiaSans'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _loginPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Your Password',
                    hintText: 'Enter your password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: true,
                  style: const TextStyle(fontFamily: 'SofiaSans'),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _targetEmailController,
                  decoration: InputDecoration(
                    labelText: 'User Email to Make Admin',
                    hintText: 'Enter user email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'SofiaSans'),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator(color: Color(0xFFFF7F59))
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_targetEmailController.text.trim().isEmpty) {
                              setState(() {
                                _resultMessage = 'Please enter the user email to make admin.';
                              });
                              return;
                            }
                            await _loginAndMakeAdmin();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7F59),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Make Admin',
                            style: TextStyle(
                              fontFamily: 'SofiaSans',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                if (_resultMessage != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    _resultMessage!,
                    style: TextStyle(
                      fontFamily: 'SofiaSans',
                      color: _resultMessage!.toLowerCase().contains('success')
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}