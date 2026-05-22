import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/color_tokens.dart';
import '../../../analytics/presentation/providers/analytics_provider.dart';

/// Multi-select chip grid for weak subjects.
class WeakSubjectPicker extends ConsumerStatefulWidget {
  const WeakSubjectPicker({
    super.key,
    required this.selectedSubjects,
    required onSelectionChanged,
  }) : _onChanged = onSelectionChanged;

  final List<String> selectedSubjects;
  final ValueChanged<List<String>> _onChanged;

  @override
  ConsumerState<WeakSubjectPicker> createState() =>
      _WeakSubjectPickerState();
}

class _WeakSubjectPickerState extends ConsumerState<WeakSubjectPicker> {
  late List<String> _selected;
  final _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = [...widget.selectedSubjects];
  }

  @override
  void didUpdateWidget(covariant WeakSubjectPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSubjects != widget.selectedSubjects) {
      _selected = [...widget.selectedSubjects];
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _toggle(String subject) {
    setState(() {
      if (_selected.contains(subject)) {
        _selected.remove(subject);
      } else {
        _selected.add(subject);
      }
    });
    widget._onChanged([..._selected]);
  }

  void _addCustom() {
    final text = _customController.text.trim();
    if (text.isNotEmpty && !_selected.contains(text)) {
      setState(() {
        _selected.add(text);
        _customController.clear();
      });
      widget._onChanged([..._selected]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(analyticsSummaryProvider);
    final textTheme = Theme.of(context).textTheme;

    final weakChapters = analyticsAsync.when(
      data: (summary) => summary.weakChapters,
      loading: () => const [],
      error: (_, __) => const [],
    );

    final subjectNames = weakChapters.isNotEmpty
        ? weakChapters.map((c) => c.chapterName).toList()
        : [
            'Trigonometry',
            'Chemical Bonding',
            'Thermodynamics',
            'Quadratic Equations',
            'Cell Biology',
            'Organic Chemistry',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Weak Subjects',
          style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose subjects you want to focus on. You can also add your own.',
          style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: subjectNames.map((subject) {
            final isSelected = _selected.contains(subject);
            return FilterChip(
              label: Text(subject),
              selected: isSelected,
              onSelected: (_) => _toggle(subject),
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primary,
              labelStyle: textTheme.bodyMedium?.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : AppColors.divider,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Custom subject input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customController,
                decoration: InputDecoration(
                  hintText: 'Add custom subject...',
                  hintStyle: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
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
                onSubmitted: (_) => _addCustom(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _addCustom,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
