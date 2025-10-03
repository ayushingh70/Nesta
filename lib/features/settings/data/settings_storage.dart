// lib/features/settings/data/settings_storage.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple model to store user's name + address details used by Checkout and Settings.
class UserAddress {
  final String name;
  final String phone;
  final String line1;   // Single address line
  final String city;
  final String? state;
  final String? pincode;

  const UserAddress({
    required this.name,
    required this.phone,
    required this.line1,
    required this.city,
    this.state,
    this.pincode,
  });

  UserAddress copyWith({
    String? name,
    String? phone,
    String? line1,
    String? city,
    String? state,
    String? pincode,
  }) {
    return UserAddress(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      line1: line1 ?? this.line1,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
    );
  }

  bool get isEmpty =>
      name.trim().isEmpty &&
          phone.trim().isEmpty &&
          line1.trim().isEmpty &&
          city.trim().isEmpty &&
          (state ?? '').trim().isEmpty &&
          (pincode ?? '').trim().isEmpty;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'line1': line1,
      'city': city,
      'state': state,
      'pincode': pincode,
    };
  }

  factory UserAddress.fromMap(Map<String, dynamic> map) {
    return UserAddress(
      name: (map['name'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      line1: (map['line1'] ?? '') as String,
      city: (map['city'] ?? '') as String,
      state: map['state'] as String?,
      pincode: map['pincode'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserAddress.fromJson(String source) =>
      UserAddress.fromMap(json.decode(source) as Map<String, dynamic>);
}

/// Simple shared preferences wrapper for saving/loading the user's address.
/// Key is namespaced so future migrations can be easier.
class SettingsStorage {
  static const _kPrefix = 'nestafar_settings_v1';
  static const _kAddressKey = '${_kPrefix}_user_address';

  /// Save the provided address (overwrites any previous).
  static Future<void> saveAddress(UserAddress address) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kAddressKey, address.toJson());
    } catch (_) {
      // ignore save errors
    }
  }

  /// Load saved address. Returns null if none saved.
  static Future<UserAddress?> loadAddress() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_kAddressKey);
      if (raw == null || raw.trim().isEmpty) return null;
      return UserAddress.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  /// Clear the saved address.
  static Future<void> clearAddress() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.remove(_kAddressKey);
    } catch (_) {
      // ignore
    }
  }
}