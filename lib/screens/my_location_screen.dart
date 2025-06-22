import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_food_v1/services/location_service.dart';
import 'package:http/http.dart' as http; // Import the http package
import 'dart:convert'; // Import for jsonDecode
import 'package:flutter_dotenv/flutter_dotenv.dart';

// To run this code
// cd django_project
// python manage.py runserver 0.0.0.0:8000

class MyLocationScreen extends StatefulWidget {
  const MyLocationScreen({super.key});

  @override
  State<MyLocationScreen> createState() => _MyLocationScreenState();
}

class _MyLocationScreenState extends State<MyLocationScreen> {
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  String? _locationErrorMessage;
  bool _isLoadingLocation = false;
  final String radius = dotenv.env['SEARCH_RADIUS'] ?? '5000'; // fallback to 10000 if not set

  // State variables for API interaction
  String? _apiErrorMessage;
  bool _isFetchingRestaurants = false;
  List<dynamic> _restaurants = []; // To store parsed restaurant data

  Future<void> _fetchCurrentLocationAndRestaurants() async {
    debugPrint("MyLocationScreen: _fetchCurrentLocationAndRestaurants called.");
    setState(() {
      _isLoadingLocation = true;
      _locationErrorMessage = null;
      _isFetchingRestaurants = false; 
      _apiErrorMessage = null;
      _restaurants = [];
    });

    try {
      debugPrint("MyLocationScreen: Calling _locationService.getCurrentLocation().");
      final position = await _locationService.getCurrentLocation();
      debugPrint("MyLocationScreen: _locationService.getCurrentLocation() returned: $position");
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
      debugPrint("MyLocationScreen: State updated with position: $_currentPosition");

      if (_currentPosition != null) {
        await _fetchRestaurantsFromApi(_currentPosition!);
      }
    } catch (e) {
      debugPrint("MyLocationScreen: Error caught in _fetchCurrentLocation: $e");
      setState(() {
        _locationErrorMessage = e.toString();
        _isLoadingLocation = false;
        _currentPosition = null;
      });
      debugPrint("MyLocationScreen: State updated with location error message: $_locationErrorMessage");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _fetchRestaurantsFromApi(Position position) async {
    setState(() {
      _isFetchingRestaurants = true;
      _apiErrorMessage = null;
      _restaurants = [];
    });

    // Use your actual machine's IP address if testing on a physical device connected to the same Wi-Fi.
    // For Android emulator, 10.0.2.2 usually points to the host machine.
    // For iOS simulator, localhost or 127.0.0.1 should work.
    // Ensure your Django server is running and accessible from your device/emulator.
    final String apiUrl = 'http://192.168.0.4:8000/recommender/get_restaurants/';
    final Uri uri = Uri.parse(apiUrl).replace(queryParameters: {
      'latitude': position.latitude.toString(),
      'longitude': position.longitude.toString(),
      'radius': radius, // Or any other radius you prefer
    });

    debugPrint("MyLocationScreen: Calling API: $uri");

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 30)); // Added timeout

      debugPrint("MyLocationScreen: API response status: ${response.statusCode}");
      // debugPrint("MyLocationScreen: API response body: ${response.body}"); // Be careful logging large bodies

      if (response.statusCode == 200) {
        try {
          final decodedResponse = jsonDecode(response.body);
          if (decodedResponse is List) {
             setState(() {
              _restaurants = decodedResponse;
              _isFetchingRestaurants = false;
            });
            debugPrint("MyLocationScreen: Successfully fetched and parsed ${_restaurants.length} restaurants.");
          } else if (decodedResponse is Map && decodedResponse.containsKey('restaurants') && decodedResponse['restaurants'] is List) {
            // Handle if API wraps list in a map: { "restaurants": [...] }
            setState(() {
              _restaurants = decodedResponse['restaurants'];
              _isFetchingRestaurants = false;
            });
            debugPrint("MyLocationScreen: Successfully fetched and parsed ${_restaurants.length} restaurants from nested structure.");
          }
          
          else {
            throw Exception("API response is not a List as expected.");
          }

        } catch (e) {
          debugPrint("MyLocationScreen: Failed to parse JSON from API: $e");
          debugPrint("MyLocationScreen: API response body was: ${response.body}");
          setState(() {
            _apiErrorMessage = "Failed to parse restaurant data: $e\nResponse was: ${response.body.substring(0, (response.body.length > 500) ? 500 : response.body.length )}..."; // Show truncated body
            _isFetchingRestaurants = false;
            _restaurants = [];
          });
        }
      } else {
        debugPrint("MyLocationScreen: API request failed with status ${response.statusCode}: ${response.body}");
        setState(() {
          _apiErrorMessage = "API Error ${response.statusCode}: Failed to fetch restaurants.\n${response.body.substring(0, (response.body.length > 500) ? 500 : response.body.length )}..."; // Show truncated body
          _isFetchingRestaurants = false;
          _restaurants = [];
        });
      }
    } catch (e) {
      debugPrint("MyLocationScreen: Error calling API: $e");
      setState(() {
        _apiErrorMessage = "Exception while fetching restaurants: $e";
        _isFetchingRestaurants = false;
        _restaurants = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Location & Restaurants'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_isLoadingLocation)
                const Column(
                  children: [
                    Text("Fetching location..."),
                    CircularProgressIndicator(),
                  ],
                )
              else if (_currentPosition != null)
                Text(
                  'Latitude: ${_currentPosition!.latitude}\n'
                  'Longitude: ${_currentPosition!.longitude}\n'
                  'Accuracy: ${_currentPosition!.accuracy} meters',
                  textAlign: TextAlign.center,
                )
              else if (_locationErrorMessage != null)
                Text(
                  'Location Error: $_locationErrorMessage',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                )
              else
                const Text(
                  'Press the button to get your location and restaurants.',
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: (_isLoadingLocation || _isFetchingRestaurants) ? null : _fetchCurrentLocationAndRestaurants,
                child: const Text('Get Location & Restaurants'),
              ),
              const SizedBox(height: 30),
              if (_isFetchingRestaurants)
                const Column(
                  children: [
                    Text("Fetching restaurants from API..."), // Updated text
                    CircularProgressIndicator(),
                  ],
                )
              else if (_apiErrorMessage != null) // Changed from _pythonScriptError
                Column(
                  children: [
                    const Text("API Error:", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    Text(
                      _apiErrorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.left,
                    ),
                  ],
                )
              else if (_restaurants.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Found ${_restaurants.length} Restaurants:", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(), // To disable ListView's own scrolling
                      itemCount: _restaurants.length,
                      itemBuilder: (context, index) {
                        final restaurant = _restaurants[index];
                        // Basic display, assuming restaurant is a Map with 'name' and 'vicinity'
                        // You'll need to adjust this based on your actual API response structure
                        final name = restaurant['name'] ?? 'N/A';
                        final vicinity = restaurant['address'] ?? 'N/A';
                        final rating = restaurant['rating']?.toString() ?? 'N/A';
                        final userRatingsTotal = restaurant['user_ratings_total']?.toString() ?? 'N/A';
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(name),
                            subtitle: Text('Address: $vicinity\nRating: $rating ($userRatingsTotal reviews)'),
                            isThreeLine: true,
                            // You can add more details or onTap functionality here
                          ),
                        );
                      },
                    ),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }
}
