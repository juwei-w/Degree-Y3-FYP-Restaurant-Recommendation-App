import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';

class LocationService {
  /// Determines the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  /// Returns a human-readable address from a given [Position].
  Future<String> getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Construct a readable address
        return "${place.street}, ${place.locality}, ${place.country}";
      } else {
        return "Address not found";
      }
    } catch (e) {
      log('Error getting address from lat/lng: $e', name: 'LocationService');
      return "Error getting address";
    }
  }

  // /// Returns a human-readable address from latitude and longitude.
  // Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
  //   try {
  //     List<Placemark> placemarks = await placemarkFromCoordinates(
  //       latitude,
  //       longitude,
  //     );

  //     if (placemarks.isNotEmpty) {
  //       Placemark place = placemarks[0];
  //       // Construct a readable address
  //       return "${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}";
  //     } else {
  //       return "Address not found";
  //     }
  //   } catch (e) {
  //     log('Error getting address from coordinates: $e', name: 'LocationService');
  //     return "Error getting address";
  //   }
  // }

  // Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
  //   try {
  //     List<Location> locations = await locationFromAddress(address);
  //     if (locations.isNotEmpty) {
  //       return {
  //         'latitude': locations.first.latitude,
  //         'longitude': locations.first.longitude,
  //       };
  //     }
  //   } catch (e) {
  //     log("Error getting coordinates from address: $e", name: 'LocationService');
  //   }
  //   return null;
  // }

  /// Fetches place autocomplete suggestions from Google Places API.
  Future<List<Map<String, String>>> getAutocompleteSuggestions(
      String input, String apiKey) async {
    if (input.trim().isEmpty) {
      return [];
    }
    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          return predictions
              .map((p) => {
                    'description': p['description'] as String,
                    'place_id': p['place_id'] as String,
                  })
              .toList();
        }
      }
    } catch (e) {
      log("Error fetching autocomplete suggestions: $e", name: 'LocationService');
    }
    return [];
  }

  /// Fetches details (including coordinates) for a given place ID.
  Future<Map<String, dynamic>?> getPlaceDetails(
      String placeId, String apiKey) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=formatted_address,geometry&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['result'] != null) {
          final result = data['result'];
          return {
            'address': result['formatted_address'],
            'latitude': result['geometry']['location']['lat'],
            'longitude': result['geometry']['location']['lng'],
          };
        }
      }
    } catch (e) {
      log("Error fetching place details: $e", name: 'LocationService');
    }
    return null;
  }
}
