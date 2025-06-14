import 'package:flutter/material.dart';
import 'package:smart_food_v1/screens/login_screen.dart'; // For logout navigation
// Import your new screens
// import 'welcome_screen.dart';
import 'admin_feedback_management_screen.dart';
import 'admin_user_management_screen.dart';

// Removed main() and AdminApp as this screen will be navigated to from login_screen

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedDrawerIndex = 2; // Default to 'Analytics and Report'
  int _currentBottomNavIndex = 1; // Default to 'Analytics' for bottom nav
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _getSelectedScreen() {
    const double bottomNavHeight = 60.0; // Adjusted to better match no-label height
    Widget screen;
    switch (_selectedDrawerIndex) {
      case 0: // Corresponds to 'Manage User' / Profile Icon
        screen = const AdminUserManagementScreen();
        break;
      case 1: // Corresponds to 'Manage Feedback' / Feedback Icon
        screen = const AdminFeedbackManagementScreen();
        break;
      case 2: // Corresponds to 'Analytics and Report' / Analytics Icon
      default:
        screen = _buildAnalyticsAndReportBody();
        break;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: bottomNavHeight),
      child: screen,
    );
  }

  void _onDrawerItemTapped(int index) {
    setState(() {
      _selectedDrawerIndex = index;
      if (index == 0) { // Manage User
        _currentBottomNavIndex = 2; // Profile icon
      } else if (index == 1) { // Manage Feedback
        _currentBottomNavIndex = 0; // Feedback icon
      } else if (index == 2) { // Analytics and Report
        _currentBottomNavIndex = 1; // Analytics icon
      }
    });
    Navigator.pop(context); // Close the drawer
  }

  void _onBottomNavItemTapped(int index) {
    setState(() {
      _currentBottomNavIndex = index;
      // If we are pushing new routes, _selectedDrawerIndex might not need to change
      // unless you want the drawer to also reflect this state upon reopening.
      // For simplicity, we'll keep the drawer index logic for now.
    });

    if (index == 0) { // Feedback Icon
      _navigateToFeedbackManagement(context);
      // Optionally, also set the drawer index if you want them to be in sync
      // setState(() { _selectedDrawerIndex = 1; });
    } else if (index == 1) { // Analytics Icon
      // For analytics, we change the body content of AdminHomeScreen
      setState(() {
        _selectedDrawerIndex = 2; // Corresponds to 'Analytics and Report' in drawer
      });
    } else if (index == 2) { // Profile Icon
      _navigateToUserManagement(context);
      // Optionally, also set the drawer index
      // setState(() { _selectedDrawerIndex = 0; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: _buildAdminAppBar(),
      drawer: _buildAdminDrawer(),
      body: Stack( // Use Stack to overlay the custom bottom navigation
        children: [
          _getSelectedScreen(), // Main content
          _buildAdminBottomNavigation(), // Custom bottom navigation bar
        ],
      ),
    );
  }

  Widget _buildAdminBottomNavigation() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 60, // Define a fixed height for the bar
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, -1), 
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0), // Vertical padding handled by item alignment
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center, // Center items vertically
            children: [
              _buildAdminNavItem(
                assetPath: 'assets/images/feedback_icon.png',
                itemIndex: 0,
              ),
              _buildAdminNavItem(
                assetPath: 'assets/images/analytics_icon.png',
                itemIndex: 1,
              ),
              _buildAdminNavItem(
                assetPath: 'assets/images/profile_icon.png',
                itemIndex: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminNavItem({
    required String assetPath,
    required int itemIndex,
  }) {
    bool isSelected = _currentBottomNavIndex == itemIndex;
    return Expanded(
      child: InkWell(
        onTap: () => _onBottomNavItemTapped(itemIndex),
        borderRadius: BorderRadius.circular(8.0),
        child: Container( // Use a container to help with centering
          alignment: Alignment.center, // Center the icon
          child: Image.asset(
            assetPath,
            width: 28, 
            height: 28,
            color: isSelected ? const Color(0xFFFF7F59) : Colors.grey[600], 
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAdminAppBar() {
    return AppBar(
      backgroundColor: Colors.white, // Match home_screen
      elevation: 0, // Match home_screen
      automaticallyImplyLeading: false, // We'll use our custom menu button
      toolbarHeight: 80, // Match home_screen
      titleSpacing: 0,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              // Menu button
              Container(
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
                  icon: const Icon(Icons.menu, color: Colors.black),
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer(); // Use the key to open drawer
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Title (Admin Dashboard)
              const Expanded(
                child: Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    fontFamily: 'SofiaSans',
                    fontSize: 20, // Adjusted for admin context
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              // Admin profile picture/icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCC33), // Example color
                  borderRadius: BorderRadius.circular(15),
                  // Replace with admin-specific image or keep placeholder
                  image: const DecorationImage(
                    image: AssetImage('assets/images/profile.png'), // Placeholder
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
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFCC33), // Example color
                      image: const DecorationImage(
                        image: AssetImage('assets/images/profile.png'), // Placeholder
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin User', // Replace with actual admin name
                            style: TextStyle(
                              fontFamily: 'SofiaSans',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'admin@example.com', // Replace with actual admin email
                            style: TextStyle(
                              fontFamily: 'SofiaSans',
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Admin Menu items
            _buildDrawerItem(
                'assets/images/profile_icon.png', // Using profile_icon for Manage User
                'Manage User',
                0,
                _onDrawerItemTapped),
            _buildDrawerItem(
                'assets/images/feedback_icon.png',
                'Manage Feedback',
                1,
                _onDrawerItemTapped),
            _buildDrawerItem(
                'assets/images/analytics_icon.png',
                'Analytics and Report',
                2,
                _onDrawerItemTapped),

            const Spacer(),

            // Logout button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()), // Navigate to LoginScreen
                      (route) => false, // Remove all previous routes
                    );
                  },
                  icon: const Icon(Icons.power_settings_new, color: Colors.white),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(
                      fontFamily: 'SofiaSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7F59),
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

  Widget _buildDrawerItem(
      String imagePath, String title, int index, Function(int) onTap) { // Changed IconData to String imagePath
    bool isSelected = _selectedDrawerIndex == index;
    return ListTile(
      leading: Image.asset( // Use Image.asset
        imagePath,
        width: 28,
        height: 28,
        color: isSelected
            ? const Color(0xFFFF7F59)
            : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'SofiaSans',
          fontSize: 18,
          fontWeight: isSelected
              ? FontWeight.bold
              : FontWeight.w500,
          color: isSelected
              ? const Color(0xFFFF7F59)
              : Colors.black,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFFFF7F59).withOpacity(0.1),
      onTap: () => onTap(index),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      horizontalTitleGap: 10,
    );
  }

  Widget _buildAnalyticsAndReportBody() {
    return SingleChildScrollView(
      // Removed padding from here, it's handled by _getSelectedScreen wrapper
      child: Padding( // Added padding back here for content within the scroll view
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Recommendation Accuracy Card
            Card(
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: <Widget>[
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: 0.72, // 72%
                            strokeWidth: 8,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF7F59)),
                          ),
                        ),
                        const Text(
                          '72%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Recommendation Accuracy',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Hybrid Model',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                print('See Full Review Tapped');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF7F59),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('See Full Review'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // New User Card
            Card(
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7F59).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.person_add_alt_1,
                          color: const Color(0xFFFF7F59).withOpacity(0.8), size: 30),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'New User',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Row(
                            children: <Widget>[
                              Text(
                                '1,925',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_upward,
                                  color: Colors.green, size: 20),
                              Text(
                                '+ 201',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // New Restaurant Card
            Card(
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.storefront,
                          color: Colors.green[700], size: 30),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'New Restaurant',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Row(
                            children: <Widget>[
                              Text(
                                '153',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_upward,
                                  color: Colors.green, size: 20),
                              Text(
                                '+ 15', // Example dynamic value
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
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
} // This closing brace should be for the _AdminHomeScreenState class

// These methods should be part of the _AdminHomeScreenState class
// Move them inside the class if they are not already.
// For this example, I am assuming they are correctly placed within the class.

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
