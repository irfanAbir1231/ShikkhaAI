import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../common_widgets/animations/animated_fade_slide.dart';
import '../../../../common_widgets/organisms/app_bar.dart';
import '../../../../common_widgets/organisms/empty_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/route_names.dart';
import '../../../../theme/color_tokens.dart';
import '../../../../theme/neu_decoration.dart';
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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.drawerStudyPlan,
        showGradient: true,
        actions: const [
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
                            l10n.planOtherPlans,
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
                            label: Text(l10n.planCreateNew),
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
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Expanded(
          child: EmptyState(
            icon: Icons.calendar_month_outlined,
            title: l10n.planNoPlansTitle,
            message: l10n.planNoPlansMsg,
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
              label: Text(l10n.planCreatePlan),
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
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isToday
                    ? l10n.planTodaysSchedule
                    : DateFormat('EEEE, MMM d').format(date),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              if (daySchedule != null && !daySchedule!.isRestDay) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.planTasksMinutes(
                      daySchedule!.tasks.length, daySchedule!.totalMinutes),
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
            decoration: NeuDecoration.colored(
              color: AppColors.primary,
              radius: 20,
            ),
            child: Text(
              l10n.planToday,
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
