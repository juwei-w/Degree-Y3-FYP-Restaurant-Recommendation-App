import 'dart:async';
import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';
import '../services/restaurant_data_service.dart'; // Import the new service
import 'feedback_screen.dart';
import 'favourites_screen.dart';
import 'profile_screen.dart';
import 'welcome_screen.dart';
import 'recommend_screen.dart';
import 'view_restaurant_screen.dart';
import '../widgets/loading_dialog.dart';

final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

class RestaurantCache {
  static List<Map<String, dynamic>> restaurants = [];
  static List<Map<String, dynamic>> filteredRestaurants = []; // Add this line
  static Map<String, dynamic>? lastLoadedAddress;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  String _userName = 'User Name';
  String _userEmail = 'user@email.com';

  final DraggableScrollableController _dragController =
      DraggableScrollableController();
  double _dragPosition = 0.5;

  List<Map<String, dynamic>> restaurants = [];
  
  bool _isDialogShowing = false;
  bool _showAddressDropdown = false;
  List<Map<String, dynamic>> _addresses = []; // Changed to List of Maps
  Map<String, dynamic>? _selectedAddress; // Changed to a Map object
  Map<String, dynamic>? _lastLoadedAddress;

  final LocationService _locationService = LocationService();

  // Fetch user's favourites from Firestore (e.g., in initState or with a FutureBuilder)
  List<dynamic> userFavourites = []; // This will be a list of restaurant objects

  GoogleMapController? _mapController;

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredRestaurants = [];

  @override
  void initState() {
    super.initState();
    log('HomeScreen initState called');
    _dragController.addListener(() {
      if (_dragPosition != _dragController.size) {
        setState(() {
          _dragPosition = _dragController.size;
        });
      }
    });

    // Restore from cache if available
    restaurants = RestaurantCache.restaurants;
    filteredRestaurants = RestaurantCache.filteredRestaurants; // Add this line
    _lastLoadedAddress = RestaurantCache.lastLoadedAddress;

    _initializeData();

    _searchController.addListener(() {
      _filterRestaurants(_searchController.text);
    });
  }

  Future<void> _initializeData() async {
    // Fetch user data, which now also determines the selected address from Firestore
    await _fetchUserInfo();

    // If no address was marked as 'selected' in the database, default to current location
    if (_selectedAddress == null) {
      await _getCurrentUserLocation();
    }

    // Set _lastLoadedAddress if not set yet
    if (_selectedAddress != null && _lastLoadedAddress == null) {
      _lastLoadedAddress = Map<String, dynamic>.from(_selectedAddress!);
      log('[_initializeData] Set _lastLoadedAddress: $_lastLoadedAddress');
    }

    // Load restaurant data after the location has been finalized
    await _loadRestaurantData();

    // Zoom to the selected location on first run
    _moveMapToSelectedAddress();
  }

  Future<void> _getCurrentUserLocation() async {
    log('Attempting to get current location...');
    try {
      final position = await _locationService.getCurrentLocation();
      final addressString = await _locationService.getAddressFromLatLng(position);
      if (mounted) {
        setState(() {
          _selectedAddress = {
            'address': addressString,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'label': 'Current Location',
            'isSelected': true,
          };
        });
        // Fetch restaurants for the new current location
        await _loadRestaurantData();
      }
    } catch (e) {
      log('Failed to get current location: $e');
      if (mounted) {
        setState(() {
          _selectedAddress = null;
        });
      }
    }
  }

  Future<void> _fetchUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String name = 'User Name';
      List<Map<String, dynamic>> userSavedAddresses = [];
      List<dynamic> favourites = [];

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          name = userData['name'] ?? user.displayName ?? 'User Name';

          if (userData['address'] != null && userData['address'] is List) {
            userSavedAddresses = List<Map<String, dynamic>>.from(
                userData['address']
                    .map((item) => Map<String, dynamic>.from(item)));
          }

          if (userData['favourites'] != null &&
              userData['favourites'] is List) {
            favourites = userData['favourites'];
          }
        }
      } catch (_) {
        name = user.displayName ?? 'User Name';
      }
      if (mounted) {
        setState(() {
          _userName = name;
          _userEmail = user.email ?? 'user@email.com';
          userFavourites = favourites;
          _addresses = userSavedAddresses;

          // If there are no addresses, set _selectedAddress to null
          if (_addresses.isEmpty) {
            _selectedAddress = null;
          } else {
            // Find the selected address from the list fetched from Firestore
            final selected = _addresses.firstWhere(
              (addr) => addr['isSelected'] == true,
              orElse: () => <String, dynamic>{},
            );
            if (selected.isNotEmpty) {
              _selectedAddress = selected;
            } else {
              _selectedAddress = null; // Explicitly null if none is selected in DB
            }
          }
        });

        bool _isSameLocation(Map<String, dynamic> a, Map<String, dynamic> b, {double tolerance = 0.0001}) {
          return (a['latitude'] - b['latitude']).abs() < tolerance &&
                (a['longitude'] - b['longitude']).abs() < tolerance;
        }

        log('[_fetchUserInfo] _selectedAddress: $_selectedAddress');
        log('[_fetchUserInfo] _lastLoadedAddress: $_lastLoadedAddress');

        if (_selectedAddress != null && _lastLoadedAddress != null) {
          log('[_fetchUserInfo] Checking if locations are the same...');
          if (_isSameLocation(_selectedAddress!, _lastLoadedAddress!)) {
            log('[_fetchUserInfo] Location unchanged, using cached restaurants.');
            setState(() {
              restaurants = RestaurantDataService.instance.getRestaurants();
            });
          } else {
            log('[_fetchUserInfo] Location changed, fetching new restaurants.');
            await _loadRestaurantData();
          }
        } else {
          log('[_fetchUserInfo] One or both addresses are null, fetching restaurants.');
          await _loadRestaurantData();
        }
      }
    }
  }

  Future<void> _loadRestaurantData() async {
    if (_selectedAddress == null) {
      log('[_loadRestaurantData] _selectedAddress is null, aborting.');
      return;
    }

    if (_lastLoadedAddress != null) {
      log('[_loadRestaurantData] _lastLoadedAddress: $_lastLoadedAddress');
      log('[_loadRestaurantData] _selectedAddress: $_selectedAddress');
    }

    // Prevent refetch if address hasn't changed
    bool _isSameLocation(Map<String, dynamic> a, Map<String, dynamic> b, {double tolerance = 0.0001}) {
      return (a['latitude'] - b['latitude']).abs() < tolerance &&
            (a['longitude'] - b['longitude']).abs() < tolerance;
    }

    if (_lastLoadedAddress != null && _isSameLocation(_selectedAddress!, _lastLoadedAddress!)) {
      log('[_loadRestaurantData] Address unchanged, skipping restaurant fetch.');
      return;
    }

    showLoadingDialog(context, message: "Fetching restaurants...");
    try {
      log('[_loadRestaurantData] Fetching restaurants for: ${_selectedAddress!['latitude']}, ${_selectedAddress!['longitude']}');
      await RestaurantDataService.instance.loadRestaurants(
        latitude: _selectedAddress!['latitude'],
        longitude: _selectedAddress!['longitude'],
      );
      if (mounted) {
        setState(() {
          restaurants = RestaurantDataService.instance.getRestaurants();
          filteredRestaurants = List<Map<String, dynamic>>.from(restaurants);
          _lastLoadedAddress = Map<String, dynamic>.from(_selectedAddress!);

          // Save to cache
          RestaurantCache.restaurants = restaurants;
          RestaurantCache.filteredRestaurants = filteredRestaurants; // Add this line
          RestaurantCache.lastLoadedAddress = _lastLoadedAddress;

          log('[_loadRestaurantData] Updated _lastLoadedAddress: $_lastLoadedAddress');
        });
      }
    } finally {
      hideLoadingDialog(context);
    }
  }

  /// Central method to update the address selection state in Firestore.
  Future<void> _updateAddressSelectionInDb({
    Map<String, dynamic>? newSelectedAddress,
    bool skipLoadRestaurants = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    // Update addresses
    final updatedAddresses = _addresses.map((addr) {
      final isSelected = (newSelectedAddress != null) &&
          (addr['address'] == newSelectedAddress['address']);
      return {...addr, 'isSelected': isSelected};
    }).toList();

    await userDocRef.update({'address': updatedAddresses});
    await _fetchUserInfo();

    // Only load restaurants if not skipping (i.e., not for current location)
    if (!skipLoadRestaurants) {
      await _loadRestaurantData();
    }
    // Move map to the new selected address
    _moveMapToSelectedAddress();
  }

  Future<void> _saveNewAddress(Map<String, dynamic> newAddressData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    // Make all existing addresses not selected
    final unselectedAddresses =
        _addresses.map((addr) => {...addr, 'isSelected': false}).toList();

    // Add the new address and mark it as selected
    final newAddressWithSelection = {...newAddressData, 'isSelected': true};
    final updatedList = [...unselectedAddresses, newAddressWithSelection];

    await userDocRef.update({'address': updatedList});
    await _fetchUserInfo(); // Refresh UI, which will set the new address as selected
    _moveMapToSelectedAddress(); // Move map to the new address
  }

  Future<void> _updateAddress(Map<String, dynamic> oldAddressData,
      Map<String, dynamic> newAddressData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    // Create a new list where the updated address is selected and all others are not.
    final updatedAddresses = _addresses.map((addr) {
      // If this is the address we are updating, replace it and mark as selected.
      if (addr['address'] == oldAddressData['address']) {
        return {...newAddressData, 'isSelected': true};
      }
      // Otherwise, ensure it's not selected.
      return {...addr, 'isSelected': false};
    }).toList();

    await userDocRef.update({'address': updatedAddresses});
    await _fetchUserInfo(); // Refresh UI
    _moveMapToSelectedAddress(); // Move map to the new address
  }

  Future<void> _deleteAddress(Map<String, dynamic> addressToDelete) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    // Remove the address from the list
    final remainingAddresses = _addresses
        .where((addr) => addr['address'] != addressToDelete['address'])
        .toList();

    await userDocRef.update({'address': remainingAddresses});
    await _fetchUserInfo(); // Refresh UI

    // After fetching, if no address is selected, get current location.
    if (_selectedAddress == null) {
      await _getCurrentUserLocation();
    }
  }

  // To check if a restaurant is a favourite:
  bool isFavourite(String placeId) {
    return userFavourites.any((restaurant) => restaurant['place_id'] == placeId);
  }

  // When the favourite button is pressed:
  Future<void> toggleFavourite(Map<String, dynamic> restaurant) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

    // Use the full restaurant map for favourites
    final placeId = restaurant['place_id'];
    final isFavourite = userFavourites.any((fav) => fav['place_id'] == placeId);

    if (isFavourite) {
      await userDoc.set({
        'favourites': FieldValue.arrayRemove([
          // Remove by matching the full object structure
          userFavourites.firstWhere((fav) => fav['place_id'] == placeId)
        ])
      }, SetOptions(merge: true));
      setState(() {
        userFavourites.removeWhere((fav) => fav['place_id'] == placeId);
      });
    } else {
      await userDoc.set({
        'favourites': FieldValue.arrayUnion([restaurant])
      }, SetOptions(merge: true));
      setState(() {
        userFavourites.add(restaurant);
      });
    }
  }
  
  @override
  void dispose() {
    _dragController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // <-- Important for keep-alive
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
                          _fetchUserInfo();
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                    ),
                  ),
                  // Location dropdown (centered)
                  Expanded(
                    child: GestureDetector(
                      onTap: _showAddressSelector,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                                ),
                              ],
                            ),
                            Text(
                              _selectedAddress?['label'] ??
                                  _selectedAddress?['address'] ??
                                  'Fetching location...',
                              style: const TextStyle(
                                fontFamily: 'SofiaSans',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF7F59),
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
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
                                        address['label'] ?? address['address'],
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _userName,
                        style: const TextStyle(
                          fontFamily: 'SofiaSans',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _userEmail,
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
    // Default to Cyberjaya if no address is selected
    final double lat = _selectedAddress?['latitude'] ?? 2.9222396;
    final double lng = _selectedAddress?['longitude'] ?? 101.636466;

    final Set<Marker> restaurantMarkers = restaurants
        .where((r) => r['latitude'] != null && r['longitude'] != null)
        .map((r) => Marker(
              markerId: MarkerId(r['place_id'] ?? r['name'] ?? ''),
              position: LatLng(r['latitude'], r['longitude']),
              infoWindow: InfoWindow(title: r['name']),
            ))
        .toSet();

    // Add the selected location marker only if _selectedAddress is not null
    if (_selectedAddress != null) {
      restaurantMarkers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: LatLng(_selectedAddress!['latitude'], _selectedAddress!['longitude']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(lat, lng),
          zoom: 14,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
        mapType: MapType.normal,
        markers: restaurantMarkers,
        onMapCreated: (controller) {
          _mapController = controller;
        },
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
                            controller: _searchController,
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
                            onChanged: (value) {
                              setState(() {
                                filteredRestaurants = restaurants.where((restaurant) {
                                  final restaurantName = restaurant['name']?.toLowerCase() ?? '';
                                  final searchTerm = value.toLowerCase();
                                  return restaurantName.contains(searchTerm);
                                }).toList();
                              });
                            },
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
                    itemCount: filteredRestaurants.length,
                    itemBuilder: (context, index) {
                      final restaurant = filteredRestaurants[index];
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
    final isFavourite = userFavourites.any((fav) => fav['place_id'] == restaurantId);

    // Opening status logic
    String openingStatusText = '';
    Color openingStatusIconColor = Colors.grey;
    if (restaurant.containsKey('opening_status')) {
      if (restaurant['opening_status'] == true) {
        openingStatusText = 'Open';
        openingStatusIconColor = Colors.green; // Updated color
      } else if (restaurant['opening_status'] == false) {
        openingStatusText = 'Closed';
        openingStatusIconColor = Colors.red.shade300; // Updated color to light red
      }
    }

    return GestureDetector(
      onTap: () => _navigateToViewRestaurant(context, restaurant),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: photoUrl != null
                      ? Image.network(
                          photoUrl,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset('assets/images/tacos.png', height: 150, width: double.infinity, fit: BoxFit.cover),
                        )
                      : Image.asset('assets/images/tacos.png', height: 150, width: double.infinity, fit: BoxFit.cover),
                ),
                // Rating badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${restaurant['rating'] ?? '-'}',
                          style: const TextStyle(
                            fontFamily: 'SofiaSans',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${restaurant['user_ratings_total'] ?? '-'})',
                          style: TextStyle(
                            fontFamily: 'SofiaSans',
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Favourite button
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFavourite ? Icons.favorite : Icons.favorite_border,
                        color: const Color(0xFFFF7F59),
                      ),
                      iconSize: 20,
                      constraints: const BoxConstraints(
                        minWidth: 30,
                        minHeight: 30,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () async {
                        await toggleFavourite(restaurant);
                      },
                    ),
                  ),
                ),
              ],
            ),
            // Restaurant info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and verified badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontFamily: 'SofiaSans',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Opening status
                  if (openingStatusText.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_filled,
                          color: openingStatusIconColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          openingStatusText,
                          style: TextStyle(
                            fontFamily: 'SofiaSans',
                            fontSize: 12,
                            color: openingStatusIconColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  // // Address
                  // if (restaurant['address'] != null)
                  //   Text(
                  //     restaurant['address'],
                  //     style: TextStyle(
                  //       fontFamily: 'SofiaSans',
                  //       fontSize: 12,
                  //       color: Colors.grey[600],
                  //     ),
                  //     maxLines: 2,
                  //     overflow: TextOverflow.ellipsis,
                  //   ),
                  // const SizedBox(height: 8),
                  // Categories (wrapped)
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: (restaurant['categories'] as List?)?.map((category) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              category.toString().toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'SofiaSans',
                                fontSize: 10,
                                color: Colors.grey[700],
                              ),
                            ),
                          );
                        }).toList() ??
                        [],
                  ),
                ],
              ),
            ),
          ],
        ),
      )
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
            // Helper function to select current location
            void selectCurrentLocation() async {
              Navigator.pop(context); // Close modal

              // showLoadingDialog(context, message: "Updating location...");
              try {
                await _updateAddressSelectionInDb(newSelectedAddress: null, skipLoadRestaurants: true);
                await _getCurrentUserLocation();
                await _loadRestaurantData();
              } finally {
                // hideLoadingDialog(context);
              }
            }

            // Determine if 'Current Location' is the active selection
            final isCurrentLocationSelected =
                _selectedAddress?['label'] == 'Current Location' ||
                    _addresses.every((addr) => addr['isSelected'] != true);

            return Container(
              constraints: const BoxConstraints(minWidth: 500),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              padding: const EdgeInsets.only(
                  top: 16, left: 0, right: 0, bottom: 8),
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

                  // "Use Current Location" option
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCurrentLocationSelected
                          ? const Color(0xFFFFF5F2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: selectCurrentLocation,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4, right: 12),
                            child: Icon(
                              isCurrentLocationSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: isCurrentLocationSelected
                                  ? const Color(0xFFFF7F59)
                                  : Colors.grey,
                              size: 26,
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: selectCurrentLocation,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 0),
                              child: Text(
                                'Use Current Location',
                                style: TextStyle(
                                  fontFamily: 'SofiaSans',
                                  fontSize: 16,
                                  fontWeight: isCurrentLocationSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isCurrentLocationSelected
                                      ? const Color(0xFFFF7F59)
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                            width: 48), // Placeholder for alignment
                      ],
                    ),
                  ),

                  ..._addresses.map((address) {
                    final isSelected = address['isSelected'] ?? false;
                    final String displayText =
                        address['label'] ?? address['address'];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFFF5F2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              _updateAddressSelectionInDb(
                                  newSelectedAddress: address);
                              Navigator.pop(context);
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
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                _updateAddressSelectionInDb(
                                    newSelectedAddress: address);
                                Navigator.pop(context);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 0),
                                child: Text(
                                  displayText,
                                  style: TextStyle(
                                    fontFamily: 'SofiaSans',
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? const Color(0xFFFF7F59)
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Color(0xFFFF7F59), size: 20),
                            splashRadius: 20,
                            onPressed: () async {
                              Navigator.pop(context);
                              _showAddOrEditAddressDialog(
                                  existingAddress: address);
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
                        Navigator.pop(context);
                        _showAddOrEditAddressDialog();
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
  }

  void _showAddOrEditAddressDialog({Map<String, dynamic>? existingAddress}) {
    final labelController =
        TextEditingController(text: existingAddress?['label']);
    final addressController =
        TextEditingController(text: existingAddress?['address']);
    final latController = TextEditingController(
        text: existingAddress?['latitude']?.toString());
    final lonController = TextEditingController(
        text: existingAddress?['longitude']?.toString());

    List<Map<String, String>> suggestions = [];
    bool isLoading = false;
    Timer? debounce;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void searchAddress(String value) {
              if (debounce?.isActive ?? false) debounce!.cancel();
              debounce = Timer(const Duration(milliseconds: 500), () async {
                if (value.isNotEmpty) {
                  setDialogState(() => isLoading = true);
                  final result = await _locationService
                      .getAutocompleteSuggestions(value, apiKey!);
                  setDialogState(() {
                    suggestions = result;
                    isLoading = false;
                  });
                } else {
                  setDialogState(() => suggestions = []);
                }
              });
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Text(
                          existingAddress == null
                              ? 'Add New Address'
                              : 'Edit Address',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      TextField(
                          controller: labelController,
                          decoration: const InputDecoration(
                              labelText: 'Label (e.g., Home, Work)')),
                      const SizedBox(height: 16),
                      TextField(
                        controller: addressController,
                        onChanged: searchAddress,
                        decoration: const InputDecoration(
                            labelText: 'Search Full Address'),
                      ),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      if (suggestions.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SizedBox(
                            height: 150,
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: suggestions.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final suggestion = suggestions[index];
                                return ListTile(
                                  title: Text(suggestion['description']!),
                                  onTap: () async {
                                    final selectedDescription =
                                        suggestion['description']!;
                                    final details = await _locationService
                                        .getPlaceDetails(
                                            suggestion['place_id']!, apiKey!);
                                    if (details != null) {
                                      setDialogState(() {
                                        addressController.text =
                                            selectedDescription;
                                        latController.text =
                                            details['latitude'].toString();
                                        lonController.text =
                                            details['longitude'].toString();
                                        suggestions = [];
                                      });
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                              child: TextField(
                                  controller: latController,
                                  decoration: const InputDecoration(
                                      labelText: 'Latitude'),
                                  keyboardType: TextInputType.number)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: TextField(
                                  controller: lonController,
                                  decoration: const InputDecoration(
                                      labelText: 'Longitude'),
                                  keyboardType: TextInputType.number)),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Row(
                          children: [
                            if (existingAddress != null)
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await _deleteAddress(existingAddress);
                                },
                                child: const Text('Delete',
                                    style:
                                        TextStyle(color: Colors.redAccent)),
                              ),
                            const Spacer(),
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel')),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                final newAddressData = {
                                  'label': labelController.text.trim(),
                                  'address': addressController.text.trim(),
                                  'latitude': double.tryParse(
                                          latController.text.trim()) ??
                                      0.0,
                                  'longitude': double.tryParse(
                                          lonController.text.trim()) ??
                                      0.0,
                                };

                                if (newAddressData['address'] == '' ||
                                    newAddressData['latitude'] == 0.0) {
                                  return;
                                }

                                if ((newAddressData['label'] as String)
                                    .isEmpty) {
                                  newAddressData['label'] =
                                      newAddressData['address'] as String;
                                }

                                Navigator.pop(context);
                                if (existingAddress == null) {
                                  await _saveNewAddress(newAddressData);
                                } else {
                                  await _updateAddress(
                                      existingAddress, newAddressData);
                                }
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      debounce?.cancel();
    });
  }

  void _navigateToFeedback(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FeedbackScreen()),
    );
  }

  void _navigateToFavourite(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FavouritesScreen()),
    );
    // Refresh user data when returning from the favourites screen
    // _fetchUserInfo();
  }

  void _navigateToWelcome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (route) => false, // Remove all previous routes
    );
  }

  void _navigateToProfile(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
    // Refresh user data when returning from the profile screen
    _fetchUserInfo();
  }

  void _navigateToRecommend(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              RecommendScreen(restaurants: restaurants, user: user),
        ),
      );
    }
  }

  void _navigateToHome(BuildContext context) {
    // Reset the draggable scrollable sheet to its initial position
    _dragController.animateTo(
      0.5, // initialChildSize
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _navigateToViewRestaurant(
      BuildContext context, Map<String, dynamic> restaurant) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewRestaurantScreen(
          restaurant: restaurant,
          isFavourite: userFavourites.any(
            (fav) =>
                fav['place_id'] ==
                (restaurant['place_id'] ?? restaurant['name'] ?? ''),
          ),
        ),
      ),
    );
    // Refresh user data when returning from the view restaurant screen
    _fetchUserInfo();
  }

  void _moveMapToSelectedAddress() {
    if (_mapController != null && _selectedAddress != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_selectedAddress!['latitude'], _selectedAddress!['longitude']),
        ),
      );
    }
  }

  void showLoadingDialog(BuildContext context, {String? message}) {
    _isDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LoadingDialog(message: message),
    );
  }

  void hideLoadingDialog(BuildContext context) {
    if (_isDialogShowing) {
      Navigator.of(context, rootNavigator: true).pop();
      _isDialogShowing = false;
    }
  }
  
  void _filterRestaurants(String query) {
    query = query.toLowerCase();
    setState(() {
      filteredRestaurants = restaurants.where((restaurant) {
        final name = restaurant['name']?.toLowerCase() ?? '';
        return name.contains(query);
      }).toList();
      RestaurantCache.filteredRestaurants = filteredRestaurants; // Add this line
    });
  }
}