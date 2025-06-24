import 'dart:convert';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// A service to load restaurant data, either from a local asset or a remote Django backend.
/// This ensures the data is loaded only once per app session.
class RestaurantDataService {
  // Private constructor
  RestaurantDataService._();

  // The single, static instance of the service
  static final instance = RestaurantDataService._();

  List<Map<String, dynamic>> _restaurants = [];

  /// Returns the current cached list of restaurants.
  List<Map<String, dynamic>> getRestaurants() {
    return _restaurants;
  }

  /// Loads restaurants from the Django backend using provided coordinates.
  /// Optionally, it can load from a local asset file if the backend is not available.
  Future<void> loadRestaurants({
    double? latitude,
    double? longitude,
  }) async {
    try {
      final String? baseUrl = dotenv.env['API_BASE_URL'];
      final String? radius = dotenv.env['SEARCH_RADIUS'];

      // If latitude and longitude are provided, fetch from the backend
      if (latitude != null && longitude != null) {
        final url = Uri.parse(
          '$baseUrl/recommender/get_restaurants/?lat=$latitude&lon=$longitude&radius=$radius',
        );

        // Debug log
        log("RestaurantDataService: Calling API: $url");

        final response = await http.get(url).timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          final List<dynamic> jsonData = json.decode(response.body);
          _restaurants = jsonData
              .where((item) => item is Map<String, dynamic> && item['name'] != null)
              .map<Map<String, dynamic>>((item) => item as Map<String, dynamic>)
              .toList();
        } else {
          log('Failed to load restaurants: ${response.statusCode}');
          log('Response body: ${response.body}');
          _restaurants = [];
        }
      } 
      else {
        // If no coordinates are provided, fall back to local asset loading
        final String jsonString =
            await rootBundle.loadString('assets/restaurant_data/django_data_2.json');
        final List<dynamic> jsonData = json.decode(jsonString);
        _restaurants = jsonData
            .where((item) => item is Map<String, dynamic> && item['name'] != null)
            .map<Map<String, dynamic>>((item) => item as Map<String, dynamic>)
            .toList();
      }
    } catch (e) {
      log('An error occurred while fetching restaurants: $e');
      _restaurants = [];
    }
  }
}