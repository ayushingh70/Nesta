// lib/features/cart/data/cart_storage.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nestafar/features/restaurants/data/models/restaurant.dart';
import 'package:nestafar/features/cart/presentation/pages/cart_screen.dart';

/// Handles saving and loading cart items using SharedPreferences.
/// Cart items are stored as JSON.
class CartStorage {
  static const _key = 'user_cart';

  /// Save the list of cart items to storage.
  static Future<void> saveCart(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final data = items
        .map((ci) => {
      'item': ci.item.toMap(),
      'qty': ci.qty,
    })
        .toList();
    await prefs.setString(_key, jsonEncode(data));
  }

  /// Load cart items from storage.
  static Future<List<CartItem>> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_key);
    if (str == null) return [];

    try {
      final list = jsonDecode(str) as List<dynamic>;
      return list.map((e) {
        final map = e as Map<String, dynamic>;
        final item = MenuItem.fromMap(Map<String, dynamic>.from(map['item']));
        return CartItem(item: item, qty: map['qty'] as int);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Clear saved cart.
  static Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}