import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'review_screen.dart';
// Add this import to access environment variables for the API key
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewRestaurantScreen extends StatefulWidget {
  final Map<String, dynamic> restaurant;
  final bool isFavourite;
  const ViewRestaurantScreen({
    Key? key,
    required this.restaurant,
    required this.isFavourite,
  }) : super(key: key);

  @override
  State<ViewRestaurantScreen> createState() => _ViewRestaurantScreenState();
}

class _ViewRestaurantScreenState extends State<ViewRestaurantScreen> {
  late bool isFavorite;

  @override
  void initState() {
    super.initState();
    // Initialize the local favorite state from the property passed to the widget
    isFavorite = widget.isFavourite;
  }

  /// Toggles the favourite status of the current restaurant in Firestore.
  Future<void> _toggleFavourite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final restaurantData = widget.restaurant;

    // Use the current state of `isFavorite` to decide which action to take
    if (isFavorite) {
      // If the restaurant is currently a favorite, remove it.
      await userDoc.set({
        'favourites': FieldValue.arrayRemove([restaurantData])
      }, SetOptions(merge: true));
    } else {
      // If the restaurant is not a favorite, add it.
      await userDoc.set({
        'favourites': FieldValue.arrayUnion([restaurantData])
      }, SetOptions(merge: true));
    }

    // After the database operation is complete, update the UI.
    // The `mounted` check ensures setState is not called after the widget is disposed.
    if (mounted) {
      setState(() {
        isFavorite = !isFavorite;
      });
    }
  }
  
  // Assume _launchURL is defined in your state class like this:
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $urlString'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    }
  }

  /// Launches WhatsApp with the restaurant's phone number and a preset booking message.
  Future<void> _launchWhatsApp() async {
    final String? phoneNumber = widget.restaurant['phone_number'] as String?;

    // Check for null, empty, or "N/A"
    if (phoneNumber == null || phoneNumber.isEmpty || phoneNumber.toUpperCase() == 'N/A') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No available phone number'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
      return;
    }

    String formattedNumber = phoneNumber.replaceAll(RegExp(r'\\D'), '');
    if (formattedNumber.startsWith('0')) {
      formattedNumber = '60${formattedNumber.substring(1)}'; // Malaysia country code
    }

    // Prepare preset message: "Hi, I would like to book a table at [restaurant name] for [time]."
    final String restaurantName = widget.restaurant['name'] ?? 'your restaurant';
    final DateTime now = DateTime.now();
    final DateTime bookingTime = now.add(const Duration(hours: 1));
    // Format time as 12-hour with AM/PM
    final int hour = bookingTime.hour % 12 == 0 ? 12 : bookingTime.hour % 12;
    final String minute = bookingTime.minute.toString().padLeft(2, '0');
    final String period = bookingTime.hour >= 12 ? 'PM' : 'AM';
    final String formattedTime = "$hour:$minute $period";
    final String message = "Hi, I would like to book a table at $restaurantName for $formattedTime.";
    final String encodedMessage = Uri.encodeComponent(message);

    final String whatsappUrl = 'https://wa.me/$formattedNumber?text=$encodedMessage';
    final String telUrl = 'tel:$phoneNumber';

    try {
      final Uri waUri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(waUri)) {
        final bool launched = await launchUrl(waUri);
        if (!launched) {
          // WhatsApp not available, fallback to phone call
          final Uri telUri = Uri.parse(telUrl);
          await launchUrl(telUri);
        }
      } else {
        // WhatsApp not available, fallback to phone call
        final Uri telUri = Uri.parse(telUrl);
        await launchUrl(telUri);
      }
    } catch (e) {
      // On any error, fallback to phone call
      final Uri telUri = Uri.parse(telUrl);
      await launchUrl(telUri);
    }
  }

  // Add this helper to your state class:
  Future<void> _launchPhoneIfAvailable(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty || phoneNumber.toUpperCase() == 'N/A') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No available phone number'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
      return;
    }
    await _launchURL('tel:$phoneNumber');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add padding around the image header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
              child: _buildImageHeader(),
            ),
            // Restaurant details
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant name
                  Text(
                    widget.restaurant['name'] ?? 'Taco Bell Cyberjaya',
                    style: const TextStyle(
                      fontFamily: 'SofiaSans',
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Opening status widget ---
                  _buildOpeningStatus(),
                  const SizedBox(height: 4),
                  // Rating and reviews
                  _buildRatingSection(),
                  const SizedBox(height: 4),
                  // Price level section
                  _buildPriceLevelSection(widget.restaurant),
                  const SizedBox(height: 12),
                  // Category tags
                  _buildCategoryTags(),
                  const SizedBox(height: 20),
                  // Restaurant info
                  _buildRestaurantInfo(widget.restaurant),
                  const SizedBox(height: 20),
                  // Place the action buttons here instead of bottomNavigationBar
                  _buildBottomActions(),
                ],
              ),
            ),
          ],
        ),
      ),
      // Remove: bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildImageHeader() {
    String? photoUrl;
    // Get the Google Maps API key from your environment variables.
    final String? apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

    // This logic now matches the working implementation from your home screen.
    // It checks for a list of photo references from the backend.
    if (widget.restaurant['photos'] != null &&
        widget.restaurant['photos'] is List &&
        (widget.restaurant['photos'] as List).isNotEmpty) {
      
      // Get the photo reference string from the first item in the list.
      final photoRef = widget.restaurant['photos'][0];

      // Construct the full Google Maps Photo API URL if we have a reference and a key.
      if (photoRef != null && apiKey != null) {
        photoUrl =
            'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoRef&key=$apiKey';
      }
    }
    
    // Define the fallback local image asset.
    final String fallbackImageAsset = 'assets/images/tacos.png';

    return Stack(
      children: [
        // Restaurant image
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[200], // Background color while loading
            child: (photoUrl != null)
                // If a photo URL was successfully constructed, display it from the network.
                ? Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    height: 200,
                    width: double.infinity,
                    // Show a loading indicator while the image is downloading.
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    // If the network image fails to load, show the fallback asset.
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        fallbackImageAsset,
                        fit: BoxFit.cover,
                        height: 200,
                        width: double.infinity,
                      );
                    },
                  )
                // If no photo URL could be constructed, display the fallback local asset directly.
                : Image.asset(
                    fallbackImageAsset,
                    fit: BoxFit.cover,
                    height: 200,
                    width: double.infinity,
                  ),
          ),
        ),

        // Back button
        Positioned(
          top: 16,
          left: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 22, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOpeningStatus() {
    String openingStatusText = '';
    Color openingStatusIconColor = Colors.grey;
    bool statusAvailable = false;

    // Check for 'opening_status' key and its value, as per home page logic
    if (widget.restaurant.containsKey('opening_status') &&
        widget.restaurant['opening_status'] is bool) {
      statusAvailable = true;
      if (widget.restaurant['opening_status'] == true) {
        openingStatusText = 'Open';
        openingStatusIconColor = Colors.green; // Color from home page style
      } else {
        openingStatusText = 'Closed';
        openingStatusIconColor = Colors.red.shade300; // Color from home page style
      }
    }

    // If no valid status, return an empty widget
    if (!statusAvailable) {
      return const SizedBox.shrink();
    }

    // Build the Row widget to match the home page style
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Add some padding around the section
      child: Row(
        // mainAxisSize: MainAxisSize.min, // REMOVED: This was preventing the Padding from being effective.
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF7F59).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.access_time_filled,
              color: openingStatusIconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            openingStatusText,
            style: TextStyle(
              fontFamily: 'SofiaSans',
              fontSize: 16,
              color: openingStatusIconColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    final dynamic numRatings = widget.restaurant['number_of_ratings'] ?? widget.restaurant['user_ratings_total'];

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF7F59).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.star,
            color: Colors.amber,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${widget.restaurant['rating'] ?? 4.5}',
          style: const TextStyle(
            fontFamily: 'SofiaSans',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        if (numRatings != null)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              '(${numRatings is int ? numRatings : numRatings.toInt()} ratings)', // Displays (489 ratings)
              style: TextStyle(fontFamily: 'SofiaSans', fontSize: 15, color: Colors.grey[600]),
            ),
          ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () {
            _navigateToReviewPage(context, widget.restaurant['name'] ?? 'Taco Bell Cyberjaya');
          },
          child: const Text(
            'See Review',
            style: TextStyle(
              fontFamily: 'SofiaSans',
              fontSize: 16,
              color: Color(0xFFFF7F59),
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFFFF7F59),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceLevelSection(Map<String, dynamic> restaurant) {
    String priceRangeText = "Price not available"; // Default text
    final dynamic priceLevelData = restaurant['price_level'];

    if (priceLevelData != null) {
      if (priceLevelData is int) {
        // Map integer price level to estimated RM ranges
        switch (priceLevelData) {
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
          default:
            priceRangeText = 'Price info unknown'; 
        }
      } 
      else if (priceLevelData is String && priceLevelData.toLowerCase() == "n/a") {
        priceRangeText = "N/A";
      } 
    } else {
        return SizedBox.shrink(); // Don't show the section if no price level data
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Add some padding around the section
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7F59).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon( // Added money icon
                Icons.attach_money, // Standard money icon
                color: const Color(0xFFFF7F59), // Match text color
                size: 20, // Adjust size as per Figma design
              ),
          ),
          const SizedBox(width: 8), // Spacing between icon and text
          Text(
            priceRangeText, // Display the determined RM range
            style: TextStyle(
              fontFamily: 'SofiaSans',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF7F59), // Color from your example
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryTags() {
    // Ensure 'categories' is a List<String> for type safety with Text widget
    final List<dynamic> rawCategories = widget.restaurant['categories'] ?? ['HALAL', 'VEGETARIAN', 'FAST FOOD'];
    final List<String> categories = rawCategories.map((category) => category.toString()).toList();
    
    if (categories.isEmpty) {
      return SizedBox.shrink(); // Don't display anything if there are no categories
    }

    return Wrap( // Changed Row to Wrap
      spacing: 12.0, // Horizontal space between tags (replaces right margin)
      runSpacing: 8.0, // Vertical space between lines of tags (adjust as per Figma)
      children: categories.map<Widget>((category) {
        return Container(
          // margin: const EdgeInsets.only(right: 12), // Margin is now handled by Wrap's spacing
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[200], // As per Figma, or use theme color if specified
            borderRadius: BorderRadius.circular(20), // Consistent with Figma
          ),
          child: Text(
            category.toUpperCase(), // Display categories in uppercase as per common tag styling
            style: TextStyle(
              fontFamily: 'SofiaSans', // Ensure this font is in your assets and pubspec.yaml
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700], // As per Figma, or use theme color
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRestaurantInfo(Map<String, dynamic> restaurant) {
    // Extract data from the restaurant map with fallbacks
    final String address = restaurant['address'] ?? 'Address not available';
    
    String openingHoursText = 'Opening hours not available'; // Default
    final dynamic openingHoursData = restaurant['opening_hours'];

    // Handle both Map (from Google Places) and List (from backend) formats
    if (openingHoursData != null) {
      if (openingHoursData is Map && openingHoursData['weekday_text'] is List) {
        final List<dynamic> hoursListRaw = openingHoursData['weekday_text'];
        openingHoursText = hoursListRaw.map((item) => item.toString()).join('\n');
      } else if (openingHoursData is List && openingHoursData.isNotEmpty) {
        try {
          final List<String> hoursList = openingHoursData.map((item) => item.toString()).toList();
          openingHoursText = hoursList.join('\n');
        } catch (e) {
          openingHoursText = 'Error displaying opening hours';
        }
      }
    }

    final String? website = restaurant['website'] as String?;
    final String? phoneNumber = restaurant['phone_number'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Address
        _buildInfoRow(
          Icons.location_on,
          address,
        ),
        
        const SizedBox(height: 20),
        
        // Opening hours
        _buildInfoRow(
          Icons.access_time,
          openingHoursText, // This will now display all opening hours, each on a new line
        ),
        
        const SizedBox(height: 20),
        
        // Website
        if (website != null && website.isNotEmpty) ...[
          _buildInfoRow(
            Icons.language,
            website,
            isClickable: true,
            onTap: () => _launchURL(website),
          ),
          const SizedBox(height: 20),
        ],
        
        // Phone
        if (phoneNumber != null && phoneNumber.isNotEmpty) ...[
          _buildInfoRow(
            Icons.phone,
            phoneNumber,
            isClickable: true,
            onTap: () => _launchPhoneIfAvailable(phoneNumber),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isClickable = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF7F59).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFF7F59),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          // Make the text expand and wrap
          Expanded(
            child: Container(
              // height: 36,
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'SofiaSans',
                  fontSize: 14,
                  color: isClickable ? const Color(0xFFFF7F59) : Colors.grey[700],
                  decoration: isClickable ? TextDecoration.underline : null,
                  decorationColor: isClickable ? const Color(0xFFFF7F59) : null,
                ),
                maxLines: null, // Allow unlimited lines
                overflow: TextOverflow.visible,
                softWrap: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // WhatsApp/Phone button
            _buildPngActionButton(
              assetPath: 'assets/images/view_whatsapp.png',
              onTap: _launchWhatsApp,
            ),
            // Favourite button (toggle)
            _buildPngActionButton(
              assetPath: isFavorite
                  ? 'assets/images/view_favourite.png'
                  : 'assets/images/view_unfavourite.png',
              onTap: () {
                // Call the function to handle the database logic and state change.
                _toggleFavourite();
              },
              isActive: isFavorite,
            ),
            // Navigation button
            _buildPngActionButton(
              assetPath: 'assets/images/view_navigate.png',
              onTap: () {
                final String? address = widget.restaurant['address'];
                final String? name = widget.restaurant['name'];
                final String? mapsUrl = widget.restaurant['maps_url'] ?? widget.restaurant['url'];
                String urlString;

                if (mapsUrl != null && mapsUrl.isNotEmpty) {
                  urlString = mapsUrl;
                } else if (address != null && address.isNotEmpty) {
                  // Use the Google Maps driving directions format with double slash
                  final destination = Uri.encodeComponent('${name ?? ''}, $address');
                  urlString = 'https://www.google.com/maps/dir//$destination?travelmode=driving';
                } else {
                  // Fallback: open Google Maps
                  urlString = 'https://maps.google.com/';
                }

                _launchURL(urlString);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPngActionButton({
    required String assetPath,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF7F59).withOpacity(0.18), // Lowered opacity from 0.45 to 0.18
              blurRadius: 32,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFFF7F59) : Colors.white,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Image.asset(
              assetPath,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToReviewPage(BuildContext context, String restaurantName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(
          restaurant: widget.restaurant, // Pass the full restaurant data
        ),
      ),
    );
  }
}