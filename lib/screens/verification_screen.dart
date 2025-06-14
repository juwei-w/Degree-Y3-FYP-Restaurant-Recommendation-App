import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'select_preferences_screen.dart'; // Import the SelectPreferenceScreen

class VerificationScreen extends StatefulWidget {
  final String email;
  
  const VerificationScreen({
    super.key, 
    required this.email,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6, 
    (index) => TextEditingController(),
  );
  
  final List<FocusNode> _focusNodes = List.generate(
    6, 
    (index) => FocusNode(),
  );

  @override
  void initState() {
    super.initState();
        
    // Set focus to the third digit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNodes[0]);
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F2),
      body: SafeArea(
        child: Stack(
          children: [
            // Background circles (matching RegisterScreen)
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
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    
                    const SizedBox(height: 80),
                    
                    // Verification heading
                    const Text(
                      'Verification Code',
                      style: TextStyle(
                        fontFamily: 'SofiaSans',
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Verification instruction
                    Text(
                      'Please type the verification code sent to\n${widget.email}',
                      style: const TextStyle(
                        fontFamily: 'SofiaSans',
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Verification code input fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        6,
                        (index) => SizedBox(
                          width: 50,
                          height: 60,
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFFF7F59), width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFFFF7F59),
                                  width: 1,
                                ),
                              ),
                            ),
                            style: const TextStyle(
                              fontFamily: 'SofiaSans',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            onChanged: (value) {
                              if (value.length == 1 && index < 5) {
                                _focusNodes[index + 1].requestFocus();
                              }
                            },
                            onSubmitted: (_) {
                              if (index == 5) {
                                // When last field is submitted, trigger verify
                                String code = _controllers.map((c) => c.text).join();
                                if (code.length == 6) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SelectPreferencesScreen(),
                                    ),
                                  );
                                }
                              } else if (_controllers[index].text.isEmpty && index > 0) {
                                _focusNodes[index - 1].requestFocus();
                              }
                            },
                            onEditingComplete: () {},
                            onTap: () {
                              _controllers[index].selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: _controllers[index].text.length,
                              );
                            },
                            inputFormatters: [
                              TextInputFormatter.withFunction((oldValue, newValue) {
                                if (oldValue.text.isNotEmpty && newValue.text.isEmpty && index > 0) {
                                  _focusNodes[index - 1].requestFocus();
                                }
                                return newValue;
                              })
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Resend code
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'I don\'t receive a code!',
                            style: TextStyle(
                              fontFamily: 'SofiaSans',
                              color: Colors.grey,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Resend code logic
                            },
                            child: const Text(
                              'Please resend',
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
                    
                    const SizedBox(height: 80),
                    
                    // Verify button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          // Verification logic
                          String code = _controllers.map((c) => c.text).join();
                          if (code.length == 6) {
                            // Navigate to SelectPreferencesScreen after verification
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SelectPreferencesScreen(),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7F59),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'VERIFY',
                          style: TextStyle(
                            fontFamily: 'SofiaSans',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}