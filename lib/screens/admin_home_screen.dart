import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'admin_feedback_management_screen.dart';
import 'admin_user_management_screen.dart';
import 'welcome_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  // Add admin info state
  String _adminName = 'Admin';
  String _adminEmail = 'admin@gmail.com';

  // Sample analytics data
  final Map<String, dynamic> analyticsData = {
    'recommendationAccuracy': 72.0,
    'newUsers': 1925,
    'userGrowth': 201,
    'newRestaurants': 153,
    'restaurantGrowth': 201,
    'totalOrders': 8547,
    'orderGrowth': 156,
    'revenue': 45230.50,
    'revenueGrowth': 12.5,
  };

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: analyticsData['recommendationAccuracy'] / 100,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    // Start animation after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _progressController.forward();
    });

    // Fetch admin info
    _fetchAdminInfo();
  }

  Future<void> _fetchAdminInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String name = 'Admin';
      String email = user.email ?? 'admin@gmail.com';

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          name = userData['name'] ?? user.displayName ?? 'Admin';
          email = userData['email'] ?? email;
        }
      } catch (_) {
        // fallback to defaults
      }
      if (mounted) {
        setState(() {
          _adminName = name;
          _adminEmail = email;
        });
      }
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: _buildAdminDrawer(),
      appBar: _buildAdminAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            
            // Recommendation Accuracy Card
            _buildRecommendationAccuracyCard(),
            const SizedBox(height: 20),
            
            // Analytics Grid
            _buildAnalyticsGrid(),
            const SizedBox(height: 20),
            
            // Recent Activity Section
            _buildRecentActivitySection(),
            const SizedBox(height: 80), // Space for bottom navigation
          ],
        ),
      ),
      bottomNavigationBar: _buildAdminBottomNavigation(),
    );
  }

  PreferredSizeWidget _buildAdminAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 80,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              // Menu button
              Builder(
                builder: (context) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ),
              ),
              
              // Admin Name (centered)
              Expanded(
                child: Text(
                  _adminName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              
              // Admin profile picture
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCC33),
                  borderRadius: BorderRadius.circular(15),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/profile.png'),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Admin profile section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Profile picture
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFCC33),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/profile.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Admin name and email (now dynamic)
                  // User name and email
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _adminName,
                        style: const TextStyle(
                          fontFamily: 'SofiaSans',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _adminEmail,
                        style: TextStyle(
                          fontFamily: 'SofiaSans',
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Admin menu items
            _buildAdminDrawerItem('assets/images/profile_icon.png', 'Manage User', () {
              _navigateToUserManagement(context);
              // Navigate to user management
            }),
            _buildAdminDrawerItem('assets/images/feedback_icon.png', 'Manage Feedback', () {
              _navigateToFeedbackManagement(context);
            }),
            _buildAdminDrawerItem('assets/images/analytics_icon.png', 'Analytics and Report', () {
              Navigator.pop(context);
              // Stay on current screen or refresh
            }),
            
            const Spacer(),
            
            // Logout button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _navigateToWelcome(context);
                  },
                  icon: const Icon(Icons.power_settings_new, color: Colors.white),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B47),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminDrawerItem(String assetPath, String title, VoidCallback onTap) {
    return ListTile(
      leading: Image.asset(
        assetPath,
        width: 28,
        height: 28,
        color: const Color(0xFFFF7F59),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'SofiaSans',
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  // Widget _buildAdminDrawerItem(IconData icon, String title, VoidCallback onTap) {
  //   return ListTile(
  //     leading: Icon(
  //       icon,
  //       color: const Color(0xFFFF6B47),
  //       size: 28,
  //     ),
  //     title: Text(
  //       title,
  //       style: const TextStyle(
  //         fontSize: 18,
  //         fontWeight: FontWeight.w500,
  //       ),
  //     ),
  //     onTap: onTap,
  //   );
  // }

  Widget _buildWelcomeSection() {
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else if (hour >= 17) {
      greeting = 'Good Evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $_adminName!',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Here\'s what\'s happening with your platform today',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationAccuracyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Circular progress indicator
              SizedBox(
                width: 100,
                height: 100,
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: CircularProgressPainter(
                        progress: _progressAnimation.value,
                        backgroundColor: Colors.grey[200]!,
                        progressColor: const Color(0xFFFF6B47),
                      ),
                      child: Center(
                        child: Text(
                          '${(analyticsData['recommendationAccuracy']).toInt()}%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6B47),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(width: 24),
              
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommendation Accuracy',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hybrid Model',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // See Full Review button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to full review
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B47),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: const Text(
                'See Full Review',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'New User',
                analyticsData['newUsers'].toString(),
                analyticsData['userGrowth'],
                Icons.person_add,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAnalyticsCard(
                'New Restaurant',
                analyticsData['newRestaurants'].toString(),
                analyticsData['restaurantGrowth'],
                Icons.restaurant,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'Total Orders',
                analyticsData['totalOrders'].toString(),
                analyticsData['orderGrowth'],
                Icons.shopping_bag,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAnalyticsCard(
                'Revenue',
                '\$${(analyticsData['revenue'] / 1000).toStringAsFixed(1)}K',
                analyticsData['revenueGrowth'],
                Icons.attach_money,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(String title, String value, dynamic growth, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Value and growth
          Row(
            // Removed MainAxisAlignment.spaceBetween to let Flexible/Expanded handle distribution
            children: [
              Expanded( // Allow the main value to take available space and wrap/ellipsis if needed
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis, // Handle overflow for the value
                  maxLines: 1,                     // Keep value on a single line
                ),
              ),
              const SizedBox(width: 8), // Add explicit spacing
              Row( // Keep the growth indicator compact
                mainAxisSize: MainAxisSize.min, // Don't let this Row expand unnecessarily
                children: [
                  Icon(
                    Icons.arrow_upward, // Assuming growth is positive
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Flexible( // Allow the growth text to shrink or use ellipsis
                    child: Text(
                      '+${growth is double ? growth.toStringAsFixed(1) : growth}${growth is double ? '%' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis, // Handle overflow for growth text
                      maxLines: 1,                     // Keep growth text on a single line
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildActivityItem(
                'New restaurant "Pizza Palace" registered',
                '2 minutes ago',
                Icons.restaurant,
                Colors.green,
              ),
              const Divider(),
              _buildActivityItem(
                'User feedback received from John Doe',
                '15 minutes ago',
                Icons.feedback,
                Colors.orange,
              ),
              const Divider(),
              _buildActivityItem(
                'System backup completed successfully',
                '1 hour ago',
                Icons.backup,
                Colors.blue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem('assets/images/feedback_icon.png', false, () {
                _navigateToFeedbackManagement(context);
              }),
              _buildNavItem('assets/images/analytics_icon.png', true, () {
                // Stay on current screen or refresh
              }),
              _buildNavItem('assets/images/profile_icon.png', false, () {
                _navigateToUserManagement(context);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(String assetPath, bool isSelected, VoidCallback onTap) {
    return IconButton(
      icon: Image.asset(
        assetPath,
        width: 28,
        height: 28,
        color: isSelected ? const Color(0xFFFF7F59) : Colors.grey,
      ),
      onPressed: onTap,
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

void _navigateToFeedbackManagement(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const AdminFeedbackManagementScreen()), // Corrected typo
  );
}

void _navigateToUserManagement(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const AdminUserManagementScreen()),
  );
}

  void _navigateToWelcome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (route) => false, // Remove all previous routes
    );
  }
