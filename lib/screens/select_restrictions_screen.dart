import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:smart_food_v1/screens/home_screen.dart';

final _logger = Logger();

class FoodRestrictionsScreen extends StatefulWidget {
  final User user;
  final String name;
  final List<String> selectedPreferences;

  const FoodRestrictionsScreen({
    super.key,
    required this.user,
    required this.name,
    required this.selectedPreferences,
  });

  @override
  State<FoodRestrictionsScreen> createState() => _FoodRestrictionsScreenState();
}

class _FoodRestrictionsScreenState extends State<FoodRestrictionsScreen> {
  final List<String> _allRestrictions = [
    'halal', 'vegetarian', 'vegan', 'beef-free'
  ];
  final Set<String> _selectedRestrictions = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _logger.i("FoodRestrictionsScreen: initState CALLED. User: ${widget.user.uid}, Name: ${widget.name}, Prefs: ${widget.selectedPreferences}");
  }

  void _toggleRestrictionSelection(String restriction) {
    setState(() {
      if (_selectedRestrictions.contains(restriction)) {
        _selectedRestrictions.remove(restriction);
        _logger.d("Removed restriction: $restriction. Selected: $_selectedRestrictions");
      } else {
        _selectedRestrictions.add(restriction);
        _logger.d("Added restriction: $restriction. Selected: $_selectedRestrictions");
      }
    });
  }

  Future<void> _saveUserDataAndProceed() async {
    _logger.i("Attempting to save user data and proceed.");
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _logger.d("Saving data for User: ${widget.user.uid}, Name: ${widget.name}, Email: ${widget.user.email}, Prefs: ${widget.selectedPreferences}, Restrictions: ${_selectedRestrictions.toList()}");
      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set({
        'uid': widget.user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'isAdmin': false,
        'name': widget.name,
        'email': widget.user.email,
        'preferences': widget.selectedPreferences,
        'restrictions': _selectedRestrictions.toList(),
        'address': [], // list of saved locations
        'favourites': [], // list of favourite restaurant IDs or objects
      });
      _logger.i("User data saved successfully for UID: ${widget.user.uid}.");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Registration successful! Welcome to FoodieFy!',
              style: TextStyle(
                fontFamily: 'SofiaSans', // Consistent with Figma guidelines
                color: Colors.white, // Text color for good contrast on SnackBar
              ),
            ),
            backgroundColor: const Color(0xFFFF7F59), // Primary app color or a success green
            behavior: SnackBarBehavior.floating, // Or SnackBarBehavior.fixed
            margin: const EdgeInsets.all(10), // Optional, if floating
            shape: RoundedRectangleBorder( // Consistent with button/card shapes
              borderRadius: BorderRadius.circular(12), // Match Figma border radius for elements
            ),
            duration: const Duration(seconds: 4), // How long the SnackBar is visible
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e, s) {
      _logger.e("Failed to save user data", error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save data: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
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
    _logger.i("FoodRestrictionsScreen: build CALLED. User: ${widget.user.uid}, Name: ${widget.name}");

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F2), // Consistent app background
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
                  const SizedBox(height: 40), // Top spacing
                  // Back Button (Styled as per Figma if available, or consistent app style)
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                          )
                        ]),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Title Text (Matching Figma)
                  const Text(
                    'Food\nRestrictions',
                    style: TextStyle(
                      fontFamily: 'SofiaSans', // Ensure this font is in pubspec.yaml and assets
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle Text (Matching Figma)
                  const Text(
                    'Select any dietary restrictions you have. This will help us filter recommendations.',
                    style: TextStyle(
                      fontFamily: 'SofiaSans',
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // GridView for Restrictions
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Number of columns
                        childAspectRatio: 2.5, // Adjust for item shape (width / height)
                        crossAxisSpacing: 16, // Spacing between items horizontally
                        mainAxisSpacing: 16, // Spacing between items vertically
                      ),
                      itemCount: _allRestrictions.length,
                      itemBuilder: (context, index) {
                        final restriction = _allRestrictions[index];
                        final isSelected = _selectedRestrictions.contains(restriction);

                        return GestureDetector(
                          onTap: () => _toggleRestrictionSelection(restriction),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFF7F59) : Colors.white, // Selected/Deselected color from Figma
                              borderRadius: BorderRadius.circular(16), // Corner radius from Figma
                              border: Border.all(
                                color: isSelected ? const Color(0xFFFF7F59) : Colors.grey.shade300, // Border color
                                width: 1,
                              ),
                              boxShadow: [ // Subtle shadow as per modern UI, adjust to Figma
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                restriction.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'SofiaSans', // Ensure this font is in pubspec.yaml and assets
                                  fontSize: 16, // Font size from Figma
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, // Font weight
                                  color: isSelected ? Colors.white : Colors.black87, // Text color
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // DONE Button (Styled as per Figma)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveUserDataAndProceed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7F59), // Button color from Figma
                        foregroundColor: Colors.white, // Text color on button
                        elevation: 0, // No shadow if flat design, or match Figma
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // Button corner radius from Figma
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : const Text(
                              'DONE',
                              style: TextStyle(
                                fontFamily: 'SofiaSans',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20), // Bottom spacing
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}