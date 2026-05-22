import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../common_widgets/animations/animated_fade_slide.dart';
import '../../../../common_widgets/organisms/app_bar.dart';
import '../../../../common_widgets/organisms/empty_state.dart';
import '../../../../routing/route_names.dart';
import '../../../../theme/color_tokens.dart';
import '../../../../theme/gradients.dart';
import '../../data/models/study_plan_models.dart';
import '../providers/study_plan_provider.dart';
import '../widgets/daily_schedule_timeline.dart';
import '../widgets/plan_progress_card.dart';
import '../widgets/plan_summary_card.dart';
import '../widgets/study_calendar.dart';

/// Plan tab shell — shows today's schedule, progress, and plan management.
class PlanShellScreen extends ConsumerWidget {
  const PlanShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(studyPlansProvider);
    final activePlan = ref.watch(activePlanProvider);
    final selectedDate = ref.watch(selectedPlanDateProvider);
    final selectedDay = ref.watch(selectedDayScheduleProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Study Plan',
        showGradient: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.calendar_month, color: Colors.white),
          ),
        ],
      ),
      body: plans.isEmpty
          ? _EmptyPlansView(onCreate: () => _goToCreate(context))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (activePlan != null) ...[
                          AnimatedFadeSlide(
                            child: PlanProgressCard(plan: activePlan),
                          ),
                          const SizedBox(height: 24),
                          AnimatedFadeSlide(
                            delay: const Duration(milliseconds: 100),
                            child: StudyCalendar(plan: activePlan),
                          ),
                          const SizedBox(height: 24),
                          AnimatedFadeSlide(
                            delay: const Duration(milliseconds: 200),
                            child: _DayHeader(
                              date: selectedDate,
                              daySchedule: selectedDay,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (selectedDay != null)
                            DailyScheduleTimeline(day: selectedDay),
                          const SizedBox(height: 24),
                        ],
                        // Other plans
                        if (plans.length > 1) ...[
                          Text(
                            'Other Plans',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 12),
                          ...plans.where((p) => p.id != activePlan?.id).map(
                            (plan) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: PlanSummaryCard(
                                config: plan.config,
                                onTap: () => _activatePlan(ref, plan),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () => _goToCreate(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Create New Plan'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _goToCreate(BuildContext context) {
    context.push('${RouteNames.plan}/${RouteNames.planCreate}');
  }

  void _activatePlan(WidgetRef ref, StudyPlan plan) {
    // Deactivate all, activate selected
    final allPlans = ref.read(studyPlansProvider);
    for (final p in allPlans) {
      final updated = p.copyWith(isActive: p.id == plan.id);
      ref.read(studyPlanRepositoryProvider).updatePlan(updated);
    }
    ref.invalidate(studyPlansProvider);
  }
}

class _EmptyPlansView extends StatelessWidget {
  const _EmptyPlansView({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(
          child: EmptyState(
            icon: Icons.calendar_month_outlined,
            title: 'No Study Plan Yet',
            message:
                'Create a personalized study plan to track your progress and stay on schedule.',
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create Study Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date, this.daySchedule});

  final DateTime date;
  final StudyDay? daySchedule;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isToday
                    ? 'Today\'s Schedule'
                    : DateFormat('EEEE, MMM d').format(date),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (daySchedule != null && !daySchedule!.isRestDay) ...[
                const SizedBox(height: 4),
                Text(
                  '${daySchedule!.tasks.length} tasks · ${daySchedule!.totalMinutes} minutes',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ],
          ),
        ),
        if (isToday)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: AppGradients.hero,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Today',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
      ],
    );
  }
}
