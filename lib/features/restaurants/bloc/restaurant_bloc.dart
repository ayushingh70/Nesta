// lib/features/restaurants/bloc/restaurant_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'restaurant_event.dart';
import 'restaurant_state.dart';
import '../data/repositories/restaurant_repository.dart';

class RestaurantBloc extends Bloc<RestaurantEvent, RestaurantState> {
  final RestaurantRepository repository;

  RestaurantBloc({required this.repository}) : super(RestaurantsLoading()) {
    on<LoadRestaurants>((event, emit) async {
      emit(RestaurantsLoading());
      try {
        final restaurants = await repository.loadRestaurants();
        emit(RestaurantsLoaded(restaurants));
      } catch (e) {
        emit(RestaurantsError(e.toString()));
      }
    });
  }
}