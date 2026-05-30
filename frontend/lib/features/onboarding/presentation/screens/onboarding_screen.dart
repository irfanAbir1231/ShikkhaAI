import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common_widgets/atoms/app_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/route_names.dart';
import '../../../../theme/color_tokens.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/onboarding_page.dart';

/// Multi-page onboarding flow with animated transitions.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pageCount = 3;

  List<_PageData> _pages(AppLocalizations l10n) => [
        _PageData(
          icon: Icons.auto_stories_rounded,
          title: l10n.onboard1Title,
          description: l10n.onboard1Desc,
          color: AppColors.primary,
        ),
        _PageData(
          icon: Icons.psychology_alt_rounded,
          title: l10n.onboard2Title,
          description: l10n.onboard2Desc,
          color: AppColors.success,
        ),
        _PageData(
          icon: Icons.trending_up_rounded,
          title: l10n.onboard3Title,
          description: l10n.onboard3Desc,
          color: AppColors.warning,
        ),
      ];

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  void _next() {
    if (_currentPage < _pageCount - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  Future<void> _finish() async {
    await ref.read(authRepositoryProvider).markOnboarded();
    if (mounted) context.go(RouteNames.register);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = _pages(l10n);
    final isLast = _currentPage == _pageCount - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            AnimatedOpacity(
              opacity: isLast ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 16),
                  child: TextButton(
                    onPressed: isLast ? null : _skip,
                    child: Text(l10n.onboardSkip),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: _onPageChanged,
                itemCount: _pageCount,
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return OnboardingPage(
                    icon: page.icon,
                    title: page.title,
                    description: page.description,
                    color: page.color,
                    delay: const Duration(milliseconds: 100),
                  );
                },
              ),
            ),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pageCount, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 28 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.divider,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: isLast ? l10n.onboardGetStarted : l10n.commonNext,
                    onPressed: _next,
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

class _PageData {
  const _PageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
}
