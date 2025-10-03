// lib/app_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/widgets/app_top_bar.dart';
import 'main.dart' show ThemeCubit; // re-use ThemeCubit from main.dart

import 'package:nestafar/features/restaurants/presentation/pages/foods_screen.dart';
import 'package:nestafar/features/cart/presentation/pages/cart_screen.dart';
import 'package:nestafar/features/settings/presentation/pages/settings_screen.dart';
import 'package:nestafar/features/orders/presentation/pages/orders_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  List<CartItem> _cartItems = [];

  final List<String> _titles = const [
    'Restaurants & Foods',
    'Cart',
    'Orders',
    'Settings',
  ];

  /// Called by child screens to update the shared cart.
  void _updateCartFromChild(List<CartItem> updated) {
    setState(() {
      // clone to avoid accidental shared mutation
      _cartItems = updated.map((e) => CartItem(item: e.item, qty: e.qty)).toList();
    });
  }

  /// Switch to Cart tab (used by Foods/Details floating buttons)
  void _switchToCartTab() {
    setState(() {
      _currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final screens = <Widget>[
      // Foods
      FoodsScreen(
        cartItems: _cartItems,
        onCartUpdated: _updateCartFromChild,
        onOpenCart: _switchToCartTab,
      ),

      // Cart
      CartScreen(
        cartItems: _cartItems,
        onUpdate: _updateCartFromChild,
      ),

      // Orders
      const OrdersScreen(),

      // Settings
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppTopBar(
        title: _titles[_currentIndex],
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: const Icon(Icons.brightness_6),
            onPressed: () => context.read<ThemeCubit>().toggle(),
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: colorScheme.surface,
            selectedItemColor: colorScheme.primary,
            unselectedItemColor: colorScheme.onSurface.withOpacity(0.7),
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Foods'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}