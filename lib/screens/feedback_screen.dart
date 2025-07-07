import 'package:flutter/material.dart';
import 'package:smart_food_v1/screens/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  double _rating = 0; // Add this for star rating

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback(String feedbackText) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Fetch user name from Firestore
    String? userName;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      userName = userDoc.data()?['name'] ?? '';
    }

    final feedbackData = {
      'user_id': user.uid,
      'user_name': userName ?? '',
      'feedback': feedbackText,
      'rating': _rating, // Save the rating
      'resolved': false,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Add a new document to the 'feedback' collection
    await FirebaseFirestore.instance.collection('feedback').add(feedbackData);
  }

  // Add this widget for star rating selection
  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return IconButton(
          icon: Icon(
            _rating >= starIndex ? Icons.star : Icons.star_border,
            color: Color(0xFFFF7F59),
            size: 32,
          ),
          onPressed: () {
            setState(() {
              _rating = starIndex.toDouble();
            });
          },
        );
      }),
    );
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
                  // Star rating widget
                  _buildStarRating(),
                  const SizedBox(height: 16),
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
                        onPressed: () async {
                          if (_feedbackController.text.trim().isNotEmpty) {
                            await _submitFeedback(_feedbackController.text.trim());
                            // Optionally show a success message or clear the input
                            _feedbackController.clear();
                            setState(() {
                              _rating = 0; // Reset the star rating after submitting
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Feedback submitted!'),
                                backgroundColor: Colors.orangeAccent,
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
