import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common_widgets/animations/animated_fade_slide.dart';
import '../../../../common_widgets/animations/animated_scale_tap.dart';
import '../../../../common_widgets/atoms/app_button.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../routing/route_names.dart';
import '../../../../theme/color_tokens.dart';
import '../../../../theme/gradients.dart';
import '../providers/auth_providers.dart';

/// Class selection screen with animated grid cards.
class ClassSelectionScreen extends ConsumerStatefulWidget {
  const ClassSelectionScreen({super.key});

  @override
  ConsumerState<ClassSelectionScreen> createState() =>
      _ClassSelectionScreenState();
}

class _ClassSelectionScreenState extends ConsumerState<ClassSelectionScreen> {
  String? _selectedGrade;

  Future<void> _completeRegistration() async {
    if (_selectedGrade == null) return;

    final name = ref.read(registrationNameProvider);
    final email = ref.read(registrationEmailProvider);

    try {
      await ref.read(registerStudentProvider.notifier).register(
            name: name,
            email: email,
            gradeLevel: _selectedGrade!,
          );

      if (mounted) {
        context.go(RouteNames.home);
      }
    } catch (_) {
      // Error is surfaced via the provider; show a snackbar.
      if (mounted) {
        final state = ref.read(registerStudentProvider);
        state.whenOrNull(
          error: (error, _) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error.toString()),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.danger,
              ),
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final registrationState = ref.watch(registerStudentProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              AnimatedFadeSlide(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppGradients.hero,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.class_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 100),
                child: Text(
                  'Select Your Class',
                  style: textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Choose your current class so we can tailor content to your curriculum.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: AnimatedFadeSlide(
                  delay: const Duration(milliseconds: 300),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: AppConstants.gradeLevels.map((grade) {
                      final isSelected = grade == _selectedGrade;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: AnimatedScaleTap(
                          onTap: () =>
                              setState(() => _selectedGrade = grade),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: isSelected ? AppGradients.hero : null,
                              color: isSelected
                                  ? null
                                  : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : AppColors.divider,
                                width: 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.25),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 8),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 20),
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.2)
                                        : AppColors.primary
                                            .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.school_outlined,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.primary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        grade,
                                        style: textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${AppConstants.subjects.length} subjects available',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: isSelected
                                              ? Colors.white
                                                  .withValues(alpha: 0.85)
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AnimatedScale(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  scale: isSelected ? 1.0 : 0.0,
                                  child: const Padding(
                                    padding: EdgeInsets.only(right: 20),
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 400),
                child: AppButton(
                  label: 'Complete Registration',
                  isLoading: registrationState.isLoading,
                  onPressed:
                      _selectedGrade != null ? _completeRegistration : null,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
