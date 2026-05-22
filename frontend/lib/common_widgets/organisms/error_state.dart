import 'package:flutter/material.dart';

import '../../core/errors/failures.dart';
import '../../theme/color_tokens.dart';
import '../atoms/app_button.dart';

/// Icon + error message + retry button for failure states.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.failure,
    this.message,
    this.onRetry,
  });

  final Failure? failure;
  final String? message;
  final VoidCallback? onRetry;

  String get _message {
    if (message != null) return message!;
    if (failure != null) return failure!.message;
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.danger.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Oops!',
              style: textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _message,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              AppButton(
                label: 'Try Again',
                variant: AppButtonVariant.secondary,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
