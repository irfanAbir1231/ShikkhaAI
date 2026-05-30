import 'package:flutter/material.dart';

import '../../../../common_widgets/molecules/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/color_tokens.dart';
import '../../data/models/dashboard_models.dart';

/// Daily streak card with flame icon and weekly activity dots.
class DailyStreakCard extends StatelessWidget {
  const DailyStreakCard({super.key, required this.data});

  final StreakData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final days = l10n.dashWeekdayInitials.split(',');
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: AppColors.warning,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dashDayStreak(data.currentStreak),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.dashLongestStreak(data.longestStreak),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final active = data.weeklyActivity[index];
              return Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: active ? AppColors.warning : AppColors.divider,
                      shape: BoxShape.circle,
                    ),
                    child: active
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          )
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    days[index],
                    style: TextStyle(
                      color: active
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
