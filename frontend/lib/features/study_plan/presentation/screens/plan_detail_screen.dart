import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../common_widgets/organisms/app_bar.dart';
import '../../../../theme/color_tokens.dart';
import '../../data/models/study_plan_models.dart';
import '../providers/study_plan_provider.dart';
import '../widgets/daily_schedule_timeline.dart';
import '../widgets/plan_progress_card.dart';
import '../widgets/study_calendar.dart';

/// Full plan detail with calendar and day-by-day schedule.
class PlanDetailScreen extends ConsumerWidget {
  const PlanDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(studyPlansProvider);
    final plan = plans.firstWhere(
      (p) => p.id == id,
      orElse: () => StudyPlan(
        id: '',
        config: StudyPlanConfig(
          id: '',
          examDate: _fallbackDate,
          weakSubjects: const [],
          dailyStudyMinutes: 0,
          createdAt: _fallbackDate,
        ),
        days: const [],
      ),
    );

    if (plan.id.isEmpty) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Plan Detail'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final selectedDate = ref.watch(selectedPlanDateProvider);
    final selectedDay = ref.watch(selectedDayScheduleProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: plan.config.planTitle ?? 'Study Plan',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref, plan.id),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PlanProgressCard(plan: plan),
                  const SizedBox(height: 24),
                  StudyCalendar(plan: plan),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('EEEE, MMM d').format(selectedDate),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            if (_isToday(selectedDate))
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Today',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (selectedDay != null)
                          DailyScheduleTimeline(day: selectedDay)
                        else
                          Container(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No schedule for this day.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String planId) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan?'),
        content: const Text(
          'This will permanently delete your study plan and all progress.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(studyPlansProvider.notifier).deletePlan(planId);
              context.pop();
              context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

final _fallbackDate = DateTime(2026);
