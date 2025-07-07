import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'feedback_screen.dart';
import 'home_screen.dart';
import 'view_restaurant_screen.dart';
import 'profile_screen.dart';
import 'recommend_screen.dart';
import '../services/restaurant_data_service.dart'; // Import the new service

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> favouriteRestaurants = [];
  String? apiKey;

  @override
  void initState() {
    super.initState();
    _loadApiKeyAndFetchFavourites();
  }

  Future<void> _loadApiKeyAndFetchFavourites() async {
    apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    await _fetchFavourites();
  }

  Future<void> _fetchFavourites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted && userDoc.exists && userDoc.data()?['favourites'] != null) {
        final favouritesData = List<dynamic>.from(userDoc.data()!['favourites']);
        setState(() {
          favouriteRestaurants =
              favouritesData.map((fav) => Map<String, dynamic>.from(fav)).toList();
        });
      }
    } catch (e) {
      // Handle or log error
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFavourite(Map<String, dynamic> restaurant) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    // On this screen, toggling always means removing from favourites.
    await userDocRef.update({
      'favourites': FieldValue.arrayRemove([restaurant])
    });

    // Update UI instantly
    if (mounted) {
      setState(() {
        favouriteRestaurants
            .removeWhere((fav) => fav['place_id'] == restaurant['place_id']);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  // Back button with shadow and rounded background
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          size: 22, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  // Centered title
                  const Text(
                    'Favorites',
                    style: TextStyle(
                      fontFamily: 'SofiaSans',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  // Avatar/profile icon (placeholder, adjust as needed)
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
            const SizedBox(height: 24),
            // Expanded to allow the list to take remaining space
            Expanded(child: _buildFavouritesList()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildFavouritesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (favouriteRestaurants.isEmpty) {
      return const Center(
        child: Text(
          'No favourite restaurants yet.',
          style: TextStyle(
              fontFamily: 'SofiaSans', fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: favouriteRestaurants.length,
      itemBuilder: (context, index) {
        final restaurant = favouriteRestaurants[index];
        return _buildRestaurantCard(restaurant);
      },
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> restaurant) {
    String? photoUrl;
    if (restaurant['photos'] != null &&
        restaurant['photos'] is List &&
        (restaurant['photos'] as List).isNotEmpty) {
      final photoRef = restaurant['photos'][0];
      if (apiKey != null) {
        photoUrl =
            'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoRef&key=$apiKey';
      }
    }

    String openingStatusText = '';
    Color openingStatusIconColor = Colors.grey;
    if (restaurant.containsKey('opening_status')) {
      if (restaurant['opening_status'] == true) {
        openingStatusText = 'Open';
        openingStatusIconColor = Colors.green;
      } else if (restaurant['opening_status'] == false) {
        openingStatusText = 'Closed';
        openingStatusIconColor = Colors.red.shade300;
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewRestaurantScreen(
              restaurant: restaurant,
              isFavourite: true, // Always true on this screen
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
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
                              Image.asset('assets/images/profile.png',
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover),
                        )
                      : Image.asset('assets/images/profile.png',
                          height: 150, width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
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
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.favorite,
                        color: Color(0xFFFF7F59),
                      ),
                      iconSize: 20,
                      constraints:
                          const BoxConstraints(minWidth: 30, minHeight: 30),
                      padding: EdgeInsets.zero,
                      onPressed: () async {
                        await _toggleFavourite(restaurant);
                      },
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontFamily: 'SofiaSans',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
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
                  // const SizedBox(height: 8),
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
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children:
                        (restaurant['categories'] as List<dynamic>?)?.map((category) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
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
      ),
    );
  }

  Widget _buildBottomNavigation() {
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
              _buildNavItem('assets/images/home_icon.png', false, () {
                _navigateToHome(context);
              }),
              _buildNavItem('assets/images/feedback_icon.png', false, () {
                _navigateToFeedback(context);
              }),
              _buildNavItem('assets/images/recommend_icon.png', false, () {
                _navigateToRecommend(context);
              }),
              _buildNavItem('assets/images/favourite_icon.png', true, () {
                // Already on Favourites, do nothing or maybe scroll to top
              }),
              _buildNavItem('assets/images/profile_icon.png', false, () {
                _navigateToProfile(context);
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

  void _navigateToHome(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _navigateToFeedback(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FeedbackScreen()),
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  void _navigateToRecommend(BuildContext context) async {
    // Ensure the data is loaded before navigating.
    final restaurants = RestaurantDataService.instance.getRestaurants();
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
}