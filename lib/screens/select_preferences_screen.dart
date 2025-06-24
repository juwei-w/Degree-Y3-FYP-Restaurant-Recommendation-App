import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart'; // Import the logger package
import 'select_restrictions_screen.dart';

// Initialize logger for this screen
final _logger = Logger();

class SelectPreferencesScreen extends StatefulWidget {
  final User user;
  final String name;

  const SelectPreferencesScreen({
    super.key,
    required this.user,
    required this.name,
  });

  @override
  State<SelectPreferencesScreen> createState() => _SelectPreferencesScreenState();
}

class _SelectPreferencesScreenState extends State<SelectPreferencesScreen> {
  // ... your existing state variables ...
  final List<String> _allPreferences = [
    'chinese', 'indian', 'malay', 'korean', 
    'japanese', 'thai', 'western', 'eastern'
  ];
  final Set<String> _selectedPreferences = {};
  bool _isLoading = false;


  void _togglePreferenceSelection(String preference) {
    setState(() {
      if (_selectedPreferences.contains(preference)) {
        _selectedPreferences.remove(preference);
      } else {
        _selectedPreferences.add(preference);
      }
    });
  }

  void _navigateToRestrictionsScreen() {
    _logger.i("_navigateToRestrictionsScreen called");

    if (_selectedPreferences.isEmpty) {
      _logger.w("No preferences selected. Showing SnackBar.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one preference.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    _logger.i("Preferences selected: ${_selectedPreferences.join(', ')}");
    setState(() {
      _isLoading = true;
      _logger.d("_isLoading set to true");
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      _logger.d("Future.delayed callback started");
      if (mounted) {
        _logger.d("Widget is mounted in Future.delayed");
        setState(() {
          _isLoading = false;
          _logger.d("_isLoading set to false");
        });
        _logger.i("Attempting to navigate to FoodRestrictionsScreen");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              _logger.d("Building FoodRestrictionsScreen. User: ${widget.user.uid}, Name: ${widget.name}, Prefs: ${_selectedPreferences.length}");
              return FoodRestrictionsScreen(
                user: widget.user,
                name: widget.name,
                selectedPreferences: _selectedPreferences.toList(),
              );
            },
          ),
        ).then((_) {
            _logger.i("Navigation to FoodRestrictionsScreen completed (or popped)");
        }).catchError((error, stackTrace) { // It's good practice to log the stack trace too
            _logger.e("Error during navigation or FoodRestrictionsScreen build", error: error, stackTrace: stackTrace);
            if (mounted) {
              setState(() { _isLoading = false; }); // Reset loading on error
            }
        });
      } else {
        _logger.w("Widget is not mounted in Future.delayed callback");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    //
    // >>> IMPORTANT: YOUR EXISTING UI CODE FOR THE BUILD METHOD GOES HERE <<>
    // >>> DO NOT CHANGE YOUR EXISTING UI IMPLEMENTATION BELOW THIS LINE <<>
    //
    // For example, it should look something like this, but use YOUR actual code:
    //
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
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Food\nPreferences',
                    style: TextStyle(
                      fontFamily: 'SofiaSans',
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select your favorite cuisines. This will help us recommend the best restaurants for you.',
                    style: TextStyle(
                      fontFamily: 'SofiaSans',
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _allPreferences.length,
                      itemBuilder: (context, index) {
                        final preference = _allPreferences[index];
                        final isSelected = _selectedPreferences.contains(preference);
                        return GestureDetector(
                          onTap: () => _togglePreferenceSelection(preference),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFF7F59) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFFF7F59) : Colors.grey.shade300,
                                width: 1,
                              ),
                              boxShadow: [
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
                                preference.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'SofiaSans',
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _navigateToRestrictionsScreen,
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
                              'NEXT',
                              style: TextStyle(
                                fontFamily: 'SofiaSans',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}