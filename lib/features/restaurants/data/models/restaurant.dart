// lib/features/restaurants/data/models/restaurant.dart
import 'dart:convert';

/// Enum for Veg/Non-Veg type
enum VegType { veg, nonveg, both }

VegType vegTypeFromString(String? value) {
  if (value == null) return VegType.both;
  switch (value.toLowerCase()) {
    case 'veg':
      return VegType.veg;
    case 'nonveg':
    case 'non-veg':
    case 'non veg':
      return VegType.nonveg;
    case 'both':
      return VegType.both;
    default:
      return VegType.both;
  }
}

/// Menu item model
class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final VegType vegType;
  final String? image;
  final bool available;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.vegType,
    this.image,
    this.available = true,
  });

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id'] as String,
      name: map['name'] as String,
      description: (map['description'] ?? '') as String,
      price: (map['price'] is num) ? (map['price'] as num).toDouble() : double.tryParse('${map['price']}') ?? 0.0,
      vegType: vegTypeFromString(map['vegType'] as String?),
      image: map['image'] as String?,
      available: map['available'] is bool ? map['available'] as bool : true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'vegType': vegType.name,
      'image': image,
      'available': available,
    };
  }
}

/// Restaurant model
class Restaurant {
  final String id;
  final String name;
  final List<String> cuisine;
  final double rating;
  final String deliveryTime;
  final int deliveryFee;
  final int priceLevel;
  final String image;
  final VegType vegType;
  final String? shortDescription;
  final List<MenuItem> menu;

  Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.deliveryTime,
    required this.deliveryFee,
    required this.priceLevel,
    required this.image,
    required this.vegType,
    this.shortDescription,
    this.menu = const [],
  });

  /// Factory to create Restaurant from Map
  factory Restaurant.fromMap(Map<String, dynamic> map) {
    // parse cuisine safely
    final cuisineList = <String>[];
    if (map['cuisine'] is List) {
      for (var v in map['cuisine']) {
        if (v != null) cuisineList.add(v.toString());
      }
    }

    // parse menu items if present
    final items = <MenuItem>[];
    if (map['menu'] is List) {
      for (var itm in (map['menu'] as List)) {
        try {
          if (itm is Map<String, dynamic>) {
            items.add(MenuItem.fromMap(itm));
          } else if (itm is Map) {
            items.add(MenuItem.fromMap(Map<String, dynamic>.from(itm)));
          }
        } catch (_) {
          // ignore malformed menu item but continue parsing others
        }
      }
    }

    return Restaurant(
      id: map['id'] as String,
      name: map['name'] as String,
      cuisine: cuisineList,
      rating: (map['rating'] as num).toDouble(),
      deliveryTime: map['deliveryTime'] as String,
      deliveryFee: (map['deliveryFee'] as num).toInt(),
      priceLevel: (map['priceLevel'] as num).toInt(),
      image: map['image'] as String? ?? '',
      vegType: vegTypeFromString(map['vegType'] as String?),
      shortDescription: map['shortDescription'] as String?,
      menu: items,
    );
  }

  /// Convert Restaurant to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cuisine': cuisine,
      'rating': rating,
      'deliveryTime': deliveryTime,
      'deliveryFee': deliveryFee,
      'priceLevel': priceLevel,
      'image': image,
      'vegType': vegType.name,
      'shortDescription': shortDescription,
      'menu': menu.map((m) => m.toMap()).toList(),
    };
  }

  /// JSON decode from string
  static List<Restaurant> listFromJson(String jsonStr) {
    final data = json.decode(jsonStr) as List<dynamic>;
    return data.map((e) {
      if (e is Map<String, dynamic>) {
        return Restaurant.fromMap(e);
      } else {
        return Restaurant.fromMap(Map<String, dynamic>.from(e as Map));
      }
    }).toList();
  }
}