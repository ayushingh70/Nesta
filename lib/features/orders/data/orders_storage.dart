// lib/features/orders/data/orders_storage.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:nestafar/features/settings/data/settings_storage.dart';

class OrderLine {
  final String itemId;
  final String name;
  final int qty;
  final double price;
  final String? image;

  const OrderLine({
    required this.itemId,
    required this.name,
    required this.qty,
    required this.price,
    this.image,
  });

  double get lineTotal => price * qty;

  Map<String, dynamic> toMap() => {
    'itemId': itemId,
    'name': name,
    'qty': qty,
    'price': price,
    'image': image,
  };

  factory OrderLine.fromMap(Map<String, dynamic> m) => OrderLine(
    itemId: (m['itemId'] ?? '') as String,
    name: (m['name'] ?? '') as String,
    qty: (m['qty'] is int)
        ? m['qty'] as int
        : int.tryParse('${m['qty']}') ?? 0,
    price: (m['price'] is num)
        ? (m['price'] as num).toDouble()
        : double.tryParse('${m['price']}') ?? 0.0,
    image: m['image'] as String?,
  );
}

/// Persisted order snapshot for history.
class Order {
  final String id; // e.g. ISO timestamp or UUID
  final DateTime placedAt;
  final List<OrderLine> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final UserAddress address;

  Order({
    required this.id,
    required this.placedAt,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.address,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'placedAt': placedAt.toIso8601String(),
    'items': items.map((e) => e.toMap()).toList(),
    'subtotal': subtotal,
    'deliveryFee': deliveryFee,
    'total': total,
    'address': address.toMap(),
  };

  factory Order.fromMap(Map<String, dynamic> m) {
    final itemsRaw = (m['items'] as List<dynamic>? ?? const []);
    final lines = <OrderLine>[
      for (final e in itemsRaw)
        if (e is Map)
          OrderLine.fromMap(Map<String, dynamic>.from(e as Map))
    ];

    return Order(
      id: (m['id'] ?? '') as String,
      placedAt: DateTime.tryParse((m['placedAt'] ?? '') as String) ??
          DateTime.now(),
      items: lines,
      subtotal: (m['subtotal'] is num)
          ? (m['subtotal'] as num).toDouble()
          : double.tryParse('${m['subtotal']}') ?? 0.0,
      deliveryFee: (m['deliveryFee'] is num)
          ? (m['deliveryFee'] as num).toDouble()
          : double.tryParse('${m['deliveryFee']}') ?? 0.0,
      total: (m['total'] is num)
          ? (m['total'] as num).toDouble()
          : double.tryParse('${m['total']}') ?? 0.0,
      address: UserAddress.fromMap(
        Map<String, dynamic>.from(m['address'] as Map),
      ),
    );
  }
}

class OrdersStorage {
  static const _kOrdersKey = 'nestafar_orders_v1';

  /// Append one order to history.
  static Future<void> addOrder(Order order) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_kOrdersKey);
      final List<dynamic> current =
      raw == null ? [] : (json.decode(raw) as List<dynamic>);
      current.add(order.toMap());
      await sp.setString(_kOrdersKey, json.encode(current));
    } catch (_) {
      // ignore write errors
    }
  }

  /// Load all orders (oldest first). Reverse in UI if you want newest first.
  static Future<List<Order>> loadOrders() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_kOrdersKey);
      if (raw == null) return [];
      final decoded = json.decode(raw) as List<dynamic>;
      final out = <Order>[];
      for (final e in decoded) {
        if (e is Map) {
          try {
            out.add(Order.fromMap(Map<String, dynamic>.from(e as Map)));
          } catch (_) {}
        }
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  /// Clear all saved orders.
  static Future<void> clear() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.remove(_kOrdersKey);
    } catch (_) {
    }
  }
}