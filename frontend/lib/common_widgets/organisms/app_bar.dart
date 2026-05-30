import 'package:flutter/material.dart';

import '../../theme/color_tokens.dart';

/// Custom branded AppBar with optional gradient background.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.showGradient = false,
    this.elevation = 0,
    this.bottom,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
  });

  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showGradient;
  final double elevation;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final bool automaticallyImplyLeading;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      leading: leading,
      actions: actions,
      elevation: elevation,
      centerTitle: centerTitle,
      automaticallyImplyLeading:
          leading == null && automaticallyImplyLeading,
      backgroundColor: showGradient ? const Color(0xFF8B5A2B) : null,
      foregroundColor: showGradient ? Colors.white : null,
      iconTheme:
          showGradient ? const IconThemeData(color: Colors.white) : null,
      titleTextStyle: showGradient
          ? const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            )
          : null,
      bottom: bottom ?? (showGradient ? const _AppBarHairline() : null),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );
}

class _AppBarHairline extends StatelessWidget
    implements PreferredSizeWidget {
  const _AppBarHairline();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: AppColors.primaryLight.withValues(alpha: 0.4),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(1);
}
