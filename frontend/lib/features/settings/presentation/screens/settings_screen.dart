import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common_widgets/organisms/app_bar.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../routing/route_names.dart';
import 'package:hive/hive.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final box = await Hive.openBox<bool>(StorageKeys.settingsBox);
    final isDark = box.get(StorageKeys.isDarkMode);
    if (isDark != null) {
      state = isDark ? ThemeMode.dark : ThemeMode.light;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final box = await Hive.openBox<bool>(StorageKeys.settingsBox);
    await box.put(
      StorageKeys.isDarkMode,
      mode == ThemeMode.dark || (mode == ThemeMode.system && WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark),
    );
  }
}

/// App settings screen with theme toggle and cache management.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader(title: 'Appearance', themeMode: themeMode),
          _ThemeModeTile(
            title: 'System Default',
            value: ThemeMode.system,
            selected: themeMode == ThemeMode.system,
            onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.system),
          ),
          _ThemeModeTile(
            title: 'Light',
            value: ThemeMode.light,
            selected: themeMode == ThemeMode.light,
            onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.light),
          ),
          _ThemeModeTile(
            title: 'Dark',
            value: ThemeMode.dark,
            selected: themeMode == ThemeMode.dark,
            onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark),
          ),
          const Divider(),
          _SectionHeader(title: 'Account', themeMode: themeMode),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Reset Onboarding'),
            subtitle: const Text('Clear local data and restart setup'),
            onTap: () async {
              final settingsBox =
                  await Hive.openBox<bool>(StorageKeys.settingsBox);
              final studentBox =
                  await Hive.openBox<String>(StorageKeys.studentBox);
              await settingsBox.put(StorageKeys.isOnboarded, false);
              await studentBox.delete(StorageKeys.studentData);
              if (context.mounted) {
                context.go(RouteNames.onboarding);
              }
            },
          ),
          const Divider(),
          _SectionHeader(title: 'About', themeMode: themeMode),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('ShikkhaAI'),
            subtitle: Text('Version 1.0.0'),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({
    required this.title,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final ThemeMode value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? Theme.of(context).colorScheme.primary : null,
      ),
      onTap: onTap,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.themeMode});

  final String title;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
