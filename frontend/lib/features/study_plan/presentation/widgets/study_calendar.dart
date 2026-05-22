import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../theme/color_tokens.dart';
import '../../data/models/study_plan_models.dart';
import '../providers/study_plan_provider.dart';

/// Custom month calendar grid for study plans.
class StudyCalendar extends ConsumerWidget {
  const StudyCalendar({super.key, required this.plan});

  final StudyPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedPlanDateProvider);
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            DateFormat('MMMM yyyy').format(currentMonth),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
        _buildMonthGrid(context, ref, currentMonth, selectedDate),
      ],
    );
  }

  Widget _buildMonthGrid(
    BuildContext context,
    WidgetRef ref,
    DateTime month,
    DateTime selectedDate,
  ) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = firstDayOfMonth.weekday % 7;

    final cells = <Widget>[];

    // Empty cells before the 1st
    for (var i = 0; i < firstWeekday; i++) {
      cells.add(const Expanded(child: SizedBox()));
    }

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final isSelected = _isSameDay(date, selectedDate);
      final isToday = _isSameDay(date, DateTime.now());
      final daySchedule = plan.days.firstWhere(
        (d) => _isSameDay(d.date, date),
        orElse: () => StudyDay(date: date, tasks: const []),
      );

      cells.add(
        Expanded(
          child: GestureDetector(
            onTap: () {
              ref.read(selectedPlanDateProvider.notifier).state = date;
            },
            child: Container(
              height: 48,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isToday
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected || isToday
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                  ),
                  if (daySchedule.tasks.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _buildTaskDots(daySchedule.tasks),
                    ),
                  ] else if (daySchedule.isRestDay) ...[
                    const SizedBox(height: 2),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      final end = i + 7 > cells.length ? cells.length : i + 7;
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: cells.sublist(i, end)),
        ),
      );
    }

    return Column(children: rows);
  }

  List<Widget> _buildTaskDots(List<StudyTask> tasks) {
    final uniqueSubjects = tasks.map((t) => t.subject).toSet().toList();
    final colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.success,
      AppColors.warning,
      AppColors.danger,
    ];

    return uniqueSubjects.take(3).map((subject) {
      final index = uniqueSubjects.indexOf(subject) % colors.length;
      return Container(
        width: 4,
        height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: colors[index],
          shape: BoxShape.circle,
        ),
      );
    }).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
