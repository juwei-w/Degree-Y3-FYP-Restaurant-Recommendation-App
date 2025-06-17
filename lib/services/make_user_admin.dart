import 'dart:developer';
import 'package:cloud_functions/cloud_functions.dart';

Future<void> makeUserAdmin(String email) async {
  final callable = FirebaseFunctions.instance.httpsCallable('makeUserAdmin');
  try {
    final result = await callable.call({'email': email});
    log(result.data['message'] ?? 'No message returned');
    // You can show a SnackBar or update UI here as per your Figma design
  } on FirebaseFunctionsException catch (e) {
    log('Cloud Function error: ${e.code} - ${e.message}');
    // Show error message in UI as per Figma guidelines
  } catch (e) {
    log('Unknown error: $e');
    // Show generic error in UI as per Figma guidelines
  }
}

// Usage:
// makeUserAdmin('user@example.com');