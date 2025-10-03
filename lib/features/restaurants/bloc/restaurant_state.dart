// lib/features/restaurants/bloc/restaurant_state.dart
import 'package:equatable/equatable.dart';
import '../data/models/restaurant.dart';

abstract class RestaurantState extends Equatable {
  const RestaurantState();

  @override
  List<Object?> get props => [];
}

class RestaurantsLoading extends RestaurantState {}

class RestaurantsLoaded extends RestaurantState {
  final List<Restaurant> restaurants;

  const RestaurantsLoaded(this.restaurants);

  @override
  List<Object?> get props => [restaurants];
}

class RestaurantsError extends RestaurantState {
  final String message;

  const RestaurantsError(this.message);

  @override
  List<Object?> get props => [message];
}