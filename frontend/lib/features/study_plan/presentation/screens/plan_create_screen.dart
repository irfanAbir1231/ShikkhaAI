import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../common_widgets/organisms/app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/route_names.dart';
import '../../../../theme/color_tokens.dart';
import '../../../../theme/neu_decoration.dart';
import '../../data/models/study_plan_models.dart';
import '../providers/study_plan_provider.dart';
import '../widgets/weak_subject_picker.dart';

/// Multi-step wizard to create a new study plan.
class PlanCreateScreen extends ConsumerStatefulWidget {
  const PlanCreateScreen({super.key});

  @override
  ConsumerState<PlanCreateScreen> createState() => _PlanCreateScreenState();
}

class _PlanCreateScreenState extends ConsumerState<PlanCreateScreen> {
  int _currentStep = 0;
  DateTime _examDate = DateTime.now().add(const Duration(days: 30));
  final List<String> _selectedSubjects = [];
  double _dailyMinutes = 120;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.planCreateTitle,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step indicator
            _StepIndicator(currentStep: _currentStep, totalSteps: 3),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStepContent(),
                ),
              ),
            ),
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentStep--),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.divider),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(l10n.commonBack),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: _currentStep == 0 ? 1 : 2,
                    child: ElevatedButton(
                      onPressed: _isGenerating ? null : _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      child: _isGenerating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _currentStep == 2 ? l10n.planGenerate : l10n.commonNext,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _StepExamDate(
          examDate: _examDate,
          onChanged: (date) => setState(() => _examDate = date),
        );
      case 1:
        return WeakSubjectPicker(
          selectedSubjects: _selectedSubjects,
          onSelectionChanged: (subjects) {
            setState(() {
              _selectedSubjects
                ..clear()
                ..addAll(subjects);
            });
          },
        );
      case 2:
        return _StepDailyTime(
          dailyMinutes: _dailyMinutes,
          onChanged: (minutes) => setState(() => _dailyMinutes = minutes),
          examDate: _examDate,
          subjects: _selectedSubjects,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _onNext() async {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      return;
    }

    setState(() => _isGenerating = true);

    final config = StudyPlanConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      examDate: _examDate,
      weakSubjects: _selectedSubjects.isEmpty
          ? ['General Study']
          : _selectedSubjects,
      dailyStudyMinutes: _dailyMinutes.round(),
      createdAt: DateTime.now(),
      planTitle: 'Exam Prep Plan',
    );

    final plan = await ref
        .read(studyPlansProvider.notifier)
        .createPlan(config);

    if (mounted) {
      setState(() => _isGenerating = false);
      context.push('${RouteNames.plan}/detail/${plan.id}');
    }
  }
}

// ------------------------------------------------------------------
// Step 1: Exam Date
// ------------------------------------------------------------------
class _StepExamDate extends StatelessWidget {
  const _StepExamDate({
    required this.examDate,
    required this.onChanged,
  });

  final DateTime examDate;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final daysLeft = examDate.difference(DateTime.now()).inDays;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.planWhenExam,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.planWhenExamDesc,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$daysLeft',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.planDaysLeftStacked,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.2,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                DateFormat('EEEE, MMMM d, yyyy').format(examDate),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () => _pickDate(context),
            icon: const Icon(Icons.calendar_today),
            label: Text(l10n.planChangeDate),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: examDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onChanged(picked);
    }
  }
}

// ------------------------------------------------------------------
// Step 3: Daily Time
// ------------------------------------------------------------------
class _StepDailyTime extends StatelessWidget {
  const _StepDailyTime({
    required this.dailyMinutes,
    required this.onChanged,
    required this.examDate,
    required this.subjects,
  });

  final double dailyMinutes;
  final ValueChanged<double> onChanged;
  final DateTime examDate;
  final List<String> subjects;

  @override
  Widget build(BuildContext context) {
    final hours = dailyMinutes / 60;
    final daysLeft = examDate.difference(DateTime.now()).inDays;
    final totalHours = (dailyMinutes * daysLeft) / 60;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.planDailyTimeQuestion,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.planDailyTimeDesc,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: NeuDecoration.colored(
            color: AppColors.primary,
            radius: 20,
          ),
          child: Column(
            children: [
              Text(
                hours == hours.toInt().toDouble()
                    ? '${hours.toInt()}h'
                    : '${hours.toStringAsFixed(1)}h',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.planMinutesPerDay(dailyMinutes.toInt()),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
              ),
              const SizedBox(height: 16),
              Slider(
                value: dailyMinutes,
                min: 30,
                max: 360,
                divisions: 11,
                onChanged: onChanged,
                activeColor: Colors.white,
                inactiveColor: Colors.white.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _PreviewRow(
                label: l10n.planStudyDuration,
                value: l10n.planDaysValue(daysLeft),
              ),
              const Divider(),
              _PreviewRow(
                label: l10n.planDailyStudyTime,
                value: l10n.minutesShort(dailyMinutes.toInt()),
              ),
              const Divider(),
              _PreviewRow(
                label: l10n.planTotalStudyHours,
                value: l10n.planHoursValue(totalHours.toStringAsFixed(0)),
              ),
              const Divider(),
              _PreviewRow(
                label: l10n.planSubjectsLabel,
                value: subjects.isEmpty ? l10n.planGeneralStudy : subjects.join(', '),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const Spacer(),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// Step Indicator
// ------------------------------------------------------------------
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isActive = index <= currentStep;
          final isCurrent = index == currentStep;

          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < totalSteps - 1 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: isActive
                    ? (isCurrent ? AppColors.primary : AppColors.primary.withValues(alpha: 0.5))
                    : AppColors.divider.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
