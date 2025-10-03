// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'app_shell.dart';

// NEW: Splash screen
import 'core/widgets/splash_screen.dart';

void main() {
  runApp(const NestafarApp());
}

class NestafarApp extends StatelessWidget {
  const NestafarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ThemeCubit(),
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Nestafar',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

/// Cubit for toggling light/dark theme
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);

  void toggle() {
    if (state == ThemeMode.light) {
      emit(ThemeMode.dark);
    } else {
      emit(ThemeMode.light);
    }
  }
}