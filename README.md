# Nestafar — Food ordering workflow (Flutter)

A small Flutter app that demonstrates a single realistic food-ordering workflow:
browse restaurants → view menu → add to cart → checkout (address) → order confirmation → order history.

## Screenshots

![Restaurants](/screenshots/restaurants.png)
![Cart](/screenshots/cart.png)
![Order Confirmation](/screenshots/confirmation.png)

> Add at least one screenshot under `screenshots/` directory.

## Features implemented (assignment checklist)
- BLoC architecture for state management (restaurants, cart, orders).
- Realistic ordering workflow.
- Error handling for persistence, empty cart, invalid address etc.
- Clean code structure following SOLID where services/repositories and UI are separated.
- Unit tests for BLoC and storage layers (run with `flutter test`).
- Theming and UI polish.

## Getting started

Prerequisites:
- Flutter SDK (>= 3.0)
- Android Studio / Xcode / VS Code

Run the app:

```bash
flutter pub get
flutter run    # or choose an emulator/device
