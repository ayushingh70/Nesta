# Nesta — Food ordering workflow

A small Flutter app that demonstrates a single realistic food-ordering workflow:
browse restaurants → view menu → add to cart → checkout (address) → order confirmation → order history.

## Screenshots

<p float="left">
  <img src="https://github.com/user-attachments/assets/b84c7124-2f37-4213-bf2a-f61f5f0e2d71" width="300" />
  <img src="https://github.com/user-attachments/assets/39efe9c0-30ea-4478-991a-55ecc9ce2d4d" width="300" style="margin-left: 20px;" />
</p>


## Features implemented
- BLoC architecture for state management (restaurants, cart, orders).
- Realistic ordering workflow.
- Error handling for persistence, empty cart, invalid address etc.
- Clean code structure following SOLID where services/repositories and UI are separated.
- Theming and UI polish.

## Getting started

Prerequisites:
- Flutter SDK (>= 3.0)
- Android Studio / Xcode / VS Code

Run the app:

```bash
flutter pub get
flutter run    # or choose an emulator/device
