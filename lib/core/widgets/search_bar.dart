// lib/core/widgets/search_bar.dart
import 'dart:async';
import 'package:flutter/material.dart';

class AppSearchBar extends StatefulWidget {
  final String hintText;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onFilterPressed;
  final TextEditingController? controller;
  final Duration debounceDuration;
  final EdgeInsetsGeometry padding;
  final bool showShadow;

  const AppSearchBar({
    super.key,
    this.hintText = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.onFilterPressed,
    this.controller,
    this.debounceDuration = const Duration(milliseconds: 450),
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.showShadow = true,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      if (mounted) widget.onChanged?.call(q.trim());
    });
    setState(() {}); // update clear button visibility
  }

  void _onClear() {
    _controller.clear();
    widget.onChanged?.call('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: widget.padding,
      child: Material(
        elevation: widget.showShadow ? 2.0 : 0.0,
        shadowColor: cs.shadow,
        borderRadius: BorderRadius.circular(12),
        color: cs.surface,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              const SizedBox(width: 8),
              Icon(Icons.search, color: cs.onSurface.withOpacity(0.7)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: widget.onSubmitted,
                  onChanged: _onTextChanged,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurface.withOpacity(0.6)),
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              // Clear button (shows only when there's text)
              if (_controller.text.isNotEmpty)
                IconButton(
                  tooltip: 'Clear',
                  icon: Icon(Icons.close, color: cs.onSurface.withOpacity(0.7)),
                  onPressed: _onClear,
                  splashRadius: 20,
                  visualDensity: VisualDensity.compact,
                ),

              // Filter button
              IconButton(
                tooltip: 'Filters',
                icon: Icon(Icons.tune, color: cs.onSurface.withOpacity(0.7)),
                onPressed: widget.onFilterPressed,
                splashRadius: 20,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}