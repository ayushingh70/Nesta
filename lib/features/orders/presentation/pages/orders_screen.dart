// lib/features/orders/presentation/pages/orders_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nestafar/features/orders/data/orders_storage.dart';

const _kCartPrefsKey = 'nestafar_cart_v1';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    final loaded = await OrdersStorage.loadOrders();
    setState(() {
      _orders = loaded.reversed.toList();
      _loading = false;
    });
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all orders?'),
        content: const Text(
            'This will remove all saved order history.\nThis action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true) {
      await OrdersStorage.clear();
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Order history cleared')));
      }
    }
  }

  Future<void> _addOrderToCart(Order order) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_kCartPrefsKey);
      final List<dynamic> current = raw == null ? [] : (json.decode(raw) as List<dynamic>);

      // normalize existing items into map by itemId -> map
      final Map<String, Map<String, dynamic>> existingById = {};
      for (final e in current) {
        if (e is Map) {
          try {
            final m = Map<String, dynamic>.from(e);
            // expected shape: { "item": { ...menu item map... }, "qty": N }
            final itemMap = Map<String, dynamic>.from(m['item'] as Map? ?? {});
            final id = (itemMap['id'] ?? itemMap['itemId'] ?? itemMap['item_id'] ?? '').toString();
            if (id.isEmpty) {
              // fallback to name key
              final fname = (itemMap['name'] ?? '').toString();
              existingById[fname] = {'item': itemMap, 'qty': (m['qty'] ?? 0)};
            } else {
              existingById[id] = {'item': itemMap, 'qty': (m['qty'] ?? 0)};
            }
          } catch (_) {
          }
        }
      }

      for (final line in order.items) {
        final id = line.itemId;
        final itemMap = <String, dynamic>{
          'id': id,
          'name': line.name,
          'description': '', // unknown from order snapshot
          'price': line.price,
          'image': line.image,
        };

        if (existingById.containsKey(id)) {
          final existing = existingById[id]!;
          final currentQty = (existing['qty'] is int) ? existing['qty'] as int : int.tryParse('${existing['qty']}') ?? 0;
          existing['qty'] = currentQty + line.qty;
        } else {
          existingById[id] = {'item': itemMap, 'qty': line.qty};
        }
      }

      // convert back to list form expected by cart prefs
      final out = <Map<String, dynamic>>[];
      for (final entry in existingById.entries) {
        final item = entry.value['item'] as Map<String, dynamic>;
        final qty = entry.value['qty'] as int;
        out.add({'item': item, 'qty': qty});
      }

      await sp.setString(_kCartPrefsKey, json.encode(out));
    } catch (_) {
      // ignore save errors for now
    }
  }

  void _openOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: FractionallySizedBox(
            heightFactor: 0.8,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(child: Text('Order #${order.id}', style: Theme.of(ctx).textTheme.titleLarge)),
                      Text(DateFormat('dd MMM yyyy • HH:mm').format(order.placedAt), style: Theme.of(ctx).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Divider(height: 24),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: order.items.length,
                    separatorBuilder: (_, __) => Divider(color: cs.outlineVariant.withOpacity(0.3)),
                    itemBuilder: (context, idx) {
                      final line = order.items[idx];
                      return ListTile(
                        leading: line.image != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(line.image!, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.fastfood)),
                        )
                            : CircleAvatar(backgroundColor: cs.primary.withOpacity(0.1), child: const Icon(Icons.fastfood)),
                        title: Text(line.name),
                        subtitle: Text('${line.qty} × ₹${line.price.toStringAsFixed(0)}'),
                        trailing: Text('₹${line.lineTotal.toStringAsFixed(0)}'),
                      );
                    },
                  ),
                ),
                // Address text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${order.address.line1}, ${order.address.city}', style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('Subtotal:'),
                          const Spacer(),
                          Text('₹${order.subtotal.toStringAsFixed(0)}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text('Delivery:'),
                          const Spacer(),
                          Text(order.deliveryFee == 0 ? 'Free' : '₹${order.deliveryFee.toStringAsFixed(0)}'),
                        ],
                      ),
                      const Divider(),
                      Row(
                        children: [
                          Text('Total', style: Theme.of(context).textTheme.titleMedium),
                          const Spacer(),
                          Text('₹${order.total.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Close'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () async {
                                // add order items into cart prefs
                                await _addOrderToCart(order);
                                if (mounted) {
                                  Navigator.of(ctx).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Items added to cart')));
                                }
                              },
                              icon: const Icon(Icons.replay),
                              label: const Text('Reorder'),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadOrders,
          child: _loading
              ? ListView(padding: const EdgeInsets.all(20), children: [Center(child: CircularProgressIndicator(color: cs.primary))])
              : _orders.isEmpty
              ? Center(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long, size: 88, color: cs.primary.withOpacity(0.6)),
                  const SizedBox(height: 18),
                  Text('No orders yet', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('Your completed orders will appear here.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 22),
                  FilledButton.icon(onPressed: _loadOrders, icon: const Icon(Icons.refresh), label: const Text('Refresh')),
                ],
              ),
            ),
          )
              : ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            itemCount: _orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, idx) {
              final order = _orders[idx];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
                child: ListTile(
                  onTap: () => _openOrderDetails(order),
                  leading: CircleAvatar(backgroundColor: cs.primary.withOpacity(0.08), child: Icon(Icons.shopping_bag, color: cs.primary)),
                  title: Text('Order #${order.id}', style: Theme.of(context).textTheme.titleMedium),
                  subtitle: Text('${order.items.length} items • ${DateFormat('dd MMM yyyy').format(order.placedAt)}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${order.total.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 6),
                      Text(order.address.city, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: _orders.isNotEmpty
          ? FloatingActionButton.extended(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        onPressed: _clearAll,
        label: const Text('Clear history'),
        icon: const Icon(Icons.delete_outline),
      )
          : null,
    );
  }
}