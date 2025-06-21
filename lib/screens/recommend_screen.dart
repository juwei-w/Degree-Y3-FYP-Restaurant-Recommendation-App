import 'package:flutter/material.dart';
// Add this import to access your API key for photo URLs
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RecommendScreen extends StatefulWidget {
  // Add a field to hold the list of restaurants passed from another screen.
  final List<Map<String, dynamic>> restaurants;

  // Update the constructor to require this list.
  const RecommendScreen({Key? key, required this.restaurants}) : super(key: key);

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
  // Remove: late Animation<Offset> _cardSlideAnimation;

  // Add a state variable to track the card's drag offset.
  Offset _dragOffset = Offset.zero;

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
      // Adjust duration for swipe/snap animations
      duration: const Duration(milliseconds: 300),
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

    // Remove: _cardSlideAnimation initialization
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
        // Trigger the swipe up animation instead of calling the old method.
        _animateSwipe(isSwipeUp: true);
      }
    });
  }

  // The _nextRestaurant and _previousRestaurant methods are no longer needed,
  // as this logic is now handled by the gesture handlers and _animateSwipe.

  /// Animates the card back to its original centered position.
  void _animateSnapBack() {
    final animation = Tween<Offset>(begin: _dragOffset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardAnimationController, curve: Curves.easeOut));

    animation.addListener(() {
      setState(() {
        _dragOffset = animation.value;
      });
    });

    _cardAnimationController.reset();
    _cardAnimationController.forward();
  }

  /// Animates the card off-screen and loads the next/previous card.
  void _animateSwipe({required bool isSwipeUp}) {
    final screenHeight = MediaQuery.of(context).size.height;
    final endOffset = Offset(0, isSwipeUp ? -screenHeight : screenHeight);

    final animation = Tween<Offset>(begin: _dragOffset, end: endOffset)
        .animate(CurvedAnimation(parent: _cardAnimationController, curve: Curves.easeIn));

    animation.addListener(() {
      setState(() {
        _dragOffset = animation.value;
      });
    });

    _cardAnimationController.reset();
    _cardAnimationController.forward().then((_) {
      // After swipe animation is complete, update the card index
      setState(() {
        if (isSwipeUp) {
          if (currentIndex < widget.restaurants.length - 1) {
            currentIndex++;
          }
        } else {
          if (currentIndex > 0) {
            currentIndex--;
          }
        }
        // Reset state for the new card
        _dragOffset = Offset.zero;
        isLiked = false;
        isDisliked = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Handle the case where no restaurants are passed in.
    if (widget.restaurants.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Recommendations"),
          backgroundColor: const Color(0xFFFF7B54),
        ),
        body: const Center(
          child: Text("No restaurants to recommend."),
        ),
      );
    }

    // Get the current restaurant from the passed-in list.
    final restaurant = widget.restaurants[currentIndex];

    // Construct the photo URL using the same logic as the home screen.
    String? photoUrl;
    final String? apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (restaurant['photos'] != null &&
        restaurant['photos'] is List &&
        (restaurant['photos'] as List).isNotEmpty) {
      final photoRef = restaurant['photos'][0];
      if (photoRef != null && apiKey != null) {
        photoUrl =
            'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoRef&key=$apiKey';
      }
    }

    return Scaffold(
      body: GestureDetector(
        // Replace onVerticalDragEnd with a full suite of gesture handlers.
        onVerticalDragStart: (details) {
          _cardAnimationController.stop();
        },
        onVerticalDragUpdate: (details) {
          setState(() {
            // Update the offset as the user drags.
            _dragOffset += details.delta;
          });
        },
        onVerticalDragEnd: (details) {
          final screenHeight = MediaQuery.of(context).size.height;
          // Decide whether to swipe away or snap back based on velocity and position.
          if (details.primaryVelocity! < -500 || _dragOffset.dy < -screenHeight / 4) {
            _animateSwipe(isSwipeUp: true); // Swipe up
          } else if (details.primaryVelocity! > 500 || _dragOffset.dy > screenHeight / 4) {
            _animateSwipe(isSwipeUp: false); // Swipe down
          } else {
            _animateSnapBack(); // Return to center
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
                  // Replace SlideTransition with Transform.translate to follow the finger.
                  child: Transform.translate(
                    offset: _dragOffset,
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
                              child: photoUrl != null
                                  ? Image.network(
                                      photoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        // Use the asset image as a fallback on error.
                                        return Image.asset('assets/images/tacos.png', fit: BoxFit.cover);
                                      },
                                    )
                                  // Use the asset image as a fallback if no URL exists.
                                  : Image.asset('assets/images/tacos.png', fit: BoxFit.cover),
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
                            maxLines: 2, // Allow up to two lines for the name
                            overflow: TextOverflow.ellipsis, // Add ... if it overflows
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
                                // Use the correct keys from your API data
                                '${restaurant['rating'] ?? 'N/A'} (${restaurant['user_ratings_total'] ?? 0})',
                                style: const TextStyle(
                                  fontSize: 14, // smaller
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Price range - Updated logic as per your request
                          Builder(
                            builder: (context) {
                              String? priceRangeText;
                              final dynamic priceLevelData = restaurant['price_level'];

                              if (priceLevelData != null) {
                                int? priceLevel;
                                if (priceLevelData is int) {
                                  priceLevel = priceLevelData;
                                } else if (priceLevelData is String) {
                                  if (priceLevelData.toLowerCase() == "n/a") {
                                    priceRangeText = "N/A";
                                  } else {
                                    priceLevel = int.tryParse(priceLevelData);
                                  }
                                }

                                if (priceLevel != null) {
                                  switch (priceLevel) {
                                    case 0:
                                      priceRangeText = 'RM1-RM20';
                                      break;
                                    case 1:
                                      priceRangeText = 'RM20-RM30';
                                      break;
                                    case 2:
                                      priceRangeText = 'RM30-RM50';
                                      break;
                                    case 3:
                                      priceRangeText = 'RM50-RM100';
                                      break;
                                    case 4:
                                      priceRangeText = '>RM100';
                                      break;
                                  }
                                }
                              }

                              // If no valid price text could be determined, show nothing.
                              if (priceRangeText == null) {
                                return const SizedBox.shrink();
                              }

                              return Text(
                                'Price: $priceRangeText',
                                style: const TextStyle(
                                  fontSize: 16, // smaller
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 14),

                          // categories - Constrained to a height of approx. 2 rows and scrollable.
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 70, // Set a max height for about two rows of tags
                            ),
                            child: SingleChildScrollView(
                              child: Center(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  // Use the correct key 'categories' and handle the case where it might be null.
                                  children: (restaurant['categories'] as List<dynamic>? ?? [])
                                      .map<Widget>((category) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.9),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              category,
                                              style: const TextStyle(
                                                color: Colors.black54,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12, // smaller
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ),
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
      )
    );
  }
}