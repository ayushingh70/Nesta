// lib/features/restaurants/data/repositories/restaurant_repository.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/restaurant.dart';

/// Repository responsible for loading restaurants data.
class RestaurantRepository {
  // Candidate asset paths (common names). Put your JSON at any of these or update.
  static const List<String> _candidatePaths = [
    'assets/mock/restaurants.json',
    'assets/data/restaurant.json',
    'assets/data/restaurants.json',
    'assets/restaurant.json',
    'assets/restaurants.json',
  ];

  /// Loads restaurants from local JSON asset.
  /// Throws an Exception with descriptive message on failure.
  Future<List<Restaurant>> loadRestaurants() async {
    String? lastErr;
    for (final path in _candidatePaths) {
      try {
        final jsonStr = await rootBundle.loadString(path);
        final list = Restaurant.listFromJson(jsonStr);
        if (list.isEmpty) {
          lastErr = 'Loaded "$path" but the list is empty.';
          continue;
        }
        return list;
      } on FlutterError catch (fe) {
        // Asset not found
        lastErr = 'Failed to load asset at "$path". Did you add it to pubspec.yaml under flutter.assets?\nFlutterError: ${fe.message}';
        // try next candidate
        continue;
      } catch (e) {
        lastErr = 'Failed to parse or read "$path": $e';
        continue;
      }
    }

    final msg = 'Unable to load restaurants JSON. Tried paths:\n${_candidatePaths.join('\n')}\n\nLast error:\n$lastErr';
    print('RestaurantRepository error: $msg');
    throw Exception(msg);
  }
}