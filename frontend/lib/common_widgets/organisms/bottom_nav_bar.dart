import 'package:flutter/material.dart';

import '../../theme/color_tokens.dart';

/// Bold icon-only floating bottom navigation bar with an animated
/// wood-textured active pill. No labels — pure iconography.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      const _NavItem(icon: Icons.home_rounded),
      const _NavItem(icon: Icons.psychology_alt_rounded),
      const _NavItem(icon: Icons.edit_note_rounded),
      const _NavItem(icon: Icons.topic_rounded),
      const _NavItem(icon: Icons.collections_bookmark_rounded),
      const _NavItem(icon: Icons.calendar_month_rounded),
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.cardBgDark : AppColors.cardBg;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.7),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark
                        ? AppColors.neuShadowDeep
                        : AppColors.neuShadow)
                    .withValues(alpha: isDark ? 0.65 : 0.35),
                offset: const Offset(0, 10),
                blurRadius: 22,
                spreadRadius: -2,
              ),
              BoxShadow(
                color: (isDark
                        ? AppColors.neuHighlightDark
                        : AppColors.neuHighlight)
                    .withValues(alpha: isDark ? 0.08 : 0.9),
                offset: const Offset(0, -2),
                blurRadius: 8,
                spreadRadius: -2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              // Bound the height so the per-slot `Center` can't expand to fill
              // the loose vertical constraints the Scaffold passes down.
              child: SizedBox(
                height: 52,
                child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = index == currentIndex;
                  return Expanded(
                    child: _NavSlot(
                      item: item,
                      isSelected: isSelected,
                      onTap: () => onTap(index),
                    ),
                  );
                }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavSlot extends StatefulWidget {
  const _NavSlot({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_NavSlot> createState() => _NavSlotState();
}

class _NavSlotState extends State<_NavSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    reverseDuration: const Duration(milliseconds: 160),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.isSelected;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) => _press.reverse(),
      onTapCancel: () => _press.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _press,
        builder: (context, _) {
          final t = _press.value;
          return Transform.scale(
            scale: 1 - 0.06 * t,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              decoration: selected
                  ? BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark
                              .withValues(alpha: 0.4),
                          offset: const Offset(0, 4),
                          blurRadius: 8,
                          spreadRadius: -2,
                        ),
                      ],
                    )
                  : BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
              child: Center(
                child: Icon(
                  widget.item.icon,
                  color: selected
                      ? Colors.white
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                  size: selected ? 28 : 26,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  const _NavItem({required this.icon});
}
