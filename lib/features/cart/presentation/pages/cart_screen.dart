// lib/features/cart/presentation/pages/cart_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nestafar/features/restaurants/data/models/restaurant.dart';
import 'package:nestafar/features/settings/data/settings_storage.dart';
import 'package:nestafar/features/orders/data/orders_storage.dart';

/// Simple CartItem wrapper: pairs a MenuItem with quantity.
class CartItem {
  final MenuItem item;
  int qty;

  CartItem({required this.item, required this.qty});

  double get lineTotal => item.price * qty;

  Map<String, dynamic> toMap() => {
    'item': item.toMap(),
    'qty': qty,
  };

  static CartItem fromMap(Map<String, dynamic> map) {
    final mi = MenuItem.fromMap(Map<String, dynamic>.from(map['item'] as Map));
    final q = (map['qty'] is int) ? map['qty'] as int : int.tryParse('${map['qty']}') ?? 0;
    return CartItem(item: mi, qty: q);
  }
}

const _kCartPrefsKey = 'nestafar_cart_v1';

class CartScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final VoidCallback? onCheckout;
  final ValueChanged<List<CartItem>>? onUpdate;

  const CartScreen({
    super.key,
    required this.cartItems,
    this.onCheckout,
    this.onUpdate,
  });

  static Route route(
      List<CartItem> cartItems, {
        VoidCallback? onCheckout,
        ValueChanged<List<CartItem>>? onUpdate,
        bool withScaffold = true,
      }) =>
      MaterialPageRoute(
        builder: (_) {
          if (!withScaffold) {
            // return bare widget (for embedding)
            return CartScreen(cartItems: cartItems, onCheckout: onCheckout, onUpdate: onUpdate);
          }
          // wrap with scaffold for pushed route
          return Scaffold(
            appBar: AppBar(title: const Text('Cart')),
            body: CartScreen(cartItems: cartItems, onCheckout: onCheckout, onUpdate: onUpdate),
          );
        },
      );

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // keep a local copy so stepper changes are immediate; report back via onUpdate.
  late List<CartItem> _items;
  static const int freeDeliveryThreshold = 500;

  // controllers for address bottom sheet
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _line1Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // If caller passed initial items, use them; otherwise try to load from prefs.
    if (widget.cartItems.isNotEmpty) {
      _items = widget.cartItems.map((e) => CartItem(item: e.item, qty: e.qty)).toList();
      // ensure persisted state matches caller-provided (write)
      _saveToPrefs();
    } else {
      _items = [];
      _loadFromPrefs();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _line1Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_kCartPrefsKey);
      if (raw == null) return;
      final decoded = json.decode(raw) as List<dynamic>;
      final loaded = decoded.map((e) => CartItem.fromMap(Map<String, dynamic>.from(e))).toList();
      if (mounted && loaded.isNotEmpty) {
        setState(() => _items = loaded);
        widget.onUpdate?.call(_items);
      }
    } catch (_) {
      // ignore load errors for now
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kCartPrefsKey, json.encode(_items.map((ci) => ci.toMap()).toList()));
    } catch (_) {
      // ignore save errors
    }
  }

  void _updateCaller() {
    widget.onUpdate?.call(_items);
    _saveToPrefs();
  }

  void _increase(CartItem ci) {
    setState(() => ci.qty++);
    _updateCaller();
  }

  void _decreaseOrRemove(CartItem ci) {
    setState(() {
      if (ci.qty > 1) {
        ci.qty--;
      } else {
        _items.remove(ci);
      }
    });
    _updateCaller();
  }

  void _removeItem(CartItem ci) {
    setState(() => _items.remove(ci));
    _updateCaller();
  }

  double get subtotal => _items.fold(0.0, (s, i) => s + i.lineTotal);
  int get totalItems => _items.fold(0, (s, i) => s + i.qty);
  double get deliveryFee => subtotal >= freeDeliveryThreshold ? 0.0 : (_items.isEmpty ? 0.0 : 30.0);
  double get total => subtotal + deliveryFee;

  /// Show bottom sheet to add/edit address.
  /// Returns the saved UserAddress or null if the user cancelled.
  Future<UserAddress?> _showAddressBottomSheet() async {
    // Prefill controllers with existing address if any
    final existing = await SettingsStorage.loadAddress();
    if (existing != null) {
      _nameController.text = existing.name;
      _phoneController.text = existing.phone;
      _line1Controller.text = existing.line1;
      _cityController.text = existing.city;
      _stateController.text = existing.state ?? '';
      _pincodeController.text = existing.pincode ?? '';
    }

    final result = await showModalBottomSheet<UserAddress?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // handle
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 12),
                  Text('Add Address', style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _line1Controller,
                    decoration: const InputDecoration(labelText: 'Address'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(labelText: 'State (optional)'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _pincodeController,
                    decoration: const InputDecoration(labelText: 'Pincode (optional)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text("Save"),
                    onPressed: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        final addr = UserAddress(
                          name: _nameController.text.trim(),
                          phone: _phoneController.text.trim(),
                          line1: _line1Controller.text.trim(),
                          city: _cityController.text.trim(),
                          state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
                          pincode: _pincodeController.text.trim().isEmpty ? null : _pincodeController.text.trim(),
                        );
                        await SettingsStorage.saveAddress(addr);
                        if (mounted) Navigator.of(ctx).pop(addr);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop(null); // user cancelled
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );

    return result;
  }

  Future<void> _handleCheckout(BuildContext context) async {
    UserAddress? addr = await SettingsStorage.loadAddress();

    // Prepare the compact OrderLine list (for preview / passing to confirmation)
    final lines = _items.map((ci) => OrderLine(itemId: ci.item.id, name: ci.item.name, qty: ci.qty, price: ci.item.price, image: ci.item.image)).toList();

    // Try to infer deliveryTime from the first cart item's map (best-effort)
    String? inferredDeliveryTime;
    if (_items.isNotEmpty) {
      try {
        final firstMap = _items.first.item.toMap();

        // Look for commonly used keys or nested restaurant object
        final candidates = <dynamic>[
          firstMap['deliveryTime'],
          firstMap['restaurantDeliveryTime'],
          firstMap['delivery'],
          firstMap['restaurantDelivery'],
          firstMap['restaurant'] is Map ? (firstMap['restaurant'] as Map)['deliveryTime'] : null,
          firstMap['meta'] is Map ? (firstMap['meta'] as Map)['deliveryTime'] : null,
        ];

        for (final c in candidates) {
          if (c == null) continue;
          final s = c.toString().trim();
          if (s.isEmpty) continue;
          inferredDeliveryTime = s;
          break;
        }

        // If it's numeric (e.g., "30"), add friendly postfix
        if (inferredDeliveryTime != null && RegExp(r'^\d+$').hasMatch(inferredDeliveryTime)) {
          inferredDeliveryTime = '$inferredDeliveryTime mins';
        }
      } catch (_) {
        // ignore inference errors
      }
    }

    if (addr == null || addr.isEmpty) {
      // No saved address -> ask user to add one
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("No Address Found"),
          content: const Text("Please add your delivery address before checkout."),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop(); // close dialog

                // Open bottom sheet to add address and wait for returned address (or null)
                final result = await _showAddressBottomSheet();

                // result is UserAddress? — check and use a non-null local before passing
                if (result != null && mounted) {
                  final selected = result; // non-nullable UserAddress

                  // show confirmation screen (simulate payment) -> pass items & deliveryTime
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CheckoutConfirmationScreen(
                        address: selected,
                        amount: total,
                        items: lines,
                        deliveryTime: inferredDeliveryTime,
                      ),
                    ),
                  );

                  // after confirmation -> persist order, clear cart & notify parent
                  await _saveOrderAndClearCart(selected);
                }
              },
              child: const Text("Add Address"),
            ),
          ],
        ),
      );
    } else {
      // We have an address saved already -> proceed
      if (!mounted) return;
      final selected = addr; // non-nullable by local alias

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CheckoutConfirmationScreen(
            address: selected,
            amount: total,
            items: lines,
            deliveryTime: inferredDeliveryTime,
          ),
        ),
      );

      // after confirmation -> persist order, clear cart & notify parent
      await _saveOrderAndClearCart(selected);
      widget.onCheckout?.call();
    }
  }

  /// Build an Order object from current cart, persist it to OrdersStorage,
  /// then clear cart and persist the cleared cart.
  Future<void> _saveOrderAndClearCart(UserAddress address) async {
    if (_items.isEmpty) return;

    final lines = _items.map((ci) => OrderLine(itemId: ci.item.id, name: ci.item.name, qty: ci.qty, price: ci.item.price, image: ci.item.image)).toList();

    final order = Order(
      id: DateTime.now().toIso8601String(),
      placedAt: DateTime.now(),
      items: lines,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: total,
      address: address,
    );

    // persist order
    await OrdersStorage.addOrder(order);

    // clear cart and persist
    if (!mounted) return;
    setState(() => _items.clear());
    _updateCaller();

    // optional user feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you, Order placed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(top: false, child: _items.isEmpty ? _emptyView(context) : _cartBody(context, cs));
  }

  Widget _emptyView(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 72, color: cs.primary.withOpacity(0.8)),
            const SizedBox(height: 12),
            Text('Your cart is empty', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('Add items from a restaurant to see them here.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _cartBody(BuildContext context, ColorScheme cs) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, idx) => _cartRow(context, _items[idx], cs),
          ),
        ),
        _summaryArea(context, cs),
      ],
    );
  }

  Widget _cartRow(BuildContext context, CartItem ci, ColorScheme cs) {
    return Material(
      elevation: 1,
      color: cs.surface,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            // Show item image if available, otherwise fallback icon
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 84,
                height: 84,
                color: cs.primary.withOpacity(0.06),
                child: (ci.item.image != null && ci.item.image!.isNotEmpty)
                    ? Image.asset(
                  ci.item.image!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.fastfood, size: 36)),
                )
                    : const Center(child: Icon(Icons.fastfood, size: 36)),
              ),
            ),

            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ci.item.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(ci.item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Row(children: [
                  Text('₹${ci.item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(onPressed: () => _decreaseOrRemove(ci), icon: const Icon(Icons.remove)),
                  Text(ci.qty.toString(), style: Theme.of(context).textTheme.bodyMedium),
                  IconButton(onPressed: () => _increase(ci), icon: const Icon(Icons.add)),
                  IconButton(onPressed: () => _removeItem(ci), icon: Icon(Icons.delete_outline, color: cs.error)),
                ]),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryArea(BuildContext context, ColorScheme cs) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: cs.surface, border: Border(top: BorderSide(color: cs.surfaceVariant))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Text('${totalItems} items'),
            const Spacer(),
            Text('Subtotal: ₹${subtotal.toStringAsFixed(0)}'),
          ]),
          const SizedBox(height: 8),
          Row(children: [Text('Delivery'), const Spacer(), Text(deliveryFee == 0 ? 'Free' : '₹${deliveryFee.toStringAsFixed(0)}')]),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () => _handleCheckout(context), child: Text('Checkout • ₹${total.toStringAsFixed(0)}')),
        ]),
      ),
    );
  }
}

/// Confirmation Screen
class CheckoutConfirmationScreen extends StatelessWidget {
  final UserAddress address;
  final double amount;
  final List<OrderLine>? items;
  final String? deliveryTime;

  const CheckoutConfirmationScreen({
    super.key,
    required this.address,
    required this.amount,
    this.items,
    this.deliveryTime,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              // Success animation / glowing check
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(shape: BoxShape.circle, color: cs.primary.withOpacity(0.1)),
                child: Icon(Icons.check_circle_rounded, size: 120, color: cs.primary),
              ),
              const SizedBox(height: 24),
              Text(
                "Order Placed Successfully!",
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Thank you for your purchase. Your delicious food is on its way 🍴",
                style: textTheme.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Compact items preview (if we have items)
              if (items != null && items!.isNotEmpty) ...[
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text("Ordered Items", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text("${items!.length} items", style: textTheme.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // show all items in a column
                        Column(
                          children: items!.map((l) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      width: 56,
                                      height: 56,
                                      color: cs.primary.withOpacity(0.06),
                                      child: (l.image != null && l.image!.isNotEmpty)
                                          ? Image.asset(l.image!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.fastfood))
                                          : const Icon(Icons.fastfood),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text("${l.qty} × ${l.name}", style: textTheme.bodyMedium)),
                                  const SizedBox(width: 8),
                                  Text("₹${(l.price * l.qty).toStringAsFixed(0)}", style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                                ],
                              ),
                            );
                          }).toList(),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Order summary card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Order Summary", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.receipt_long, size: 20),
                        const SizedBox(width: 8),
                        Text("Amount Paid: ", style: textTheme.bodyMedium),
                        const Spacer(),
                        Text("₹${amount.toStringAsFixed(0)}", style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${address.line1}, ${address.city}${address.state != null ? ", ${address.state}" : ""}",
                            style: textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 20),

              // Estimated delivery time card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                color: cs.primary.withOpacity(0.08),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.delivery_dining, size: 32, color: cs.primary),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Estimated Delivery", style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            deliveryTime ?? "30 - 40 mins",
                            style: textTheme.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // Back to Home button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text(
                    "Back to Home",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}