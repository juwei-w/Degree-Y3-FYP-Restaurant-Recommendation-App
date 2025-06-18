import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'feedback_screen.dart';
import 'favourites_screen.dart';
import 'profile_screen.dart';
import 'welcome_screen.dart';
import 'recommend_screen.dart';
import 'view_restaurant_screen.dart';

final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final DraggableScrollableController _dragController = DraggableScrollableController();
  double _dragPosition = 0.5; // Half screen initially
  
  List<Map<String, dynamic>> restaurants = [];

  bool _showAddressDropdown = false;
  final List<String> _addresses = [
    '4102 Pretty View Lane',
    '123 Main Street',
    '88 Jalan Bestari',
    'No. 5, Jalan Mawar',
  ];
  String _selectedAddress = '4102 Pretty View Lane';

  // Add this to your _HomeScreenState:
  Set<String> favouriteRestaurantIds = {}; // Use a unique field, e.g., name or place_id

  @override
  void initState() {
    super.initState();
    _dragController.addListener(() {
      setState(() {
        _dragPosition = _dragController.size;
      });
    });
    _loadRestaurantData();
  }

  Future<void> _loadRestaurantData() async {
    final String jsonString = await rootBundle.loadString('assets/restaurant_data/django_data_2.json');
    final List<dynamic> jsonData = json.decode(jsonString);
    setState(() {
      restaurants = jsonData
        .where((item) => item is Map<String, dynamic> && item['name'] != null)
        .map<Map<String, dynamic>>((item) => item as Map<String, dynamic>)
        .toList();
    });
  }

  @override
  void dispose() {
    _dragController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // App drawer (side menu)
      drawer: _buildDrawer(),
      // Proper app bar
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Map
          _buildMapImage(),
          
          // Draggable restaurant list
          _buildDraggableRestaurantList(),
          
          // Bottom navigation
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 80,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
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
                  // Location dropdown (centered)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _showAddressSelector,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Location',
                                        style: TextStyle(
                                          fontFamily: 'SofiaSans',
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded, // visually thicker
                                        color: Colors.grey,
                                        size: 17,
                                        // fontWeight: FontWeight.bold,
                                      ),
                                    ],
                                  ),
                                  Text(
                                    _selectedAddress,
                                    style: const TextStyle(
                                      fontFamily: 'SofiaSans',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFF7F59),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Profile picture
                  GestureDetector( // Wrap with GestureDetector
                    onTap: () {
                      _navigateToProfile(context); // Navigate to ProfileScreen
                    },
                    child: Container(
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
                  ),
                ],
              ),
              // Dropdown menu (floating, not constrained by AppBar)
              if (_showAddressDropdown)
                Positioned(
                  top: 60, // Position below the address row
                  left: 70, // Adjust to align with address (tweak as needed)
                  right: 70, // Adjust to align with address (tweak as needed)
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: _addresses.map((address) {
                          final bool isSelected = address == _selectedAddress;
                          return Material(
                            color: isSelected
                                ? const Color(0xFFFFF5F2)
                                : Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                setState(() {
                                  _selectedAddress = address;
                                  _showAddressDropdown = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFFFF5F2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        address,
                                        style: TextStyle(
                                          fontFamily: 'SofiaSans',
                                          fontSize: 14,
                                          color: isSelected
                                              ? const Color(0xFFFF7F59)
                                              : Colors.black87,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check,
                                        color: Color(0xFFFF7F59),
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // User profile section
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
                  
                  // User name and email
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Text('User Name');
                      }
                      final userData = snapshot.data!.data() as Map<String, dynamic>;
                      final userName = userData['name'] ?? 'User Name';
                      final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'user@email.com';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontFamily: 'SofiaSans',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            userEmail,
                            style: TextStyle(
                              fontFamily: 'SofiaSans',
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Menu items
            _buildDrawerItem('assets/images/home_icon.png', 'Home', () {
              Navigator.pop(context); // Closes the drawer and returns to home
              _navigateToHome(context); // Navigate to home
            }),
            _buildDrawerItem('assets/images/profile_icon.png', 'Profile', () {
              Navigator.pop(context); // Close drawer first
              _navigateToProfile(context); // Then navigate to profile
            }),
            _buildDrawerItem('assets/images/favourite_icon.png', 'Favourites', () {
              Navigator.pop(context);
              _navigateToFavourite(context);
            }),
            _buildDrawerItem('assets/images/recommend_icon.png', 'Recommend', () {
              Navigator.pop(context); 
              _navigateToRecommend(context);
            }),
            _buildDrawerItem('assets/images/feedback_icon.png', 'Feedback', () {
              Navigator.pop(context);
              _navigateToFeedback(context);
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

  Widget _buildDrawerItem(String assetPath, String title, VoidCallback onTap) {
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

  Widget _buildMapImage() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Image.asset(
        'assets/images/map.png',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildDraggableRestaurantList() {
    final double minSize = 0.22; // Adjusted to keep search bar visible
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        setState(() {
          _dragPosition = notification.extent;
        });
        return true;
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: minSize,
        maxChildSize: 1.0,
        controller: _dragController,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Drag handle - ONLY this should be draggable
                GestureDetector(
                  behavior: HitTestBehavior.translucent, // Makes the whole area tappable/draggable
                  onVerticalDragUpdate: (details) {
                    double newPosition = _dragPosition - details.delta.dy / MediaQuery.of(context).size.height;
                    newPosition = newPosition.clamp(minSize, 1.0);
                    _dragController.jumpTo(newPosition);
                  },
                  onTap: () {
                    final current = _dragController.size;
                    final target = (current < 0.95) ? 1.0 : minSize;
                    _dragController.animateTo(
                      target,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 20, // Increase the height for a larger tap/drag area
                    alignment: Alignment.center,
                    child: Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 4),
                      width: 80,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                // Search bar (moved outside scrollable area, always visible)
                Padding(
                  padding: EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 4.0,
                    bottom: 8.0, // fixed bottom padding
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Icon(Icons.search, color: Colors.grey),
                        ),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Find for food or restaurant...',
                              hintStyle: TextStyle(
                                fontFamily: 'SofiaSans',
                                color: Colors.grey,
                              ),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none, // Remove orange border when active
                              enabledBorder: InputBorder.none, // Remove border when enabled
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(8.0),
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF7F59).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.tune,
                            color: Color(0xFFFF7F59),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Nearby Restaurants header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nearby Restaurants',
                        style: TextStyle(
                          fontFamily: 'SofiaSans',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Animate the draggable sheet to full height (1.0)
                          if (_dragController.size < 0.95) { // Check if not already fully expanded
                            _dragController.animateTo(
                              1.0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Row(
                          children: const [
                            Text(
                              'View All',
                              style: TextStyle(
                                fontFamily: 'SofiaSans',
                                color: Color(0xFFFF7F59),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Color(0xFFFF7F59),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Restaurant list - NOT draggable, just scrollable
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    // Only add bottom padding for nav bar (not keyboard) since search bar is now always visible
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 80,
                    ),
                    itemCount: restaurants.length,
                    itemBuilder: (context, index) {
                      final restaurant = restaurants[index];
                      return _buildRestaurantCard(restaurant);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> restaurant) {
    String? photoUrl;
    if (restaurant['photos'] != null &&
        restaurant['photos'] is List &&
        (restaurant['photos'] as List).isNotEmpty) {
      final photoRef = restaurant['photos'][0];
      photoUrl =
          'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoRef&key=$apiKey';
    }

    final String restaurantId = restaurant['place_id'] ?? restaurant['name'] ?? '';
    final isFavourite = favouriteRestaurantIds.contains(restaurantId);

    // Determine opening status string and color (color-blind friendly)
    String openingStatusText = '';
    Color openingStatusColor = const Color(0xFF66FF00); // bright green for open
    Color openingStatusBgColor = const Color(0xFFECFFDE); // light green
    if (restaurant.containsKey('opening_status')) {
      if (restaurant['opening_status'] == true) {
        openingStatusText = 'Open';
        openingStatusColor = const Color(0xFF66FF00); // bright green for open
        openingStatusBgColor = const Color(0xFFECFFDE); // light green
      } else if (restaurant['opening_status'] == false) {
        openingStatusText = 'Closed';
        openingStatusColor = const Color(0xFFBDBDBD); // dark grey for closed
        openingStatusBgColor = const Color(0xFFF5F5F5); // light grey
      }
    }

    return GestureDetector(
      onTap: () { _navigateToViewRestaurant(context, restaurant); },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: photoUrl != null
                      ? Image.network(
                          photoUrl,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset('assets/images/profile.png', height: 140, width: double.infinity, fit: BoxFit.cover),
                        )
                      : Image.asset('assets/images/profile.png', height: 140, width: double.infinity, fit: BoxFit.cover),
                ),
                // Rating badge (top left)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          restaurant['rating'] != null ? '${restaurant['rating']}' : '-',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black,
                            fontFamily: 'SofiaSans',
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        if (restaurant['number_of_ratings'] != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Text(
                              '(${restaurant['number_of_ratings']})',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontFamily: 'SofiaSans',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Favourite button (top right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() {
                          if (isFavourite) {
                            favouriteRestaurantIds.remove(restaurantId);
                          } else {
                            favouriteRestaurantIds.add(restaurantId);
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          isFavourite ? Icons.favorite : Icons.favorite_border,
                          color: isFavourite ? Color(0xFFFF7F59) : Colors.grey[400],
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant name and verified icon
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            fontFamily: 'SofiaSans',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Icon(Icons.verified, color: Color(0xFF2DC653), size: 18),
                    ],
                  ),
                  // Remove previous opening status display here (was below name and above address)
                  const SizedBox(height: 8),
                  // Restaurant address/details
                  if (restaurant['address'] != null)
                    Text(
                      restaurant['address'],
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontFamily: 'SofiaSans',
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),
                  // Opening status and categories as chips (styled to match theme)
                  if ((restaurant['categories'] != null && restaurant['categories'] is List) || openingStatusText.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: [
                        if (openingStatusText.isNotEmpty)
                          Chip(
                            label: Text(
                              openingStatusText.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'SofiaSans',
                                fontWeight: FontWeight.w600,
                                color: openingStatusColor,
                                letterSpacing: 0.2,
                              ),
                            ),
                            backgroundColor: openingStatusBgColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: openingStatusColor,
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          ),
                        ...((restaurant['categories'] as List?)?.map<Widget>((categoryItem) {
                          final String categoryText = categoryItem.toString().toUpperCase();
                          return Chip(
                            label: Text(
                              categoryText,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'SofiaSans',
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF7F59),
                                letterSpacing: 0.2,
                              ),
                            ),
                            // backgroundColor: Color(0xFFE0E0E0), // light grey background
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: const Color(0xFFFF7F59), 
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          );
                        }).toList() ?? []),
                      ],
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
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
                _buildNavItem('assets/images/home_icon.png', true, () {
                  _navigateToHome(context);
                }),
                _buildNavItem('assets/images/feedback_icon.png', false, () {
                  _navigateToFeedback(context);
                }),
                _buildNavItem('assets/images/recommend_icon.png', false, () {
                  _navigateToRecommend(context);
                }),
                _buildNavItem('assets/images/favourite_icon.png', false, () {
                  _navigateToFavourite(context);
                }),
                _buildNavItem('assets/images/profile_icon.png', false, () {
                  _navigateToProfile(context);
                }),
              ],
            ),
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

  void _showAddressSelector() async {
    await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              padding: const EdgeInsets.only(top: 16, left: 0, right: 0, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    child: Text(
                      'Select Address',
                      style: TextStyle(
                        fontFamily: 'SofiaSans',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._addresses.map((address) {
                    final isSelected = address == _selectedAddress;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFF5F2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Selection circle (now tappable)
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              setState(() {
                                _selectedAddress = address;
                              });
                              setModalState(() {});
                              Navigator.pop(context, address);
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4, right: 12),
                              child: Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: isSelected
                                    ? const Color(0xFFFF7F59)
                                    : Colors.grey,
                                size: 26,
                              ),
                            ),
                          ),
                          // Address text
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setState(() {
                                  _selectedAddress = address;
                                });
                                setModalState(() {});
                                Navigator.pop(context, address);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
                                child: Text(
                                  address,
                                  style: TextStyle(
                                    fontFamily: 'SofiaSans',
                                    fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected
                                        ? const Color(0xFFFF7F59)
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Edit icon
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFFFF7F59), size: 20),
                            splashRadius: 20,
                            onPressed: () async {
                              final controller = TextEditingController(text: address);
                              final result = await showDialog<Map<String, dynamic>>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Edit Address'),
                                    content: TextField(
                                      controller: controller,
                                      maxLines: 3,
                                      decoration: const InputDecoration(
                                        hintText: 'Edit address',
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, {'delete': true}),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.redAccent),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context, {
                                            'edit': controller.text.trim()
                                          });
                                        },
                                        child: const Text('Save'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (result != null && result['edit'] != null && result['edit'].isNotEmpty) {
                                final idx = _addresses.indexOf(address);
                                setState(() {
                                  _addresses[idx] = result['edit'];
                                  if (_selectedAddress == address) _selectedAddress = result['edit'];
                                });
                                setModalState(() {});
                              } else if (result != null && result['delete'] == true) {
                                setState(() {
                                  _addresses.remove(address);
                                  if (_selectedAddress == address && _addresses.isNotEmpty) {
                                    _selectedAddress = _addresses.first;
                                  }
                                });
                                setModalState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
                    child: TextButton.icon(
                      onPressed: () async {
                        final newAddress = await showDialog<String>(
                          context: context,
                          builder: (context) {
                            final controller = TextEditingController();
                            return AlertDialog(
                              title: const Text('Add New Address'),
                              content: TextField(
                                controller: controller,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  hintText: 'Enter new address',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context, controller.text.trim());
                                  },
                                  child: const Text('Add'),
                                ),
                              ],
                            );
                          },
                        );
                        if (newAddress != null && newAddress.isNotEmpty) {
                          setState(() {
                            _addresses.add(newAddress);
                            _selectedAddress = newAddress;
                          });
                          setModalState(() {});
                        }
                      },
                      icon: const Icon(Icons.add, color: Color(0xFFFF7F59)),
                      label: const Text(
                        'Add Address',
                        style: TextStyle(
                          fontFamily: 'SofiaSans',
                          color: Color(0xFFFF7F59),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    // No need to update _selectedAddress here, it's handled inside the modal now
  }

  void _navigateToFeedback(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FeedbackScreen()),
    );
  }

  void _navigateToFavourite(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FavouritesScreen()),
    );
  }

  void _navigateToWelcome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (route) => false, // Remove all previous routes
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  void _navigateToRecommend(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RecommendScreen()),
    );
  }

  void _navigateToHome(BuildContext context) {
    // Reset the draggable scrollable sheet to its initial position
    _dragController.animateTo(
      0.5, // initialChildSize
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _navigateToViewRestaurant(BuildContext context, Map<String, dynamic> restaurant) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ViewRestaurantScreen(
        restaurant: restaurant,
        isFavourite: favouriteRestaurantIds.contains(restaurant['place_id'] ?? restaurant['name'] ?? ''),
      ),
    ),
  );
}
}