import 'package:flutter/material.dart';

import '../../theme/neu_decoration.dart';

/// Skeuomorphic raised plate with configurable depth, padding, and onTap ripple.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.borderRadius = 16,
    this.elevation = 0,
    this.gradient,
    this.backgroundColor,
    this.border,
    this.decoration,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double borderRadius;
  final double elevation;
  final Gradient? gradient;
  final Color? backgroundColor;
  final BoxBorder? border;
  final BoxDecoration? decoration;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
    reverseDuration: const Duration(milliseconds: 180),
    value: 0,
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    if (widget.onTap == null) return;
    if (pressed) {
      _press.forward();
    } else {
      _press.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final depth = 1.0 + widget.elevation.clamp(0, 4) * 0.25;

    return Padding(
      padding: widget.margin,
      child: GestureDetector(
        onTapDown: widget.onTap != null
            ? (_) => _setPressed(true)
            : null,
        onTapUp: widget.onTap != null
            ? (_) => _setPressed(false)
            : null,
        onTapCancel: widget.onTap != null ? () => _setPressed(false) : null,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _press,
          builder: (context, child) {
            final t = _press.value;
            final liveDepth = depth * (1 - 0.55 * t);
            final scale = 1 - 0.015 * t;
            return Transform.scale(
              scale: scale,
              child: Container(
                decoration: widget.decoration ??
                    (widget.gradient != null
                        ? NeuDecoration.raised(
                            isDark: isDark,
                            radius: widget.borderRadius,
                            color: widget.backgroundColor,
                            depth: liveDepth,
                            gradient: widget.gradient,
                          ).copyWith(border: widget.border)
                        : widget.backgroundColor != null
                            ? NeuDecoration.colored(
                                color: widget.backgroundColor!,
                                radius: widget.borderRadius,
                                depth: liveDepth,
                              ).copyWith(border: widget.border)
                            : NeuDecoration.raised(
                                isDark: isDark,
                                radius: widget.borderRadius,
                                depth: liveDepth,
                              ).copyWith(border: widget.border)),
                child: child,
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
  }
}
