// lib/features/restaurants/presentation/widgets/filter_sheet.dart
import 'package:flutter/material.dart';

enum VegFilter { all, veg, nonveg, both }

/// Each SortOption belongs to a criterion group (rating, fee, time).
/// Multiple different criteria can be selected at once, but opposite
/// options within the same criterion are mutually exclusive.
enum SortOption {
  ratingHigh,
  ratingLow,
  feeLow,
  feeHigh,
  timeLow,
  timeHigh,
}

class FilterOptions {
  final VegFilter vegFilter;
  final Set<SortOption> sortOptions;

  const FilterOptions({
    this.vegFilter = VegFilter.all,
    this.sortOptions = const {},
  });

  FilterOptions copyWith({
    VegFilter? vegFilter,
    Set<SortOption>? sortOptions,
  }) {
    return FilterOptions(
      vegFilter: vegFilter ?? this.vegFilter,
      sortOptions: sortOptions ?? this.sortOptions,
    );
  }
}

/// Compact filter sheet (no price level, minimal spacing).
class FilterSheet extends StatefulWidget {
  final FilterOptions initial;

  const FilterSheet({super.key, required this.initial});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late VegFilter _vegFilter;
  late Set<SortOption> _selectedSorts;

  @override
  void initState() {
    super.initState();
    _vegFilter = widget.initial.vegFilter;
    _selectedSorts = Set.from(widget.initial.sortOptions);
  }

  void _resetToDefaults() {
    setState(() {
      _vegFilter = VegFilter.all;
      _selectedSorts = {};
    });
  }

  // Helpers to toggle sort options with mutual-exclusivity inside each pair.
  void _toggleSort(SortOption option) {
    setState(() {
      // Determine the opposite option (if any) and remove it
      final opposite = _opposite(option);
      if (_selectedSorts.contains(option)) {
        _selectedSorts.remove(option);
      } else {
        if (opposite != null) _selectedSorts.remove(opposite);
        _selectedSorts.add(option);
      }
    });
  }

  SortOption? _opposite(SortOption opt) {
    switch (opt) {
      case SortOption.ratingHigh:
        return SortOption.ratingLow;
      case SortOption.ratingLow:
        return SortOption.ratingHigh;
      case SortOption.feeLow:
        return SortOption.feeHigh;
      case SortOption.feeHigh:
        return SortOption.feeLow;
      case SortOption.timeLow:
        return SortOption.timeHigh;
      case SortOption.timeHigh:
        return SortOption.timeLow;
    }
  }

  Widget _sectionTitle(String text, {IconData? icon}) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        if (icon != null) Icon(icon, size: 16, color: cs.primary),
        if (icon != null) const SizedBox(width: 8),
        Text(text,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Small drag handle
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: cs.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),

            // Header: title + reset (compact)
            Row(
              children: [
                Expanded(
                  child: Text('Filters & Sorting',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: _resetToDefaults,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(44, 28)),
                  child: const Text('Reset'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Veg Type (2x2 compact grid)
            Align(alignment: Alignment.centerLeft, child: _sectionTitle('Veg Type', icon: Icons.local_dining)),
            const SizedBox(height: 6),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 6,
              crossAxisSpacing: 8,
              childAspectRatio: 4.8,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _vegChip(label: 'All', value: VegFilter.all),
                _vegChip(label: 'Both', value: VegFilter.both),
                _vegChip(label: 'Veg', value: VegFilter.veg, leading: Icons.eco),
                _vegChip(label: 'Non Veg', value: VegFilter.nonveg, leading: Icons.set_meal),
              ],
            ),

            const SizedBox(height: 10),

            // Sort options (compact, grouped)
            Align(alignment: Alignment.centerLeft, child: _sectionTitle('Sort (choose one per group)', icon: Icons.sort)),
            const SizedBox(height: 6),

            // Rating group: High / Low
            Row(
              children: [
                Expanded(
                  child: _sortChip(label: 'Rating: Low → High', opt: SortOption.ratingHigh, selected: _selectedSorts.contains(SortOption.ratingHigh)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _sortChip(label: 'Rating: High → Low', opt: SortOption.ratingLow, selected: _selectedSorts.contains(SortOption.ratingLow)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Fee group
            Row(
              children: [
                Expanded(
                  child: _sortChip(label: 'Fee: Low → High', opt: SortOption.feeLow, selected: _selectedSorts.contains(SortOption.feeLow)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _sortChip(label: 'Fee: High → Low', opt: SortOption.feeHigh, selected: _selectedSorts.contains(SortOption.feeHigh)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Time group
            Row(
              children: [
                Expanded(
                  child: _sortChip(label: 'Time: Low → High', opt: SortOption.timeLow, selected: _selectedSorts.contains(SortOption.timeLow)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _sortChip(label: 'Time: High → Low', opt: SortOption.timeHigh, selected: _selectedSorts.contains(SortOption.timeHigh)),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Buttons row: Cancel | Apply
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, null),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, FilterOptions(vegFilter: _vegFilter, sortOptions: _selectedSorts));
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _vegChip({required String label, required VegFilter value, IconData? leading}) {
    final selected = _vegFilter == value;
    final cs = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leading != null) Icon(leading, size: 14),
          if (leading != null) const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => setState(() => _vegFilter = value),
      selectedColor: cs.primary,
      backgroundColor: cs.surfaceVariant,
      labelStyle: TextStyle(color: selected ? cs.onPrimary : cs.onSurface),
    );
  }

  Widget _sortChip({required String label, required SortOption opt, required bool selected}) {
    final cs = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label, textAlign: TextAlign.center),
      selected: selected,
      onSelected: (_) => _toggleSort(opt),
      selectedColor: cs.primary,
      backgroundColor: cs.surfaceVariant,
      labelStyle: TextStyle(color: selected ? cs.onPrimary : cs.onSurface, fontWeight: FontWeight.w600),
    );
  }
}