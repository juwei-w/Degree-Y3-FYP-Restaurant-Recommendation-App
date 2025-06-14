import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'review_screen.dart';

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
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.restaurant['isFavorite'] ?? false;
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
                  const SizedBox(height: 12),
                  // Rating and reviews
                  _buildRatingSection(),
                  const SizedBox(height: 16),
                  // Price level section
                  _buildPriceLevelSection(widget.restaurant),
                  const SizedBox(height: 16),
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
    return Stack(
      children: [
        // Restaurant image
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: AssetImage(widget.restaurant['image'] ?? 'assets/images/tacos.png'),
              fit: BoxFit.cover,
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

  Widget _buildRatingSection() {
    final dynamic numRatings = widget.restaurant['number_of_ratings'] ?? widget.restaurant['user_ratings_total'];

    return Row(
      children: [
        const Icon(
          Icons.star,
          color: Colors.amber,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          '${widget.restaurant['rating'] ?? 4.5}',
          style: const TextStyle(
            fontFamily: 'SofiaSans',
            fontSize: 18,
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
              fontSize: 20,
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

    if (openingHoursData != null && openingHoursData is List && openingHoursData.isNotEmpty) {
      // Check if the list contains strings
      try {
        final List<String> hoursList = openingHoursData.map((item) => item.toString()).toList();
        openingHoursText = hoursList.join('\n');
      } catch (e) {
        openingHoursText = 'Error displaying opening hours';
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
            onTap: () => _launchURL('tel:$phoneNumber'),
          ),
          // No SizedBox needed after the last item if it's conditional
        ],
      ],
    );
  }

  // Assume _launchURL is defined in your state class like this:
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
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
      // padding: const EdgeInsets.symmetric(vertical: 16),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // WhatsApp/Phone button
            _buildPngActionButton(
              assetPath: 'assets/images/view_whatsapp.png',
              onTap: () => _launchURL('tel:0382130100'),
            ),
            // Favourite button (toggle)
            _buildPngActionButton(
              assetPath: isFavorite
                  ? 'assets/images/view_favourite.png'
                  : 'assets/images/view_unfavourite.png',
              onTap: () {
                setState(() {
                  isFavorite = !isFavorite;
                });
              },
              isActive: isFavorite,
            ),
            // Navigation button
            _buildPngActionButton(
              assetPath: 'assets/images/view_navigate.png',
              onTap: () => _launchURL('https://maps.google.com/?q=Taco+Bell+Cyberjaya'),
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
          restaurantName: restaurantName,
        ),
      ),
    );
  }
}