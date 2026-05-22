import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common_widgets/animations/animated_fade_slide.dart';
import '../../../../common_widgets/organisms/app_bar.dart';
import '../../../../common_widgets/organisms/empty_state.dart';
import '../../../../routing/route_names.dart';
import '../../../../theme/color_tokens.dart';
import '../../../../theme/gradients.dart';

/// Upload tab shell with CTAs for handwritten and PDF uploads.
class UploadShellScreen extends ConsumerWidget {
  const UploadShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Upload',
        showGradient: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload Your Work',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Get AI-powered feedback on handwritten answers or upload PDF chapters for study.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),
              // Handwritten Eval CTA
              AnimatedFadeSlide(
                child: _UploadCTACard(
                  icon: Icons.edit_note,
                  title: 'Handwritten Evaluation',
                  subtitle: 'Snap a photo of your handwritten answer and get instant AI feedback on spelling, grammar, and structure.',
                  buttonLabel: 'Start Evaluation',
                  gradient: AppGradients.hero,
                  onTap: () => context.push(
                    '${RouteNames.upload}/${RouteNames.uploadHandwritten}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // PDF Chapter CTA
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 100),
                child: _UploadCTACard(
                  icon: Icons.menu_book,
                  title: 'Upload PDF Chapter',
                  subtitle: 'Upload curriculum PDFs to build your personal study library and generate practice questions.',
                  buttonLabel: 'Upload PDF',
                  gradient: AppGradients.success,
                  onTap: () {},
                ),
              ),
              const SizedBox(height: 32),
              // Recent evaluations section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Evaluations',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const _RecentEvaluationsList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          '${RouteNames.upload}/${RouteNames.uploadHandwritten}',
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Upload'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

class _UploadCTACard extends StatelessWidget {
  const _UploadCTACard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        buttonLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentEvaluationsList extends StatelessWidget {
  const _RecentEvaluationsList();

  @override
  Widget build(BuildContext context) {
    // Mock: no recent evaluations yet
    return const EmptyState(
      icon: Icons.history,
      title: 'No evaluations yet',
      message: 'Your recent handwritten evaluations will appear here.',
    );
  }
}
