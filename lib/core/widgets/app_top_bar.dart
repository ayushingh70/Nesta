// lib/core/widgets/app_top_bar.dart
import 'package:flutter/material.dart';

/// Reusable AppBar
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool showBack;

  const AppTopBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = false,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).maybePop(),
      )
          : null,
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: centerTitle,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}