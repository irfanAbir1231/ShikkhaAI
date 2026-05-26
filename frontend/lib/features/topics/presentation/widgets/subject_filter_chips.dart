import 'package:flutter/material.dart';

import '../../../../theme/color_tokens.dart';

/// Horizontal scrollable subject filter chips.
class SubjectFilterChips extends StatelessWidget {
  const SubjectFilterChips({
    super.key,
    required this.subjects,
    required this.selected,
    required this.onSelected,
  });

  final List<String> subjects;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: subjects.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              final isSelected = selected == null;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('All'),
                  selected: isSelected,
                  onSelected: (_) => onSelected(null),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }
            final subject = subjects[index - 1];
            final isSelected = selected?.toLowerCase() == subject.toLowerCase();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(subject),
                selected: isSelected,
                onSelected: (_) => onSelected(subject),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
