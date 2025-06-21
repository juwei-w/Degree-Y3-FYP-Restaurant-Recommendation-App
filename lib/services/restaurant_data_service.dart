import 'dart:convert';
import 'package:flutter/services.dart';

/// A simple service to load and cache restaurant data from the local JSON asset.
/// This ensures the data is loaded only once per app session.
class RestaurantDataService {
  // Private constructor
  RestaurantDataService._();

  // The single, static instance of the service
  static final instance = RestaurantDataService._();

  List<Map<String, dynamic>> _restaurants = [];
  bool _hasLoaded = false;

  /// Returns the cached list of restaurants.
  List<Map<String, dynamic>> get restaurants => _restaurants;

  /// Loads restaurants from the asset file if they haven't been loaded yet.
  Future<void> loadRestaurants() async {
    if (_hasLoaded) {
      return; // Data is already loaded, do nothing.
    }

    try {
      final String jsonString =
          await rootBundle.loadString('assets/restaurant_data/django_data_2.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      _restaurants = jsonData
          .where((item) => item is Map<String, dynamic> && item['name'] != null)
          .map<Map<String, dynamic>>((item) => item as Map<String, dynamic>)
          .toList();
      _hasLoaded = true;
    } catch (e) {
      // Handle potential errors during file loading or parsing
      print("Error loading restaurant data: $e");
      _restaurants = []; // Ensure list is empty on error
    }
  }
}