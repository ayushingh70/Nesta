// lib/features/restaurants/presentation/pages/restaurant_details.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nestafar/features/restaurants/data/models/restaurant.dart';
import '../../../../main.dart' show ThemeCubit; // re-use ThemeCubit from main.dart
import '../../../cart/presentation/pages/cart_screen.dart';
// added search bar import
import 'package:nestafar/core/widgets/search_bar.dart';

const _kCartPrefsKey = 'nestafar_cart_v1';

class RestaurantDetailsScreen extends StatefulWidget {
  final Restaurant restaurant;
  final VoidCallback? onOpenCart;

  const RestaurantDetailsScreen({
    super.key,
    required this.restaurant,
    this.onOpenCart,
  });

  @override
  State<RestaurantDetailsScreen> createState() =>
      _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  // menuItemId -> qty (local state for this screen)
  final Map<String, int> _cart = {};

  // search query state
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSavedCart();
  }

  // Load saved cart from SharedPreferences and prefill quantities for items
  Future<void> _loadSavedCart() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_kCartPrefsKey);
      if (raw == null) return;
      final List<dynamic> decoded = json.decode(raw) as List<dynamic>;
      final Map<String, int> loaded = {};
      for (final entry in decoded) {
        if (entry is Map<String, dynamic>) {
          final itemId = entry['itemId']?.toString();
          final qty = entry['qty'];
          final restaurantId = entry['restaurantId']?.toString();
          // Only load items that belong to this restaurant (so details shows its own items)
          if (itemId != null &&
              qty is int &&
              restaurantId == widget.restaurant.id) {
            loaded[itemId] = qty;
          }
        }
      }
      if (mounted && loaded.isNotEmpty) {
        setState(() {
          _cart
            ..clear()
            ..addAll(loaded);
        });
      }
    } catch (_) {
    }
  }
  Future<void> _persistCartChange() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_kCartPrefsKey);
      final List<dynamic> decoded = raw == null ? [] : json.decode(raw) as List<dynamic>;

      // Build a map of existing entries keyed by (restaurantId + itemId) to merge easily
      final Map<String, Map<String, dynamic>> merged = {};

      for (final e in decoded) {
        if (e is Map<String, dynamic>) {
          final rId = e['restaurantId']?.toString();
          final iId = e['itemId']?.toString();
          if (rId != null && iId != null) {
            merged['$rId|$iId'] = {
              'restaurantId': rId,
              'itemId': iId,
              'qty': (e['qty'] is int) ? e['qty'] as int : int.tryParse('${e['qty']}') ?? 0,
            };
          }
        }
      }

      // Merge current restaurant's _cart into merged map.
      // If qty for an item is zero or missing, remove it from merged.
      for (final mi in widget.restaurant.menu) {
        final key = '${widget.restaurant.id}|${mi.id}';
        if (_cart.containsKey(mi.id)) {
          final q = _cart[mi.id]!;
          if (q > 0) {
            merged[key] = {
              'restaurantId': widget.restaurant.id,
              'itemId': mi.id,
              'qty': q,
            };
          } else {
            merged.remove(key);
          }
        } else {
          // if local map doesn't have it, do nothing (we keep other restaurants' items)
        }
      }

      // Convert merged to list
      final List<Map<String, dynamic>> out = merged.values.toList();
      await sp.setString(_kCartPrefsKey, json.encode(out));
    } catch (_) {
      // ignore persistence errors for now (we could surface later)
    }
  }

  void _increment(MenuItem item) {
    setState(() {
      _cart[item.id] = (_cart[item.id] ?? 0) + 1;
    });
    _persistCartChange();
  }

  void _decrement(MenuItem item) {
    setState(() {
      final current = _cart[item.id] ?? 0;
      if (current > 1) {
        _cart[item.id] = current - 1;
      } else {
        _cart.remove(item.id);
      }
    });
    _persistCartChange();
  }

  int _getQuantity(MenuItem item) => _cart[item.id] ?? 0;

  /// Convert cart map into CartItem list for passing to CartScreen.route
  List<CartItem> _buildCartItems() {
    return widget.restaurant.menu
        .where((m) => _cart.containsKey(m.id))
        .map((m) => CartItem(item: m, qty: _cart[m.id]!))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;
    final cs = Theme.of(context).colorScheme;

    // apply search filtering (case-insensitive) but keep original menu unchanged
    final filteredMenu = restaurant.menu.where((mi) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final nameMatch = mi.name.toLowerCase().contains(q);
      final descMatch = mi.description.toLowerCase().contains(q);
      return nameMatch || descMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          restaurant.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: const Icon(Icons.brightness_6),
            onPressed: () => context.read<ThemeCubit>().toggle(),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Hero image
                Hero(
                  tag: 'restaurant-image-${restaurant.id}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      color: cs.primary.withOpacity(0.06),
                      child: restaurant.image.isNotEmpty
                          ? Image.asset(
                        restaurant.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.restaurant, size: 48)),
                      )
                          : const Center(child: Icon(Icons.restaurant, size: 48)),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // name + rating
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              restaurant.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: cs.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: Colors.amber),
                                const SizedBox(width: 6),
                                Text(restaurant.rating.toStringAsFixed(1), style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      if (restaurant.shortDescription != null && restaurant.shortDescription!.isNotEmpty)
                        Text(
                          restaurant.shortDescription!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.8)),
                        ),

                      const SizedBox(height: 12),
                      // chips row
                      Row(
                        children: [
                          _vegBadge(context, restaurant.vegType),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(color: cs.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                            child: Text('• ${restaurant.deliveryTime}', style: Theme.of(context).textTheme.bodySmall),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              children: restaurant.cuisine
                                  .map((c) => Chip(
                                label: Text(c),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Text('Menu', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          Text('(${restaurant.menu.length} items)', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Search bar below Menu header
                      AppSearchBar(
                        hintText: 'Search menu items...',
                        onChanged: (q) {
                          setState(() {
                            _searchQuery = q;
                          });
                        },
                        showShadow: false,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ],
                  ),
                ),

                // Menu list (filtered)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: filteredMenu
                        .map(
                          (mi) => _MenuItemRow(
                        menuItem: mi,
                        quantity: _getQuantity(mi),
                        onAdd: () => _increment(mi),
                        onRemove: () => _decrement(mi),
                      ),
                    )
                        .toList(),
                  ),
                ),

                const SizedBox(height: 75),
              ],
            ),
          ),

          // floating bottom center button
          if (_cart.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: () async {
                    // Persist first
                    await _persistCartChange();
                    if (widget.onOpenCart != null) {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                      widget.onOpenCart!.call();
                      return;
                    }

                    final items = _buildCartItems();
                    await Navigator.of(context).push(
                      CartScreen.route(
                        items,
                        onUpdate: (updated) {
                          setState(() {
                            _cart
                              ..clear()
                              ..addEntries(updated.map((ci) => MapEntry(ci.item.id, ci.qty)));
                          });
                          _persistCartChange();
                        },
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart),
                  label: Text("${_cart.values.fold(0, (a, b) => a + b)} items in cart"),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _vegBadge(BuildContext context, VegType type) {
    switch (type) {
      case VegType.veg:
        return const _VegBadge(color: Colors.green, label: 'Veg');
      case VegType.nonveg:
        return const _VegBadge(color: Colors.red, label: 'Non-veg');
      case VegType.both:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _VegBadge(color: Colors.green, label: 'Veg', size: 16),
            SizedBox(width: 6),
            _VegBadge(color: Colors.red, label: 'Non', size: 16),
          ],
        );
    }
  }
}

/// Menu item row with stepper
class _MenuItemRow extends StatelessWidget {
  final MenuItem menuItem;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _MenuItemRow({
    required this.menuItem,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Material(
        color: cs.surface,
        elevation: 1,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // item image (unchanged)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 84,
                  height: 84,
                  color: cs.primary.withOpacity(0.06),
                  child: (menuItem.image != null && menuItem.image!.isNotEmpty)
                      ? Image.asset(
                    menuItem.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.fastfood, size: 36),
                  )
                      : const Center(child: Icon(Icons.fastfood, size: 36)),
                ),
              ),

              const SizedBox(width: 12),
              // details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(menuItem.name, style: Theme.of(context).textTheme.titleMedium)),
                        if (menuItem.vegType == VegType.veg)
                          const _VegBadge(color: Colors.green, label: 'Veg', size: 14)
                        else if (menuItem.vegType == VegType.nonveg)
                          const _VegBadge(color: Colors.red, label: 'Non-veg', size: 14),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(menuItem.description, style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text("₹${menuItem.price.toStringAsFixed(0)}", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        quantity == 0
                            ? ElevatedButton(
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                          onPressed: onAdd,
                          child: const Text("Add"),
                        )
                            : Container(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: cs.primary),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.remove, color: Colors.white), onPressed: onRemove),
                              Text("$quantity", style: const TextStyle(color: Colors.white)),
                              IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: onAdd),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Veg badge widget
class _VegBadge extends StatelessWidget {
  final Color color;
  final String label;
  final double size;

  const _VegBadge({required this.color, required this.label, this.size = 20, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), border: Border.all(color: color, width: 1.2)),
          child: Center(child: Container(width: size * 0.45, height: size * 0.45, decoration: BoxDecoration(color: color, shape: BoxShape.circle))),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, color: color)),
      ],
    );
  }
}