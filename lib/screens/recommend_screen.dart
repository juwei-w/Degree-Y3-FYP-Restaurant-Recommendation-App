import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../widgets/loading_dialog.dart'; // <-- Import the global loading dialog helper
import 'view_restaurant_screen.dart';

class RecommendScreen extends StatefulWidget {
  final List<Map<String, dynamic>> restaurants;
  final User user;

  const RecommendScreen({Key? key, required this.restaurants, required this.user})
      : super(key: key);

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

  Offset _dragOffset = Offset.zero;

  List<Map<String, dynamic>> _recommendedRestaurants = [];
  String? _error;

  int currentIndex = 0;
  final Map<String, String> _interactionStates = {};
  Map<String, dynamic>? _userProfile;

  bool _hasFetchedRecommendations = false;

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasFetchedRecommendations) {
      _hasFetchedRecommendations = true;
      _fetchHybridRecommendations();
    }
  }

  void _safeShowLoadingDialog(BuildContext context, {String? message}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showLoadingDialog(context, message: message);
    });
  }

  void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LoadingDialog(message: message),
    );
  }

  void hideLoadingDialog(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  dynamic _convertTimestamps(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    if (value is Map<String, dynamic>) {
      return value.map((key, val) => MapEntry(key, _convertTimestamps(val)));
    }
    if (value is List) {
      return value.map((item) => _convertTimestamps(item)).toList();
    }
    return value;
  }

  Future<void> _fetchHybridRecommendations() async {
    final user = widget.user;

    if (widget.restaurants.isEmpty) {
      setState(() {
        _error = "No restaurants available for recommendations.";
      });
      return;
    }

    _safeShowLoadingDialog(context, message: "Fetching recommendations...");
    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception("User profile not found in Firestore for UID: ${user.uid}");
      }
      final userProfileData = userQuery.docs.first.data();
      _userProfile = userProfileData;
      final encodableUserProfile = _convertTimestamps(userProfileData);

      final String? baseUrl = dotenv.env['API_BASE_URL'];
      if (baseUrl == null) {
        throw Exception("API_BASE_URL not found in .env file");
      }
      final url = Uri.parse('$baseUrl/recommender/hybrid_recommendations/');

      final requestBody = json.encode({
        'restaurants': widget.restaurants,
        'user_profile': encodableUserProfile,
      });

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          )
          .timeout(const Duration(seconds: 60));

      if (mounted) {
        if (response.statusCode == 200) {
          final List<dynamic> jsonData = json.decode(response.body);
          setState(() {
            _recommendedRestaurants = jsonData
                .map((item) => item as Map<String, dynamic>)
                .where((r) => r['place_id'] != null && r['place_id'] is String)
                .toList();
            _error = null;
          });
        } else {
          setState(() {
            _error =
                "Error: Could not fetch recommendations (${response.statusCode}). Server response: ${response.body}";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "An error occurred: $e";
        });
      }
    } finally {
      hideLoadingDialog(context);
    }
  }

  Future<void> _sendFeedback(Map<String, dynamic> restaurant, String action) async {
    final String? apiUrl = dotenv.env['API_BASE_URL'];
    if (apiUrl == null) {
      debugPrint('[FEEDBACK ERROR] API_BASE_URL not found in .env file.');
      return;
    }

    final url = Uri.parse('$apiUrl/recommender/record_feedback/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.user.uid,
          'restaurant_data': restaurant,
          'action': action,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Feedback ($action) sent successfully for ${restaurant['name']}');
      } else {
        debugPrint('Failed to send feedback. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending feedback: $e');
    }
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _dislikeAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  void _toggleLike() {
    final restaurant = _recommendedRestaurants[currentIndex];
    final restaurantId = restaurant['place_id'] as String;
    bool wasLiked = _interactionStates[restaurantId] == 'liked';

    setState(() {
      if (wasLiked) {
        _interactionStates.remove(restaurantId);
        isLiked = false;
      } else {
        _interactionStates[restaurantId] = 'liked';
        isLiked = true;
        isDisliked = false;
        _sendFeedback(restaurant, 'like');
      }
    });
    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reverse();
      if (!wasLiked && isLiked && currentIndex < _recommendedRestaurants.length - 1) {
        _animateSwipe(isSwipeUp: true, sendFeedback: false);
      }
    });
  }

  void _toggleDislike() {
    final restaurant = _recommendedRestaurants[currentIndex];
    final restaurantId = restaurant['place_id'] as String;
    bool wasDisliked = _interactionStates[restaurantId] == 'disliked';

    setState(() {
      if (wasDisliked) {
        _interactionStates.remove(restaurantId);
        isDisliked = false;
      } else {
        _interactionStates[restaurantId] = 'disliked';
        isDisliked = true;
        isLiked = false;
        _sendFeedback(restaurant, 'dislike');
      }
    });

    _dislikeAnimationController.forward().then((_) {
      _dislikeAnimationController.reverse();
      if (!wasDisliked && isDisliked && currentIndex < _recommendedRestaurants.length - 1) {
        _animateSwipe(isSwipeUp: true, sendFeedback: false);
      }
    });
  }

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

  void _animateSwipe({required bool isSwipeUp, bool sendFeedback = true}) {
    final restaurant = _recommendedRestaurants[currentIndex];
    final restaurantId = restaurant['place_id'] as String;

    if (isSwipeUp && sendFeedback && !_interactionStates.containsKey(restaurantId)) {
      _sendFeedback(restaurant, 'skip');
      setState(() {
        _interactionStates[restaurantId] = 'skipped';
      });
    }

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
      setState(() {
        if (isSwipeUp) {
          if (currentIndex < _recommendedRestaurants.length - 1) {
            currentIndex++;
          }
        } else {
          if (currentIndex > 0) {
            currentIndex--;
          }
        }
        final newRestaurantId = _recommendedRestaurants[currentIndex]['place_id'] as String;
        final previousState = _interactionStates[newRestaurantId] ?? 'none';
        isLiked = previousState == 'liked';
        isDisliked = previousState == 'disliked';
        _dragOffset = Offset.zero;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Handle error state
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Error"),
          backgroundColor: const Color(0xFFFF7B54),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    // Show mockup card while loading recommendations
    if (_recommendedRestaurants.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Recommendations"),
          backgroundColor: const Color(0xFFFF7B54),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFF6B47),
                Color(0xFFFFB5A3),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    height: 270,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withOpacity(0.3),
                    ),
                    child: const Center(
                      child: Icon(Icons.restaurant, size: 80, color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 120,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 80,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.only(bottom: 32.0),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final restaurant = _recommendedRestaurants[currentIndex];

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
        onVerticalDragStart: (details) {
          _cardAnimationController.stop();
        },
        onVerticalDragUpdate: (details) {
          setState(() {
            _dragOffset += details.delta;
          });
        },
        onVerticalDragEnd: (details) {
          final screenHeight = MediaQuery.of(context).size.height;
          final isFirstCard = currentIndex == 0;
          final isLastCard = currentIndex == _recommendedRestaurants.length - 1;

          if ((details.primaryVelocity! < -500 ||
                  _dragOffset.dy < -screenHeight / 4) &&
              !isLastCard) {
            _animateSwipe(isSwipeUp: true);
          } else if ((details.primaryVelocity! > 500 ||
                  _dragOffset.dy > screenHeight / 4) &&
              !isFirstCard) {
            _animateSwipe(isSwipeUp: false);
          } else {
            _animateSnapBack();
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFF6B47),
                Color(0xFFFFB5A3),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
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
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (restaurant.containsKey('final_score'))
                            Text(
                              'Hybrid: ${restaurant['final_score'].toStringAsFixed(4)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (restaurant.containsKey('final_score_with_rl'))
                            Text(
                              'RL: ${restaurant['final_score_with_rl'].toStringAsFixed(4)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Transform.translate(
                    offset: _dragOffset,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Container(
                              height: 270,
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
                                          return Image.asset('assets/images/tacos.png', fit: BoxFit.cover);
                                        },
                                      )
                                    : Image.asset('assets/images/tacos.png', fit: BoxFit.cover),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            restaurant['name'],
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${restaurant['rating'] ?? 'N/A'} (${restaurant['user_ratings_total'] ?? 0})',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
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

                              if (priceRangeText == null) {
                                return const SizedBox.shrink();
                              }

                              return Text(
                                'Price: $priceRangeText',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 70,
                            ),
                            child: SingleChildScrollView(
                              child: Center(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
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
                                                fontSize: 12,
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
                          Container(
                            width: double.infinity,
                            height: 44,
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            child: ElevatedButton(
                              onPressed: () {
                                final restaurant = _recommendedRestaurants[currentIndex];
                                final restaurantId = restaurant['place_id'] as String;

                                _sendFeedback(restaurant, 'click_details');

                                setState(() {
                                  _interactionStates[restaurantId] = 'viewed';
                                });

                                final List<dynamic> favorites = _userProfile?['favorites'] as List<dynamic>? ?? [];
                                final bool isFavourite = favorites.contains(restaurant['place_id']);

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ViewRestaurantScreen(
                                      restaurant: restaurant,
                                      isFavourite: isFavourite,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6B47),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ScaleTransition(
                                scale: _dislikeAnimation,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDisliked
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
                                    onPressed: _toggleDislike,
                                    icon: Icon(
                                      isDisliked
                                          ? Icons.thumb_down
                                          : Icons.thumb_down_outlined,
                                      color: isDisliked
                                          ? Colors.white
                                          : const Color(0xFFFF5722),
                                      size: 25,
                                    ),
                                    padding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
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