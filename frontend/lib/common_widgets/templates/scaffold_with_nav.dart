import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../organisms/bottom_nav_bar.dart';

/// Shell scaffold that wraps all bottom-nav tabs and persists
/// navigation state per tab via [StatefulNavigationShell].
class ScaffoldWithNav extends StatelessWidget {
  const ScaffoldWithNav({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
