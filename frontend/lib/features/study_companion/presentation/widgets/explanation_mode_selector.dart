import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/color_tokens.dart';
import '../../data/models/explanation_mode.dart';

/// Horizontally scrollable row of selectable explanation mode chips.
class ExplanationModeSelector extends StatelessWidget {
  const ExplanationModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
  });

  final ExplanationMode selectedMode;
  final ValueChanged<ExplanationMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBg = isDark ? AppColors.cardBgDark : AppColors.cardBg;
    final unselectedBorder =
        isDark ? AppColors.dividerDark : AppColors.divider;

    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        itemCount: ExplanationMode.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final mode = ExplanationMode.values[index];
          final isSelected = mode == selectedMode;

          return GestureDetector(
            onTap: () => onModeSelected(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              constraints: const BoxConstraints(minWidth: 88, maxWidth: 160),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : unselectedBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : unselectedBorder,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    mode.icon,
                    size: 18,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mode.localizedLabel(AppLocalizations.of(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
