import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/constants/storage_keys.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Hive local storage
    final appDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDir.path);

    // Pre-open critical boxes
    await Hive.openBox<String>(StorageKeys.studentBox);
    await Hive.openBox<bool>(StorageKeys.settingsBox);
    await Hive.openBox<String>(StorageKeys.chatSessionsBox);
    await Hive.openBox<String>(StorageKeys.chatSettingsBox);
    await Hive.openBox<String>(StorageKeys.examSessionsBox);
    await Hive.openBox<String>(StorageKeys.examResultsBox);
    await Hive.openBox<String>(StorageKeys.studyPlansBox);
    await Hive.openBox<String>(StorageKeys.topicsBox);
    await Hive.openBox<String>(StorageKeys.savedNotesBox);
    await Hive.openBox<String>(StorageKeys.savedQuizzesBox);
    await Hive.openBox<String>(StorageKeys.syncQueueBox);
    await Hive.openBox<String>(StorageKeys.dashboardStatsBox);
    await Hive.openBox<String>(StorageKeys.chaptersBox);
    await Hive.openBox<String>(StorageKeys.explanationsBox);
    await Hive.openBox<String>(StorageKeys.appPrefsBox);

    log('Hive initialized at ${appDir.path}');

    runApp(
      const ProviderScope(
        child: ShikkhaAIApp(),
      ),
    );
  }, (error, stack) {
    log('Uncaught error', error: error, stackTrace: stack);
  });
}
