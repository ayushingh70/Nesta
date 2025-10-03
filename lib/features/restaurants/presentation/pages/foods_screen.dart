// lib/features/restaurants/presentation/pages/foods_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:nestafar/core/widgets/search_bar.dart';
import 'package:nestafar/features/restaurants/data/models/restaurant.dart';
import 'package:nestafar/features/restaurants/data/repositories/restaurant_repository.dart';
import 'package:nestafar/features/restaurants/bloc/restaurant_bloc.dart';
import 'package:nestafar/features/restaurants/bloc/restaurant_event.dart';
import 'package:nestafar/features/restaurants/bloc/restaurant_state.dart';
import 'package:nestafar/features/restaurants/presentation/widgets/filter_sheet.dart';
import 'package:nestafar/features/restaurants/presentation/pages/restaurant_details.dart';
import 'package:nestafar/features/cart/presentation/pages/cart_screen.dart';


class FoodsScreen extends StatelessWidget {
  final List<CartItem> cartItems;
  final ValueChanged<List<CartItem>> onCartUpdated;
  final VoidCallback? onOpenCart;

  const FoodsScreen({
    super.key,
    this.onOpenCart,
    required this.cartItems,
    required this.onCartUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
      RestaurantBloc(repository: RestaurantRepository())..add(LoadRestaurants()),
      child: FoodsView(
        cartItems: cartItems,
        onCartUpdated: onCartUpdated,
        onOpenCart: onOpenCart,
      ),
    );
  }
}

class FoodsView extends StatefulWidget {
  final List<CartItem> cartItems;
  final ValueChanged<List<CartItem>> onCartUpdated;
  final VoidCallback? onOpenCart;

  const FoodsView({
    super.key,
    required this.cartItems,
    required this.onCartUpdated,
    this.onOpenCart,
  });

  @override
  State<FoodsView> createState() => _FoodsViewState();
}

class _FoodsViewState extends State<FoodsView> {
  String _query = '';
  FilterOptions _activeFilters = const FilterOptions();

  Future<void> _onRefresh(BuildContext context) async {
    context.read<RestaurantBloc>().add(LoadRestaurants());
    await Future.delayed(const Duration(milliseconds: 500));
  }

  int _parseDeliveryLower(String deliveryTime) {
    try {
      final digits = RegExp(r'(\d+)');
      final match = digits.firstMatch(deliveryTime);
      if (match != null) return int.parse(match.group(0)!);
    } catch (_) {}
    return 9999;
  }

  List<Restaurant> _applyFiltersAndSort(List<Restaurant> source) {
    var list = source.where((r) {
      if (_query.isEmpty) return true;
      final nameMatch = r.name.toLowerCase().contains(_query);
      final cuisineMatch = r.cuisine.any((c) => c.toLowerCase().contains(_query));
      return nameMatch || cuisineMatch;
    }).toList();

    switch (_activeFilters.vegFilter) {
      case VegFilter.all:
        break;
      case VegFilter.veg:
        list = list.where((r) => r.vegType == VegType.veg).toList();
        break;
      case VegFilter.nonveg:
        list = list.where((r) => r.vegType == VegType.nonveg).toList();
        break;
      case VegFilter.both:
        list = list.where((r) => r.vegType == VegType.both).toList();
        break;
    }

    final sorts = _activeFilters.sortOptions;

    if (sorts.isEmpty) {
      list.sort((a, b) => b.rating.compareTo(a.rating));
      return list;
    }

    int comparator(Restaurant a, Restaurant b) {
      if (sorts.contains(SortOption.ratingHigh)) {
        final cmp = b.rating.compareTo(a.rating);
        if (cmp != 0) return cmp;
      } else if (sorts.contains(SortOption.ratingLow)) {
        final cmp = a.rating.compareTo(b.rating);
        if (cmp != 0) return cmp;
      }

      if (sorts.contains(SortOption.feeLow)) {
        final cmp = a.deliveryFee.compareTo(b.deliveryFee);
        if (cmp != 0) return cmp;
      } else if (sorts.contains(SortOption.feeHigh)) {
        final cmp = b.deliveryFee.compareTo(a.deliveryFee);
        if (cmp != 0) return cmp;
      }

      if (sorts.contains(SortOption.timeLow)) {
        final cmp =
        _parseDeliveryLower(a.deliveryTime).compareTo(_parseDeliveryLower(b.deliveryTime));
        if (cmp != 0) return cmp;
      } else if (sorts.contains(SortOption.timeHigh)) {
        final cmp =
        _parseDeliveryLower(b.deliveryTime).compareTo(_parseDeliveryLower(a.deliveryTime));
        if (cmp != 0) return cmp;
      }

      return 0;
    }

    list.sort(comparator);
    return list;
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<FilterOptions?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => FilterSheet(
        initial: FilterOptions(
          vegFilter: _activeFilters.vegFilter,
          sortOptions: _activeFilters.sortOptions,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _activeFilters = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppSearchBar(
          hintText: 'Search restaurants...',
          onChanged: (q) => setState(() => _query = q.toLowerCase()),
          onFilterPressed: _openFilterSheet,
        ),
        Expanded(
          child: BlocBuilder<RestaurantBloc, RestaurantState>(
            builder: (context, state) {
              if (state is RestaurantsLoading) {
                return _buildShimmerList(context);
              } else if (state is RestaurantsError) {
                return _EmptyState(
                  message: "Failed to load restaurants",
                  detail: state.message,
                  onRetry: () => context.read<RestaurantBloc>().add(LoadRestaurants()),
                );
              } else if (state is RestaurantsLoaded) {
                final processed = _applyFiltersAndSort(state.restaurants);

                if (processed.isEmpty) {
                  return _EmptyState(
                    message: "No restaurants found",
                    detail: "Try adjusting your search or filters.",
                    onRetry: () => context.read<RestaurantBloc>().add(LoadRestaurants()),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => _onRefresh(context),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: processed.length,
                    itemBuilder: (context, index) {
                      final r = processed[index];
                      return Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: RestaurantCard(
                          restaurant: r,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RestaurantDetailsScreen(restaurant: r),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: 6,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: RestaurantCardShimmer(),
        );
      },
    );
  }
}

/// Empty state with retry button
class _EmptyState extends StatelessWidget {
  final String message;
  final String? detail;
  final VoidCallback onRetry;

  const _EmptyState({
    required this.message,
    this.detail,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu, size: 80, color: cs.primary.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(message,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(detail!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurface.withOpacity(0.7))),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

/// Restaurant card
class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback? onTap;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    this.onTap,
  });

  Widget _buildVegBadge(VegType type) {
    switch (type) {
      case VegType.veg:
        return _VegBadge(color: Colors.green, label: 'Veg');
      case VegType.nonveg:
        return _VegBadge(color: Colors.red, label: 'Non-veg');
      case VegType.both:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _VegBadge(color: Colors.green, label: 'Veg', size: 18),
            SizedBox(width: 6),
            _VegBadge(color: Colors.red, label: 'Non', size: 18),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      elevation: 3,
      shadowColor: cs.shadow.withOpacity(0.2),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              // Image
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 104,
                    height: 104,
                    color: cs.primary.withOpacity(0.06),
                    child: restaurant.image.isNotEmpty
                        ? Image.asset(
                      restaurant.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                      const Icon(Icons.restaurant, size: 40),
                    )
                        : const Icon(Icons.restaurant, size: 40),
                  ),
                ),
              ),
              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // name + badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              restaurant.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildVegBadge(restaurant.vegType),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        restaurant.cuisine.join(', '),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.onSurface.withOpacity(0.65)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: cs.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star,
                                    size: 14, color: Colors.amber),
                                const SizedBox(width: 6),
                                Text(restaurant.rating.toStringAsFixed(1),
                                    style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('• ${restaurant.deliveryTime}',
                              style: Theme.of(context).textTheme.bodySmall),
                          const Spacer(),
                          Text('Delivery fee ₹${restaurant.deliveryFee}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right,
                              color: cs.onSurface.withOpacity(0.5)),
                        ],
                      ),
                    ],
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color, width: 1.2),
          ),
          child: Center(
            child: Container(
              width: size * 0.45,
              height: size * 0.45,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Shimmer placeholder
class RestaurantCardShimmer extends StatelessWidget {
  const RestaurantCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: cs.surfaceVariant.withOpacity(0.5),
      highlightColor: cs.surface.withOpacity(0.8),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: cs.surface,
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 16, width: 140, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 100, color: Colors.white),
                    const Spacer(),
                    Container(height: 12, width: 90, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}