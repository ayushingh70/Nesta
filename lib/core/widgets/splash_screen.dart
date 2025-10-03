// lib/core/widgets/splash_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:nestafar/app_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _decorController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _textFadeAnim;

  @override
  void initState() {
    super.initState();

    // Logo animations
    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scaleAnim = CurvedAnimation(parent: _logoController, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _logoController, curve: Curves.easeIn);

    // Text animations
    _textController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _textFadeAnim = CurvedAnimation(parent: _textController, curve: Curves.easeIn);

    // Decorative (looping) animation
    _decorController = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _decorController.repeat(reverse: true);

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _textController.forward();
    });

    // Navigate after 3 seconds
    Timer(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, __, ___) => const AppShell(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ));
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _decorController.dispose();
    super.dispose();
  }

  // Helper to build decorative floating icon positioned widgets
  Widget _floatingIcon({
    required double left,
    required double top,
    required double size,
    required IconData icon,
    required Color color,
    required double offsetFactor,
  }) {
    return AnimatedBuilder(
      animation: _decorController,
      builder: (_, __) {
        // subtle drifting using a sin wave
        final t = _decorController.value;
        final dx = math.sin((t * math.pi * 2) + offsetFactor) * 6;
        final dy = math.cos((t * math.pi * 2) + offsetFactor) * 6;
        return Positioned(
          left: left + dx,
          top: top + dy,
          child: Opacity(
            opacity: 0.12 + 0.18 * (0.5 + 0.5 * math.sin((t * math.pi * 2) + offsetFactor)),
            child: Transform.rotate(
              angle: (t - 0.5) * 0.2,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(size * 0.4),
                ),
                child: Icon(icon, size: size * 0.55, color: Colors.white.withOpacity(0.95)),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // layered gradient background for depth
          gradient: LinearGradient(
            colors: [
              cs.primary.withOpacity(0.96),
              cs.primary.withOpacity(0.68),
              cs.surface,
            ],
            begin: Alignment(-1.0, -0.3),
            end: Alignment(0.8, 1.0),
          ),
        ),
        child: Stack(
          children: [
            // Soft circular decorative blobs (subtle)
            Positioned(
              left: -70,
              top: -40,
              child: AnimatedBuilder(
                animation: _decorController,
                builder: (_, __) {
                  final scale = 1.0 + 0.06 * math.sin(_decorController.value * math.pi * 2);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        color: cs.onPrimary.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(120),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              right: -60,
              bottom: -80,
              child: AnimatedBuilder(
                animation: _decorController,
                builder: (_, __) {
                  final scale = 1.0 + 0.08 * math.cos(_decorController.value * math.pi * 2);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: cs.onPrimary.withOpacity(0.025),
                        borderRadius: BorderRadius.circular(90),
                      ),
                    ),
                  );
                },
              ),
            ),

            // floating food-icon tiles
            _floatingIcon(
              left: 40,
              top: 90,
              size: 46,
              icon: Icons.local_pizza,
              color: cs.primary.withOpacity(0.85),
              offsetFactor: 0.2,
            ),
            _floatingIcon(
              left: 24,
              top: 260,
              size: 34,
              icon: Icons.ramen_dining,
              color: cs.primary.withOpacity(0.75),
              offsetFactor: 1.1,
            ),
            _floatingIcon(
              left: 220,
              top: 160,
              size: 40,
              icon: Icons.icecream,
              color: cs.primary.withOpacity(0.65),
              offsetFactor: 2.6,
            ),
            _floatingIcon(
              left: 260,
              top: 40,
              size: 38,
              icon: Icons.coffee,
              color: cs.primary.withOpacity(0.6),
              offsetFactor: 3.9,
            ),
            _floatingIcon(
              left: 120,
              top: 340,
              size: 44,
              icon: Icons.fastfood,
              color: cs.primary.withOpacity(0.7),
              offsetFactor: 0.8,
            ),

            // center content (logo + title)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Container(
                        height: 140,
                        width: 140,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [cs.primary, cs.primary.withOpacity(0.85)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withOpacity(0.36),
                              blurRadius: 24,
                              spreadRadius: 4,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Image.asset(
                            "assets/logo.png",
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _textFadeAnim,
                    child: Text(
                      "Nestafar",
                      style: textTheme.headlineMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: _textFadeAnim,
                    child: Text(
                      "Food Delivery Simplified",
                      style: textTheme.bodyLarge?.copyWith(
                        color: cs.onSurface.withOpacity(0.82),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}