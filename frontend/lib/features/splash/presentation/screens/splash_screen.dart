import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/route_names.dart';
import '../../../../theme/color_tokens.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Skeuomorphic splash — raised emblem plate on a soft gradient base,
/// orbiting glow ring, and staggered title reveal.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _orbitController;
  late final AnimationController _shineController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoLift;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  bool _connectionError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _logoScale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Cubic(0.2, 0.9, 0.3, 1.4),
      ),
    );
    _logoLift = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );
    _textFade = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 250));
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    await _textController.forward();
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    await _checkHealth();
  }

  Future<void> _checkHealth() async {
    setState(() {
      _connectionError = false;
      _errorMessage = '';
    });

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      await dio.get<dynamic>('/health');
      if (!mounted) return;
      _routeNext();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _connectionError = true;
        _errorMessage = 'Cannot connect to server at ${ApiConstants.baseUrl}.\n'
            'Please make sure the backend is running on the same network.\n\n'
            'Error: $e';
      });
    }
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
    _orbitController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Container(
        decoration: const BoxDecoration(color: AppColors.surface),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Soft pastel-blue background wash (faint shape overlay).
            const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
              ),
              child: SizedBox.expand(),
            ),

            // Orbiting glow ring
            AnimatedBuilder(
              animation: _orbitController,
              builder: (context, _) {
                return Transform.rotate(
                  angle: _orbitController.value * 2 * math.pi,
                  child: CustomPaint(
                    size: const Size(320, 320),
                    painter: _OrbitPainter(),
                  ),
                );
              },
            ),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Skeumorphic emblem plate
                AnimatedBuilder(
                  animation: Listenable.merge([_logoController, _shineController]),
                  builder: (context, child) {
                    final lift = _logoLift.value;
                    return Transform.translate(
                      offset: Offset(0, (1 - lift) * 16),
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: _EmblemPlate(shine: _shineController.value),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 36),

                // Title
                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Column(
                      children: [
                        Text(
                          AppLocalizations.of(context).appName,
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 40,
                                letterSpacing: 0.5,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            AppLocalizations.of(context).splashTagline,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.2,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Bottom progress + version (or connection error)
            Positioned(
              bottom: 56,
              left: 24,
              right: 24,
              child: FadeTransition(
                opacity: _textFade,
                child: _connectionError
                    ? Column(
                        children: [
                          const Icon(
                            Icons.wifi_off_rounded,
                            color: AppColors.danger,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Connection Failed',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w700,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                            textAlign: TextAlign.center,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _checkHealth,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation(AppColors.primary),
                              backgroundColor: AppColors.primarySoft,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            AppLocalizations.of(context).appVersionShort,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textTertiary,
                                      letterSpacing: 1.0,
                                    ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Convex emblem plate — paired highlight + shadow with rotating sheen.
class _EmblemPlate extends StatelessWidget {
  const _EmblemPlate({required this.shine});

  final double shine;

  @override
  Widget build(BuildContext context) {
    const size = 128.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFB87A4B),
            Color(0xFF8B5A2B),
            Color(0xFF6B3E1F),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        border: Border.all(
          color: const Color(0xFFC19A6B).withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B3E1F).withValues(alpha: 0.4),
            offset: const Offset(0, 4),
            blurRadius: 10,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: const Color(0xFFC19A6B).withValues(alpha: 0.2),
            offset: const Offset(0, -2),
            blurRadius: 4,
            spreadRadius: -1,
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Subtle solid sheen overlay.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Image.asset(
              'assets/images/logos/logo_256.png',
              width: 72,
              height: 72,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.primary.withValues(alpha: 0.10);
    canvas.drawCircle(center, radius, ring);

    final ring2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.primary.withValues(alpha: 0.06);
    canvas.drawCircle(center, radius - 28, ring2);

    for (var i = 0; i < 3; i++) {
      final angle = i * (2 * math.pi / 3);
      final dx = center.dx + radius * math.cos(angle);
      final dy = center.dy + radius * math.sin(angle);
      final dot = Paint()..color = AppColors.primary;
      canvas.drawCircle(Offset(dx, dy), 4, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
