import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
  with WidgetsBindingObserver {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  String _initialName = '';
  String _initialEmail = '';

  bool _newEmailVerificationSent = false;
  String _emailForWhichVerificationWasSent = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      _loadUserData();
    }
  }

  Future<User?> _handleSessionExpiry({bool showMessages = true}) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null && mounted && showMessages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active user session found. Please log in.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    }
    return currentUser;
  }

  void _loadUserData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    User? refreshedUser = await _handleSessionExpiry(showMessages: false);
    String? currentAuthEmail =
        refreshedUser?.email ?? FirebaseAuth.instance.currentUser?.email;

    if (refreshedUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Session expired or token invalid. Please log in again.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    String loadedUserName = refreshedUser.displayName ?? "";
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(refreshedUser.uid)
          .get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        loadedUserName = userData['name'] ?? "";
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _fullNameController.text = loadedUserName;
        _emailController.text = currentAuthEmail ?? "";
        _passwordController.clear();
        _initialName = loadedUserName;
        _initialEmail = currentAuthEmail ?? "";
        _isLoading = false;
      });
    }
  }

  Future<void> _sendVerificationToNewEmail() async {
    if (!mounted) return;
    final newEmailCandidate = _emailController.text.trim();
    final String currentActualAuthEmail =
        FirebaseAuth.instance.currentUser?.email ?? _initialEmail;

    if (newEmailCandidate.isEmpty ||
        newEmailCandidate == currentActualAuthEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please enter a new email address different from your current one.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }
    bool isValidEmail = RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(newEmailCandidate);
    if (!isValidEmail) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a valid email address.'),
        backgroundColor: Colors.orangeAccent,
      ));
      return;
    }

    setState(() {
      _isLoading = true;
    });
    User? currentUser = await _handleSessionExpiry();

    if (currentUser == null) {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
      return;
    }

    if (currentUser.email == newEmailCandidate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This is already your verified email address.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        setState(() {
          _newEmailVerificationSent = false;
          _emailForWhichVerificationWasSent = "";
          _initialEmail = currentUser.email!;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      await currentUser.verifyBeforeUpdateEmail(newEmailCandidate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'We\'ve sent a verification email to $newEmailCandidate. After verifying, press Update to complete the email change.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        setState(() {
          _newEmailVerificationSent = true;
          _emailForWhichVerificationWasSent = newEmailCandidate;
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = "Failed to send verification: ${e.message}";
        if (e.code == 'requires-recent-login') {
          message =
              "This operation requires you to log in again for security reasons.";
        } else if (e.code == 'email-already-in-use') {
          message = "This email address is already in use by another account.";
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: Colors.orangeAccent,
        ));
        if (e.code == 'requires-recent-login') {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
          return;
        }
      }
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  Future<void> _updateUserData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });

    User? currentUser = FirebaseAuth.instance.currentUser;

    final String newEmail = _emailController.text.trim();

    // If user entered a new email but did not request verification
    if (newEmail.isNotEmpty &&
        newEmail != _initialEmail &&
        (!_newEmailVerificationSent || newEmail != _emailForWhichVerificationWasSent)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile not updated. Please verify your email to proceed with the change.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        // Reset the email text field to the current user's email
        _emailController.text = _initialEmail;
        setState(() { _isLoading = false; });
      }
      return;
    }

    // Handle email update (only after verification)
    if (_newEmailVerificationSent &&
        _emailController.text.trim() == _emailForWhichVerificationWasSent) {
      // Try to reload, but catch the token-expired error
      try {
        await currentUser?.reload();
        currentUser = FirebaseAuth.instance.currentUser;
        final refreshedEmail = currentUser?.email ?? "";

        if (refreshedEmail == _emailForWhichVerificationWasSent) {
          // Update Firestore profile email
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser!.uid)
                .update({'email': refreshedEmail});
          } catch (_) {}
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Email successfully updated to $refreshedEmail. Please log in again.'),
                backgroundColor: Colors.orangeAccent,
              ),
            );
          }
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
          return;
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-token-expired' ||
            e.code == 'user-disabled' ||
            e.code == 'user-not-found') {
          // Assume email update succeeded, show message and redirect to login
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Email successfully updated. Please log in again.'),
                backgroundColor: Colors.orangeAccent,
              ),
            );
          }
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
          return;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${e.message}'),
                backgroundColor: Colors.orangeAccent,
              ),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }
    }

    // --- Name Update ---
    final String newFullName = _fullNameController.text.trim();
    if (newFullName.isNotEmpty && newFullName != _initialName) {
      try {
        await currentUser?.updateProfile(displayName: newFullName);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .update({'name': newFullName});
        setState(() {
          _initialName = newFullName;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Name updated.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating name: $e'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    }

    // --- Password Update ---
    final String newPassword = _passwordController.text.trim();
    if (newPassword.isNotEmpty) {
      try {
        await currentUser?.updatePassword(newPassword);
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in again to update your password.'),
              backgroundColor: Colors.orangeAccent,
            ),
          );
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
          return;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating password: ${e.message}'),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
      }
    }

    setState(() {
      _isLoading = false;
    });
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    String verifyButtonText = 'Verify';
    bool verifyButtonEnabled = true;
    Color verifyButtonColor = Theme.of(context).primaryColor; // Default color
    Color verifyButtonBackgroundColor =
        Theme.of(context).primaryColor.withOpacity(0.1); // Default background

    final String emailInTextField = _emailController.text.trim();
    final String currentActualAuthEmail =
        FirebaseAuth.instance.currentUser?.email ?? _initialEmail;

    bool showVerifyButton = false;

    if (emailInTextField.isNotEmpty &&
        emailInTextField == currentActualAuthEmail) {
      showVerifyButton = true;
      verifyButtonText = 'Verified';
      verifyButtonEnabled = false;
      verifyButtonColor = Colors.green;
      verifyButtonBackgroundColor = Colors.green.withOpacity(0.1);
    } else if (emailInTextField.isNotEmpty &&
        emailInTextField != currentActualAuthEmail) {
      showVerifyButton = true;
      if (_newEmailVerificationSent &&
          emailInTextField == _emailForWhichVerificationWasSent) {
        verifyButtonText = 'Sent';
        verifyButtonEnabled = false;
        verifyButtonColor = Colors.grey[700]!;
        verifyButtonBackgroundColor = Colors.grey[300]!;
      } else {
        verifyButtonText = 'Verify';
        verifyButtonEnabled = true;
        // Use default colors assigned at the start of build method
        verifyButtonColor =
            const Color(0xFFFF7F59); // Matching figma button color
        verifyButtonBackgroundColor = const Color(0xFFFF7F59).withOpacity(0.1);
      }
    } else {
      if (emailInTextField.isEmpty) {
        showVerifyButton = false;
      }
    }

    if (_isLoading) verifyButtonEnabled = false;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F2),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFCC33),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: -40,
              right: -80,
              child: Container(
                width: 160,
                height: 160,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6F3C),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  Row(
                    children: [
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
                          icon: const Icon(Icons.arrow_back_ios_new,
                              size: 20, color: Colors.black),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        "Profile",
                        style: TextStyle(
                          fontFamily: 'SofiaSans',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      Container(width: 48),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFCC33),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/profile.png'),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Color(0xFFFF7F59),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    // Use _fullNameController.text if _initialName is empty on first load but controller has data
                    _initialName.isNotEmpty ? _initialName : 'User Name',
                    style: const TextStyle(
                      fontFamily: 'SofiaSans',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Full name',
                        style: TextStyle(
                          fontFamily: 'SofiaSans',
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[100],
                        ),
                        child: TextField(
                          controller: _fullNameController,
                          style: const TextStyle(
                            fontFamily: 'SofiaSans',
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            // To update the displayed name above dynamically
                            if (mounted) setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'E-mail',
                        style: TextStyle(
                          fontFamily: 'SofiaSans',
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[100],
                              ),
                              child: TextField(
                                controller: _emailController,
                                style: const TextStyle(
                                  fontFamily: 'SofiaSans',
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                  border: InputBorder.none,
                                ),
                                keyboardType: TextInputType.emailAddress,
                                onChanged: (value) {
                                  if (mounted) {
                                    setState(() {
                                      final text = value.trim();
                                      if (text !=
                                          _emailForWhichVerificationWasSent) {
                                        _newEmailVerificationSent = false;
                                      }
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          if (showVerifyButton)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: TextButton(
                                onPressed: verifyButtonEnabled
                                    ? _sendVerificationToNewEmail
                                    : null,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  backgroundColor: verifyButtonBackgroundColor,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(
                                  verifyButtonText,
                                  style: TextStyle(
                                    fontFamily: 'SofiaSans',
                                    fontSize: 14,
                                    color: verifyButtonColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password',
                        style: TextStyle(
                          fontFamily: 'SofiaSans',
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[100],
                        ),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: const TextStyle(
                            fontFamily: 'SofiaSans',
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: "Enter new password (optional)",
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            border: InputBorder.none,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey[500],
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateUserData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7F59),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ))
                            : const Text(
                                'Update',
                                style: TextStyle(
                                  fontFamily: 'SofiaSans',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
