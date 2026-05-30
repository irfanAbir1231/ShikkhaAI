import 'package:flutter/material.dart';

import '../../../../common_widgets/molecules/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/color_tokens.dart';

import '../../data/models/analytics_models.dart';

/// Calendar-style streak visualization with flame icons and day badges.
class StreakCalendar extends StatelessWidget {
  const StreakCalendar({super.key, required this.data});

  final DailyStreakData data;

  @override
  Widget build(BuildContext context) {
    final days = data.last30Days;
    final l10n = AppLocalizations.of(context);
    final weekDayLabels = l10n.analyticsWeekdayInitialsSun.split(',');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                l10n.streakDailyStreak,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFF8B5A2B),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.streakDaysShort(data.currentStreak),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StreakStat(
                    value: data.currentStreak.toString(),
                    label: l10n.streakCurrent,
                    icon: Icons.local_fire_department,
                    iconColor: AppColors.primary,
                  ),
                  _StreakStat(
                    value: data.longestStreak.toString(),
                    label: l10n.streakBest,
                    icon: Icons.emoji_events,
                    iconColor: AppColors.success,
                  ),
                  _StreakStat(
                    value: '${days.where((d) => d.isActive).length}',
                    label: l10n.streakActive,
                    icon: Icons.check_circle,
                    iconColor: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Day labels
              Row(
                children: weekDayLabels
                    .map(
                      (label) => Expanded(
                        child: Center(
                          child: Text(
                            label,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              // Calendar grid
              ..._buildWeekRows(days, context),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildWeekRows(
    List<DailyActivity> days,
    BuildContext context,
  ) {
    final rows = <Widget>[];
    for (var i = 0; i < days.length; i += 7) {
      final weekDays = days.sublist(
        i,
        i + 7 > days.length ? days.length : i + 7,
      );
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: weekDays.map((day) {
              return Expanded(child: _DayCell(day: day));
            }).toList(),
          ),
        ),
      );
    }
    return rows;
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day});

  final DailyActivity day;

  @override
  Widget build(BuildContext context) {
    final isToday = _isSameDay(day.date, DateTime.now());

    return Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: day.isActive
              ? AppColors.success.withValues(alpha: 0.15)
              : (isToday
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent),
          shape: BoxShape.circle,
          border: isToday
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Center(
          child: day.isActive
              ? const Icon(
                  Icons.local_fire_department,
                  color: AppColors.primary,
                  size: 18,
                )
              : Text(
                  '${day.date.day}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _StreakStat extends StatelessWidget {
  const _StreakStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
