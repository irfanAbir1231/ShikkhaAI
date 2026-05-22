import 'package:flutter/material.dart';

import '../../../../theme/color_tokens.dart';
import '../../../../theme/gradients.dart';

/// Full-screen animated OCR scanner with progress steps.
class OcrProcessingAnimation extends StatefulWidget {
  const OcrProcessingAnimation({super.key});

  @override
  State<OcrProcessingAnimation> createState() => _OcrProcessingAnimationState();
}

class _OcrProcessingAnimationState extends State<OcrProcessingAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _scanController;
  late final AnimationController _pulseController;
  late final Animation<double> _scanLine;
  late final Animation<double> _pulse;

  final _steps = [
    ('Uploading Image...', Icons.cloud_upload),
    ('OCR Processing...', Icons.document_scanner),
    ('AI Evaluating...', Icons.psychology),
  ];

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _scanLine = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    _pulse = Tween<double>(begin: 0.8, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Scanner animation
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulse.value,
                child: Container(
                  width: 160,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      width: 2,
                    ),
                    color: AppColors.primary.withValues(alpha: 0.05),
                  ),
                  child: Stack(
                    children: [
                      // Paper lines
                      Positioned.fill(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            5,
                            (_) => Container(
                              height: 2,
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              color: AppColors.divider,
                            ),
                          ),
                        ),
                      ),
                      // Scanning line
                      AnimatedBuilder(
                        animation: _scanLine,
                        builder: (context, child) {
                          return Positioned(
                            top: _scanLine.value * 180,
                            left: 8,
                            right: 8,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: AppGradients.hero,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          // Step indicators
          ..._steps.asMap().entries.map((entry) {
            final index = entry.key;
            final (label, icon) = entry.value;
            return _StepRow(
              label: label,
              icon: icon,
              isActive: index <= 1, // animate through steps
              delay: Duration(milliseconds: index * 600),
            );
          }),
          const SizedBox(height: 32),
          // Loading dots
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _BouncingDot(delay: 0),
              SizedBox(width: 8),
              _BouncingDot(delay: 150),
              SizedBox(width: 8),
              _BouncingDot(delay: 300),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatefulWidget {
  const _StepRow({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.delay,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final Duration delay;

  @override
  State<_StepRow> createState() => _StepRowState();
}

class _StepRowState extends State<_StepRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 48),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.divider.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.isActive
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                widget.label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: widget.isActive
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight:
                          widget.isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
              const Spacer(),
              if (widget.isActive)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BouncingDot extends StatefulWidget {
  const _BouncingDot({required this.delay});

  final int delay;

  @override
  State<_BouncingDot> createState() => _BouncingDotState();
}

class _BouncingDotState extends State<_BouncingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -8 * _controller.value),
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
