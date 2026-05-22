import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

/// Switches between mobile (single column) and tablet/desktop (side panel)
/// layouts based on screen width.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppConstants.desktopBreakpoint) {
          return desktop ?? tablet ?? mobile;
        }
        if (constraints.maxWidth >= AppConstants.tabletBreakpoint) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}

/// Convenience widget that adds horizontal padding that adapts to screen size.
class ResponsivePadding extends StatelessWidget {
  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobilePadding = const EdgeInsets.symmetric(horizontal: 16),
    this.tabletPadding = const EdgeInsets.symmetric(horizontal: 32),
    this.desktopPadding = const EdgeInsets.symmetric(horizontal: 64),
  });

  final Widget child;
  final EdgeInsets mobilePadding;
  final EdgeInsets tabletPadding;
  final EdgeInsets desktopPadding;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    EdgeInsets padding;
    if (width >= AppConstants.desktopBreakpoint) {
      padding = desktopPadding;
    } else if (width >= AppConstants.tabletBreakpoint) {
      padding = tabletPadding;
    } else {
      padding = mobilePadding;
    }
    return Padding(padding: padding, child: child);
  }
}
