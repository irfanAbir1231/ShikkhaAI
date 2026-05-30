import 'package:flutter/material.dart';

import '../../theme/color_tokens.dart';


enum AppButtonVariant { primary, secondary, ghost }

/// Skeuomorphic design-system button: primary uses a raised gradient plate
/// with paired highlight + shadow, depresses inward on press.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final Widget? icon;
  final double height;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    reverseDuration: const Duration(milliseconds: 160),
    value: 0,
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  void _setPressed(bool pressed) {
    if (!_enabled) return;
    if (pressed) {
      _press.forward();
    } else {
      _press.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: widget.variant == AppButtonVariant.primary
                  ? Colors.white
                  : AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
        ],
        if (widget.icon != null && !widget.isLoading) ...[
          widget.icon!,
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: _foregroundColor(colors),
          ),
        ),
      ],
    );

    final sized = SizedBox(
      width: widget.isFullWidth ? double.infinity : null,
      height: widget.height,
      child: Center(child: content),
    );

    Widget plate = switch (widget.variant) {
      AppButtonVariant.primary => _RaisedPlate(
          enabled: _enabled,
          press: _press,
          child: sized,
        ),
      AppButtonVariant.secondary => _OutlinedPlate(
          enabled: _enabled,
          press: _press,
          child: sized,
        ),
      AppButtonVariant.ghost => sized,
    };

    return GestureDetector(
      onTapDown: _enabled ? (_) => _setPressed(true) : null,
      onTapUp: _enabled ? (_) => _setPressed(false) : null,
      onTapCancel: _enabled ? () => _setPressed(false) : null,
      onTap: _enabled ? widget.onPressed : null,
      behavior: HitTestBehavior.opaque,
      child: plate,
    );
  }

  Color _foregroundColor(ColorScheme colors) {
    return switch (widget.variant) {
      AppButtonVariant.primary => Colors.white,
      AppButtonVariant.secondary => AppColors.primary,
      AppButtonVariant.ghost => AppColors.primary,
    };
  }
}

class _RaisedPlate extends StatelessWidget {
  const _RaisedPlate({
    required this.child,
    required this.enabled,
    required this.press,
  });

  final Widget child;
  final bool enabled;
  final AnimationController press;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: press,
      builder: (context, _) {
        final t = press.value;
        final depth = 1 - 0.7 * t;
        final scale = 1 - 0.02 * t;
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: enabled
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFB87A4B), Color(0xFF8B5A2B), Color(0xFF6B3E1F)],
                    ),
                    border: Border.all(
                      color: const Color(0xFFC19A6B).withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6B3E1F).withValues(alpha: 0.45 * depth),
                        offset: Offset(0, 4 * depth),
                        blurRadius: 10 * depth,
                        spreadRadius: -2,
                      ),
                      BoxShadow(
                        color: const Color(0xFFC19A6B).withValues(alpha: 0.25 * depth),
                        offset: Offset(0, -2 * depth),
                        blurRadius: 4 * depth,
                        spreadRadius: -1,
                      ),
                    ],
                  )
                : BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(22),
                  ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _OutlinedPlate extends StatelessWidget {
  const _OutlinedPlate({
    required this.child,
    required this.enabled,
    required this.press,
  });

  final Widget child;
  final bool enabled;
  final AnimationController press;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: press,
      builder: (context, _) {
        final t = press.value;
        final depth = 1 - 0.6 * t;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardBgDark : AppColors.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: enabled ? 0.55 : 0.25),
              width: 1.4,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.neuShadow.withValues(alpha: 0.35 * depth),
                      offset: Offset(3 * depth, 3 * depth),
                      blurRadius: 8 * depth,
                    ),
                    BoxShadow(
                      color: AppColors.neuHighlight.withValues(alpha: 0.9 * depth),
                      offset: Offset(-3 * depth, -3 * depth),
                      blurRadius: 8 * depth,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
    );
  }
}
