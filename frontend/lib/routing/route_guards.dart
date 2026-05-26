import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../core/constants/storage_keys.dart';
import 'route_names.dart';

/// Redirects users based on authentication / onboarding state.
Future<String?> authGuard(BuildContext context, GoRouterState state) async {
  final studentBox = await Hive.openBox<String>(StorageKeys.studentBox);
  final settingsBox = await Hive.openBox<bool>(StorageKeys.settingsBox);

  final studentJson = studentBox.get(StorageKeys.studentData);
  final authToken = studentBox.get(StorageKeys.authToken);
  final isRegistered = studentJson != null && studentJson.isNotEmpty;
  final isAuthenticated = isRegistered && authToken != null && authToken.isNotEmpty;
  final isOnboarded = settingsBox.get(StorageKeys.isOnboarded) ?? false;

  final location = state.matchedLocation;

  final isAuthRoute = location == RouteNames.onboarding ||
      location == RouteNames.register ||
      location == RouteNames.classSelection ||
      location == RouteNames.splash;

  // Authenticated users should never see auth routes
  if (isAuthenticated && isAuthRoute) {
    return RouteNames.home;
  }

  // Unauthenticated users should not access protected routes
  if (!isAuthenticated && !isAuthRoute) {
    if (!isOnboarded) return RouteNames.onboarding;
    return RouteNames.register;
  }

  return null;
}
