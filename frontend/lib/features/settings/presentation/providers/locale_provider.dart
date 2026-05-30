import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/storage_keys.dart';

/// Supported app locales.
const Locale englishLocale = Locale('en');
const Locale banglaLocale = Locale('bn');

/// Holds the active app [Locale], persisted in Hive.
final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(englishLocale) {
    _load();
  }

  Future<void> _load() async {
    final box = await Hive.openBox<String>(StorageKeys.appPrefsBox);
    final code = box.get(StorageKeys.languageCode);
    if (code != null && code.isNotEmpty) {
      state = Locale(code);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final box = await Hive.openBox<String>(StorageKeys.appPrefsBox);
    await box.put(StorageKeys.languageCode, locale.languageCode);
  }
}
