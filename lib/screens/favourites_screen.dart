import 'package:flutter/material.dart';
import 'feedback_screen.dart';
import 'home_screen.dart';
import 'view_restaurant_screen.dart';
import 'profile_screen.dart';
import 'recommend_screen.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  // Sample favorite restaurant data
  final List<Map<String, dynamic>> favouriteRestaurants = [
    {
      'name': 'McDonald\'s',
      'image': 'assets/images/tacos.png',
      'rating': 4.5,
      'reviews': 154,
      'freeDelivery': true,
      'deliveryTime': '10-15 mins',
      'categories': ['BURGER', 'CHICKEN', 'FAST FOOD'],
      'isFavorite': true,
      'isVerified': true,
      'address': '123 Main Street',
      'operatingHours': 'Operating Hours',
    },
    {
      'name': 'McDonald\'s',
      'image': 'assets/images/pizza.png',
      'rating': 4.5,
      'reviews': 154,
      'freeDelivery': true,
      'deliveryTime': '10-15 mins',
      'categories': ['BURGER', 'CHICKEN', 'FAST FOOD'],
      'isFavorite': true,
      'isVerified': true,
      'address': '123 Main Street',
      'operatingHours': 'Operating Hours',
    },
    {
      'name': 'McDonald\'s',
      'image': 'assets/images/tacos.png',
      'rating': 4.5,
      'reviews': 154,
      'freeDelivery': true,
      'deliveryTime': '10-15 mins',
      'categories': ['BURGER', 'CHICKEN', 'FAST FOOD'],
      'isFavorite': true,
      'isVerified': true,
      'address': '123 Main Street',
      'operatingHours': 'Operating Hours',
    },
    {
      'name': 'McDonald\'s',
      'image': 'assets/images/pizza.png',
      'rating': 4.5,
      'reviews': 154,
      'freeDelivery': true,
      'deliveryTime': '10-15 mins',
      'categories': ['BURGER', 'CHICKEN', 'FAST FOOD'],
      'isFavorite': true,
      'isVerified': true,
      'address': '123 Main Street',
      'operatingHours': 'Operating Hours',
    },
    {
      'name': 'McDonald\'s',
      'image': 'assets/images/tacos.png',
      'rating': 4.5,
      'reviews': 154,
      'freeDelivery': true,
      'deliveryTime': '10-15 mins',
      'categories': ['BURGER', 'CHICKEN', 'FAST FOOD'],
      'isFavorite': true,
      'isVerified': true,
      'address': '123 Main Street',
      'operatingHours': 'Operating Hours',
    },
    {
      'name': 'McDonald\'s',
      'image': 'assets/images/tacos.png',
      'rating': 4.5,
      'reviews': 154,
      'freeDelivery': true,
      'deliveryTime': '10-15 mins',
      'categories': ['HALAL', 'VEGETARIAN', 'FAST FOOD'],
      'isFavorite': true,
      'isVerified': true,
      'address': 'Address',
      'operatingHours': 'Operating Hours',
    },
  ];

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
                      icon: const Icon(Icons.arrow_back_ios_new, size: 22, color: Colors.black),
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favouriteRestaurants.length,
      itemBuilder: (context, index) {
        final restaurant = favouriteRestaurants[index];
        final bool isLastItem = index == favouriteRestaurants.length - 1;

        // Wrap the card in GestureDetector to navigate on tap
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewRestaurantScreen(restaurant: restaurant, isFavourite: favouriteRestaurants.contains(restaurant['place_id'] ?? restaurant['name'] ?? ''),),
              ),
            );
          },
          child: _buildRestaurantCard(restaurant, isLastItem),
        );
      },
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> restaurant, bool showDetails) {
    return Container(
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
          // Restaurant image
          Stack(
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Image.asset(
                  restaurant['image'],
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
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
                        '${restaurant['rating']}',
                        style: const TextStyle(
                          fontFamily: 'SofiaSans',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${restaurant['reviews']})',
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
              
              // Favorite button
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
                      restaurant['isFavorite'] ? Icons.favorite : Icons.favorite_border,
                      color: const Color(0xFFFF7F59),
                    ),
                    iconSize: 20,
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        restaurant['isFavorite'] = !restaurant['isFavorite'];
                      });
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
                    Text(
                      restaurant['name'],
                      style: const TextStyle(
                        fontFamily: 'SofiaSans',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (restaurant['isVerified'])
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                  ],
                ),
                
                // Show address and operating hours for the last item
                if (showDetails) ...[
                  const SizedBox(height: 4),
                  Text(
                    restaurant['address'],
                    style: TextStyle(
                      fontFamily: 'SofiaSans',
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restaurant['operatingHours'],
                    style: TextStyle(
                      fontFamily: 'SofiaSans',
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                ] else ...[
                  const SizedBox(height: 4),
                  
                  // Delivery info
                  Row(
                    children: [
                      if (restaurant['freeDelivery'])
                        Row(
                          children: [
                            const Icon(
                              Icons.local_shipping_outlined,
                              color: Color(0xFFFF7F59),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Free delivery',
                              style: TextStyle(
                                fontFamily: 'SofiaSans',
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Color(0xFFFF7F59),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            restaurant['deliveryTime'],
                            style: TextStyle(
                              fontFamily: 'SofiaSans',
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                ],
                
                // Categories
                Row(
                  children: (restaurant['categories'] as List<String>).map((category) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontFamily: 'SofiaSans',
                          fontSize: 10,
                          color: Colors.grey[700],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
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

  void _navigateToRecommend(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RecommendScreen()),
    );
  }

}