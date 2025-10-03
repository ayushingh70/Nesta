// lib/features/restaurants/bloc/restaurant_event.dart
import 'package:equatable/equatable.dart';

abstract class RestaurantEvent extends Equatable {
  const RestaurantEvent();

  @override
  List<Object?> get props => [];
}

/// Trigger loading of restaurants from repository
class LoadRestaurants extends RestaurantEvent {}