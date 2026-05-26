import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/route_names.dart';
import '../../../../theme/gradients.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Animated splash screen that decides where to route the user.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _pulseController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoRotate;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const ElasticOutCurve(0.7),
      ),
    );
    _logoRotate = Tween<double>(begin: -0.3, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _textFade = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 16),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic));
    _pulse = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    await _textController.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _routeNext();
  }

  void _routeNext() {
    try {
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      final isOnboarded = ref.read(isOnboardedProvider);

      if (isAuthenticated) {
        context.go(RouteNames.home);
      } else if (isOnboarded) {
        context.go(RouteNames.register);
      } else {
        context.go(RouteNames.onboarding);
      }
    } catch (e, st) {
      log('Splash routing error', error: e, stackTrace: st);
      context.go(RouteNames.onboarding);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.hero),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Decorative pulsing circles
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulse.value,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                );
              },
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoScale.value,
                      child: Transform.rotate(
                        angle: _logoRotate.value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // App name
                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Column(
                      children: [
                        Text(
                          'ShikkhaAI',
                          style:
                              Theme.of(context).textTheme.displayLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'AI-powered study companion',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Bottom version
            Positioned(
              bottom: 48,
              child: FadeTransition(
                opacity: _textFade,
                child: Text(
                  'v1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
