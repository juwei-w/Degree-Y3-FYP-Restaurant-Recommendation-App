import 'package:flutter/material.dart';
import 'package:smart_food_v1/screens/home_screen.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Row for back button and centered title
                  Row(
                    children: [
                      // Back button with shadow and rounded background
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const Spacer(),
                      // Centered title
                      const Text(
                        'Feedback',
                        style: TextStyle(
                          fontFamily: 'SofiaSans',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      // Empty container to balance the row
                      Container(width: 48),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Heading
                  const Text(
                    'FoodieFy we value\nyour opinion',
                    style: TextStyle(
                      fontFamily: 'SofiaSans',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF7F59),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Subtitle
                  Text(
                    'Kindly take a moment to tell us what you think.',
                    style: TextStyle(
                      fontFamily: 'SofiaSans',
                      fontSize: 18,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Feedback text field
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFF7F59),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _feedbackController,
                      maxLines: 10,
                      decoration: const InputDecoration(
                        hintText: 'Write a review',
                        hintStyle: TextStyle(
                          fontFamily: 'SofiaSans',
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        contentPadding: EdgeInsets.all(16),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Submit button
                  Center(
                    child: SizedBox(
                      width: 250,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_feedbackController.text.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Thank you for your feedback!'),
                                backgroundColor: Color(0xFFFF7F59),
                              ),
                            );
                            _navigateToHome(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please write your feedback before submitting.'),
                                backgroundColor: Colors.red,
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
                          'Submit',
                          style: TextStyle(
                            fontFamily: 'SofiaSans',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class YourFeedbackFormWidget extends StatelessWidget {
  const YourFeedbackFormWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Add your feedback form fields here
            TextField(
              decoration: InputDecoration(
                labelText: 'Your Feedback',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _navigateToHome(context), 
              child: Text('Submit Feedback'),
            ),
          ],
        ),
      ),
    );
  }
}

void _navigateToHome(BuildContext context) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const HomeScreen()),
  );
}
