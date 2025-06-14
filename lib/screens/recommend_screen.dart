import 'package:flutter/material.dart';

class RecommendScreen extends StatefulWidget {
  const RecommendScreen({Key? key}) : super(key: key);

  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen>
    with TickerProviderStateMixin {
  bool isLiked = false;
  bool isDisliked = false;
  late AnimationController _likeAnimationController;
  late AnimationController _dislikeAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _likeAnimation;
  late Animation<double> _dislikeAnimation;
  late Animation<Offset> _cardSlideAnimation;

  // Sample restaurant data
  final List<Map<String, dynamic>> restaurants = [
    {
      'name': 'Taco Bell Cyberjaya',
      'rating': 4.5,
      'reviews': '30+',
      'priceRange': 'RM 1-20',
      'image': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400',
      'tags': ['HALAL', 'VEGETARIAN', 'FAST FOOD'],
    },
    {
      'name': 'Pizza Hut KLCC',
      'rating': 4.2,
      'reviews': '150+',
      'priceRange': 'RM 15-35',
      'image': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
      'tags': ['HALAL', 'ITALIAN', 'FAST FOOD'],
    },
    {
      'name': 'Nando\'s Pavilion',
      'rating': 4.7,
      'reviews': '200+',
      'priceRange': 'RM 20-40',
      'image': 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=400',
      'tags': ['HALAL', 'GRILLED', 'CASUAL DINING'],
    },
  ];

  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _dislikeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _likeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _likeAnimationController,
      curve: Curves.elasticOut,
    ));

    _dislikeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _dislikeAnimationController,
      curve: Curves.elasticOut,
    ));

    _cardSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _dislikeAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  void _toggleLike() {
    setState(() {
      isLiked = !isLiked;
      if (isLiked) {
        isDisliked = false; // If liked, un-dislike
      }
    });
    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reverse();
    });
  }

  void _handleDislike() {
    bool wasDisliked = isDisliked; // Store previous state
    setState(() {
      isDisliked = !isDisliked;
      if (isDisliked) {
        isLiked = false; // If disliked, un-like
      }
    });
    _dislikeAnimationController.forward().then((_) {
      _dislikeAnimationController.reverse();
      // Only proceed to next restaurant if it was newly disliked
      if (isDisliked && !wasDisliked) {
        _nextRestaurant();
      }
    });
  }

  void _nextRestaurant() async {
    if (currentIndex < restaurants.length - 1) {
      _cardSlideAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(0, -1.0),
      ).animate(CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.easeInOut,
      ));
      await _cardAnimationController.forward();

      setState(() {
        currentIndex++;
        isLiked = false;
        isDisliked = false; // Reset dislike for new card
      });
      _cardAnimationController.reset();

      _cardSlideAnimation = Tween<Offset>(
        begin: const Offset(0, 1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.easeInOut,
      ));
      await _cardAnimationController.forward();
    }
  }

  void _previousRestaurant() async {
    if (currentIndex > 0) {
      _cardSlideAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(0, 1.0),
      ).animate(CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.easeInOut,
      ));
      await _cardAnimationController.forward();

      setState(() {
        currentIndex--;
        isLiked = false;
        isDisliked = false; // Reset dislike for new card
      });
      _cardAnimationController.reset();

      _cardSlideAnimation = Tween<Offset>(
        begin: const Offset(0, -1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.easeInOut,
      ));
      await _cardAnimationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = restaurants[currentIndex];

    return Scaffold(
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! < -500) {
            // Swipe up - skip to next
            _nextRestaurant();
          } else if (details.primaryVelocity! > 500) {
            // Swipe down - go to previous
            _previousRestaurant();
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFF7B54),
                Color(0xFFFF6B47),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header with back button
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main content
                Expanded(
                  child: SlideTransition(
                    position: _cardSlideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Restaurant image
                          Container(
                            height: 280, // slightly smaller
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                restaurant['image'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.restaurant,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Restaurant name
                          Text(
                            restaurant['name'],
                            style: const TextStyle(
                              fontSize: 22, // smaller
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 10),

                          // Rating
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 18, // smaller
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${restaurant['rating']} (${restaurant['reviews']})',
                                style: const TextStyle(
                                  fontSize: 14, // smaller
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Price range
                          Text(
                            restaurant['priceRange'],
                            style: const TextStyle(
                              fontSize: 16, // smaller
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Tags
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: restaurant['tags']
                                .map<Widget>((tag) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        tag,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12, // smaller
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),

                          const SizedBox(height: 24),

                          // View Restaurant button
                          Container(
                            width: double.infinity,
                            height: 44, // smaller
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            child: ElevatedButton(
                              onPressed: () {
                                // Navigate to restaurant details
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Opening ${restaurant['name']}'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF5722),
                                foregroundColor: Colors.white,
                                elevation: 8,
                                shadowColor: Colors.black.withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: const Text(
                                'View Restaurant',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Like/Dislike buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Dislike button
                              ScaleTransition(
                                scale: _dislikeAnimation,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDisliked // Change color based on state
                                        ? const Color(0xFFFF5722) // Active color
                                        : Colors.white, // Inactive color
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    onPressed: _handleDislike,
                                    icon: Icon(
                                      isDisliked // Change icon based on state
                                          ? Icons.thumb_down // Filled icon
                                          : Icons.thumb_down_outlined, // Outlined icon
                                      color: isDisliked // Change icon color
                                          ? Colors.white
                                          : const Color(0xFFFF5722),
                                      size: 25,
                                    ),
                                    padding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),

                              // Like button
                              ScaleTransition(
                                scale: _likeAnimation,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isLiked
                                        ? const Color(0xFFFF5722)
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    onPressed: _toggleLike,
                                    icon: Icon(
                                      isLiked
                                          ? Icons.thumb_up
                                          : Icons.thumb_up_outlined,
                                      color: isLiked
                                          ? Colors.white
                                          : const Color(0xFFFF5722),
                                      size: 25,
                                    ),
                                    padding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}