import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common_widgets/organisms/app_bar.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/route_names.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/locale_provider.dart';
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
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: CustomAppBar(title: l10n.settingsTitle),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader(title: l10n.settingsAppearance, themeMode: themeMode),
          _ThemeModeTile(
            title: l10n.settingsSystemDefault,
            value: ThemeMode.system,
            selected: themeMode == ThemeMode.system,
            onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.system),
          ),
          _ThemeModeTile(
            title: l10n.settingsLight,
            value: ThemeMode.light,
            selected: themeMode == ThemeMode.light,
            onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.light),
          ),
          _ThemeModeTile(
            title: l10n.settingsDark,
            value: ThemeMode.dark,
            selected: themeMode == ThemeMode.dark,
            onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark),
          ),
          const Divider(),
          _SectionHeader(title: l10n.settingsLanguage, themeMode: themeMode),
          _LanguageTile(
            title: l10n.settingsLanguageEnglish,
            selected: locale.languageCode == 'en',
            onTap: () => ref.read(localeProvider.notifier).setLocale(englishLocale),
          ),
          _LanguageTile(
            title: l10n.settingsLanguageBangla,
            selected: locale.languageCode == 'bn',
            onTap: () => ref.read(localeProvider.notifier).setLocale(banglaLocale),
          ),
          const Divider(),
          _SectionHeader(title: l10n.settingsAccount, themeMode: themeMode),
          ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text(l10n.settingsLogOut, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            subtitle: Text(l10n.settingsLogOutSubtitle),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.settingsLogOutConfirmTitle),
                  content: Text(l10n.settingsLogOutConfirmBody),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(l10n.commonCancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(l10n.settingsLogOut),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await ref.read(authRepositoryProvider).logout();
                if (context.mounted) {
                  ref.read(authRefreshProvider.notifier).state++;
                  context.go(RouteNames.register);
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: Text(l10n.settingsResetOnboarding),
            subtitle: Text(l10n.settingsResetOnboardingSubtitle),
            onTap: () async {
              final settingsBox =
                  await Hive.openBox<bool>(StorageKeys.settingsBox);
              final studentBox =
                  await Hive.openBox<String>(StorageKeys.studentBox);
              await settingsBox.put(StorageKeys.isOnboarded, false);
              await studentBox.delete(StorageKeys.studentData);
              await studentBox.delete(StorageKeys.authToken);
              if (context.mounted) {
                context.go(RouteNames.onboarding);
              }
            },
          ),
          const Divider(),
          _SectionHeader(title: l10n.settingsAbout, themeMode: themeMode),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.appName),
            subtitle: Text(l10n.settingsVersion),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
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
