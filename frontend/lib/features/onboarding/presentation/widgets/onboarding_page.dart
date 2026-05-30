import 'package:flutter/material.dart';

import '../../../../theme/color_tokens.dart';
import '../../../../theme/neu_decoration.dart';
import '../../../../common_widgets/animations/animated_fade_slide.dart';

/// Single onboarding page with an illustrated header, title, and description.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.delay = Duration.zero,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          AnimatedFadeSlide(
            delay: delay,
            child: Container(
              width: 180,
              height: 180,
              decoration: NeuDecoration.colored(
                color: color,
                radius: 90,
              ),
              child: Icon(
                icon,
                size: 72,
                color: color == AppColors.warning
                    ? AppColors.textPrimary
                    : Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 48),
          AnimatedFadeSlide(
            delay: delay + const Duration(milliseconds: 150),
            child: Text(
              title,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedFadeSlide(
            delay: delay + const Duration(milliseconds: 300),
            child: Text(
              description,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                    fontWeight: FontWeight.normal,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
