import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../routing/route_names.dart';
import '../../theme/color_tokens.dart';
import '../../theme/neu_decoration.dart';


/// Global key for the root [Scaffold] hosting the app drawer.
///
/// Lives at the [ScaffoldWithNav] shell so any inner screen can open
/// the same drawer via `AppDrawerScope.open(context)`.
final GlobalKey<ScaffoldState> kRootScaffoldKey =
    GlobalKey<ScaffoldState>(debugLabel: 'root-drawer-scaffold');

/// Helpers to open the global drawer from any screen.
class AppDrawerScope {
  const AppDrawerScope._();

  static void open(BuildContext _) {
    kRootScaffoldKey.currentState?.openDrawer();
  }

  static bool get hasDrawer =>
      kRootScaffoldKey.currentState?.hasDrawer ?? false;
}

/// Skeuomorphic side drawer with header card, nav tiles, and a footer plate.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    return Drawer(
      elevation: 24,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const _DrawerHeader(),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _DrawerTile(
                    icon: Icons.home_rounded,
                    label: l10n.navHome,
                    onTap: () => _go(context, RouteNames.home),
                  ),
                  _DrawerTile(
                    icon: Icons.dashboard_rounded,
                    label: l10n.drawerDashboard,
                    onTap: () => _go(
                      context,
                      '${RouteNames.home}/${RouteNames.dashboard}',
                    ),
                  ),
                  _DrawerTile(
                    icon: Icons.psychology_alt_rounded,
                    label: l10n.drawerStudyCompanion,
                    onTap: () => _go(context, RouteNames.studyCompanion),
                  ),
                  _DrawerTile(
                    icon: Icons.edit_note_rounded,
                    label: l10n.drawerSmartExam,
                    onTap: () => _go(context, RouteNames.exam),
                  ),
                  _DrawerTile(
                    icon: Icons.topic_rounded,
                    label: l10n.navTopics,
                    onTap: () => _go(context, RouteNames.topics),
                  ),
                  _DrawerTile(
                    icon: Icons.collections_bookmark_rounded,
                    label: l10n.navLibrary,
                    onTap: () => _go(context, RouteNames.library),
                  ),
                  _DrawerTile(
                    icon: Icons.calendar_month_rounded,
                    label: l10n.drawerStudyPlan,
                    onTap: () => _go(context, RouteNames.plan),
                  ),
                  _DrawerTile(
                    icon: Icons.analytics_rounded,
                    label: l10n.drawerAnalytics,
                    onTap: () => _go(
                      context,
                      '${RouteNames.home}/${RouteNames.analytics}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Divider(
                      color: isDark
                          ? AppColors.dividerDark
                          : AppColors.divider,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _DrawerTile(
                    icon: Icons.settings_rounded,
                    label: l10n.settingsTitle,
                    onTap: () => _go(context, RouteNames.settings),
                  ),
                  _DrawerTile(
                    icon: Icons.help_outline_rounded,
                    label: l10n.drawerHelpFeedback,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const _DrawerFooter(),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, String route) {
    Navigator.of(context).pop();
    context.go(route);
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
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
            color: const Color(0xFF6B3E1F).withValues(alpha: 0.3),
            offset: const Offset(0, 4),
            blurRadius: 10,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.25),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: const Offset(0, 3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.person_rounded,
                color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).drawerGreeting,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context).drawerStreakTagline,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatefulWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_DrawerTile> createState() => _DrawerTileState();
}

class _DrawerTileState extends State<_DrawerTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    reverseDuration: const Duration(milliseconds: 180),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTapDown: (_) => _press.forward(),
        onTapUp: (_) => _press.reverse(),
        onTapCancel: () => _press.reverse(),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _press,
          builder: (context, _) {
            final t = _press.value;
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: t < 0.05
                  ? BoxDecoration(
                      color: isDark
                          ? AppColors.cardBgDark
                          : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.white.withValues(alpha: 0.6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark
                                  ? AppColors.neuShadowDeep
                                  : AppColors.neuShadow)
                              .withValues(alpha: 0.28),
                          offset: const Offset(3, 3),
                          blurRadius: 8,
                        ),
                        BoxShadow(
                          color: (isDark
                                  ? AppColors.neuHighlightDark
                                  : AppColors.neuHighlight)
                              .withValues(alpha: isDark ? 0.05 : 0.7),
                          offset: const Offset(-3, -3),
                          blurRadius: 8,
                        ),
                      ],
                    )
                  : NeuDecoration.inset(
                      isDark: isDark,
                      radius: 14,
                    ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(widget.icon,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary)
                        .withValues(alpha: 0.6),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: NeuDecoration.floating(isDark: isDark, radius: 16),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded,
              color: AppColors.warning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context).drawerFooter,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Icon(Icons.dark_mode_outlined,
              size: 20,
              color: (isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary)
                  .withValues(alpha: 0.7)),
        ],
      ),
    );
  }
}
