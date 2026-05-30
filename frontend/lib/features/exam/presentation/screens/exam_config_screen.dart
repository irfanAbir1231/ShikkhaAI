import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common_widgets/atoms/app_button.dart';
import '../../../../common_widgets/organisms/app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/color_tokens.dart';
import '../../data/models/exam_config_model.dart';
import '../../data/models/exam_enums.dart';
import '../providers/exam_provider.dart';

/// Screen for configuring a new exam before starting.
class ExamConfigScreen extends ConsumerStatefulWidget {
  const ExamConfigScreen({super.key});

  @override
  ConsumerState<ExamConfigScreen> createState() => _ExamConfigScreenState();
}

class _ExamConfigScreenState extends ConsumerState<ExamConfigScreen> {
  late ExamConfig _config;
  final _topicController = TextEditingController();
  bool _isLoading = false;

  final _subjects = [
    'Science',
    'Physics',
    'Chemistry',
    'Biology',
    'Mathematics',
    'Bangla',
    'English',
    'ICT',
    'History',
    'Geography',
  ];

  final _classLevels = ['6', '7', '8', '9', '10', '11', '12'];

  @override
  void initState() {
    super.initState();
    _config = ref.read(examConfigProvider);
    _topicController.text = _config.topic;
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyExtraPrefill());
  }

  void _applyExtraPrefill() {
    final extra = GoRouterState.of(context).extra;
    if (extra is! Map<String, dynamic>) return;
    final subject = extra['subject'] as String?;
    final topic = extra['topic'] as String?;
    final difficultyRaw = extra['difficulty'] as String?;
    ExamDifficulty? difficulty;
    if (difficultyRaw != null) {
      difficulty = ExamDifficulty.values.firstWhere(
        (d) => d.jsonValue == difficultyRaw || d.name == difficultyRaw,
        orElse: () => _config.difficulty,
      );
    }
    final next = _config.copyWith(
      subject: subject ?? _config.subject,
      topic: topic ?? _config.topic,
      difficulty: difficulty ?? _config.difficulty,
    );
    _topicController.text = next.topic;
    _updateConfig(next);
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  void _updateConfig(ExamConfig newConfig) {
    setState(() => _config = newConfig);
    ref.read(examConfigProvider.notifier).state = newConfig;
  }

  Future<void> _startExam() async {
    setState(() => _isLoading = true);
    try {
      final config = _config.copyWith(topic: _topicController.text.trim());
      await ref.read(examSessionProvider.notifier).startExam(config);
      if (mounted) {
        final session = ref.read(examSessionProvider);
        if (session != null) {
          context.push('/exam/session/${session.examId}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).examStartFailed('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: CustomAppBar(title: l10n.examConfigTitle),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: l10n.examSubject),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _subjects.map((subject) {
                final isSelected = _config.subject == subject;
                return ChoiceChip(
                  label: Text(subject),
                  selected: isSelected,
                  onSelected: (_) => _updateConfig(
                    _config.copyWith(subject: subject),
                  ),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  backgroundColor: AppColors.cardBg,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: l10n.examTopic),
            const SizedBox(height: 8),
            TextField(
              controller: _topicController,
              decoration: InputDecoration(
                hintText: l10n.examTopicHint,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: l10n.examClassLevel),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _classLevels.map((level) {
                final isSelected = _config.classLevel == level;
                return ChoiceChip(
                  label: Text(l10n.examClassN(level)),
                  selected: isSelected,
                  onSelected: (_) => _updateConfig(
                    _config.copyWith(classLevel: level),
                  ),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  backgroundColor: AppColors.cardBg,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: l10n.examDifficulty),
            const SizedBox(height: 8),
            _DifficultySelector(
              difficulty: _config.difficulty,
              onChanged: (d) => _updateConfig(_config.copyWith(difficulty: d)),
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: l10n.examExamType),
            const SizedBox(height: 8),
            _ExamTypeSelector(
              examType: _config.examType,
              onChanged: (t) => _updateConfig(
                _config.copyWith(
                  examType: t,
                  timeLimitMinutes: t.defaultTimeLimitMinutes,
                  numQuestions: t.defaultNumQuestions,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: l10n.examNumQuestions),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _config.numQuestions.toDouble(),
                    min: 5,
                    max: 50,
                    divisions: 45,
                    label: '${_config.numQuestions}',
                    onChanged: _config.examType == ExamType.practice
                        ? (v) => _updateConfig(
                              _config.copyWith(numQuestions: v.round()),
                            )
                        : null,
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    '${_config.numQuestions}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: l10n.examTimeLimit),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _config.timeLimitMinutes.toDouble(),
                    min: 10,
                    max: 180,
                    divisions: 17,
                    label: '${_config.timeLimitMinutes} min',
                    onChanged: _config.examType == ExamType.practice
                        ? (v) => _updateConfig(
                              _config.copyWith(timeLimitMinutes: v.round()),
                            )
                        : null,
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    '${_config.timeLimitMinutes}m',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _PreviewCard(config: _config),
            const SizedBox(height: 32),
            AppButton(
              label: _isLoading ? l10n.examGenerating : l10n.examStart,
              onPressed: _isLoading ? null : _startExam,
              isFullWidth: true,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _DifficultySelector extends StatelessWidget {
  const _DifficultySelector({
    required this.difficulty,
    required this.onChanged,
  });

  final ExamDifficulty difficulty;
  final ValueChanged<ExamDifficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ExamDifficulty.values.map((d) {
        final isSelected = difficulty == d;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(d),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? d.color.withValues(alpha: 0.1) : AppColors.cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? d.color : AppColors.divider,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    d.localizedLabel(AppLocalizations.of(context)),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? d.color : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ExamTypeSelector extends StatelessWidget {
  const _ExamTypeSelector({
    required this.examType,
    required this.onChanged,
  });

  final ExamType examType;
  final ValueChanged<ExamType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: ExamType.values.map((t) {
        final isSelected = examType == t;
        return GestureDetector(
          onTap: () => onChanged(t),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.divider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  t.icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.localizedLabel(AppLocalizations.of(context)),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.localizedSubtitle(AppLocalizations.of(context)),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 22,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.config});

  final ExamConfig config;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.examPreview,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _PreviewRow(label: l10n.examSubject, value: config.subject),
          _PreviewRow(label: l10n.examTopic, value: config.topic),
          _PreviewRow(label: l10n.examRowClass, value: l10n.examClassN(config.classLevel)),
          _PreviewRow(label: l10n.examDifficulty, value: config.difficulty.localizedLabel(l10n)),
          _PreviewRow(label: l10n.examRowType, value: config.examType.localizedLabel(l10n)),
          _PreviewRow(label: l10n.examRowQuestions, value: '${config.numQuestions}'),
          _PreviewRow(label: l10n.examRowTime, value: l10n.minutesShort(config.timeLimitMinutes)),
          const Divider(height: 24),
          _PreviewRow(
            label: l10n.examTotalMarks,
            value: '${config.totalMarks}',
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
