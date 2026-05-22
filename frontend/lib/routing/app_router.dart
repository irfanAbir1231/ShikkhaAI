import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../common_widgets/templates/scaffold_with_nav.dart';
import '../features/auth/presentation/screens/class_selection_screen.dart';
import '../features/auth/presentation/screens/registration_screen.dart';
import '../features/analytics/presentation/screens/weakness_analytics_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/exam/presentation/screens/exam_config_screen.dart';
import '../features/exam/presentation/screens/exam_history_screen.dart';
import '../features/exam/presentation/screens/exam_result_screen.dart';
import '../features/exam/presentation/screens/exam_session_screen.dart';
import '../features/exam/presentation/screens/exam_shell_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/library/presentation/screens/library_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/study_companion/presentation/screens/study_companion_screen.dart';
import '../features/study_plan/presentation/screens/plan_create_screen.dart';
import '../features/study_plan/presentation/screens/plan_detail_screen.dart';
import '../features/study_plan/presentation/screens/plan_shell_screen.dart';
import '../features/upload/presentation/screens/handwritten_result_screen.dart';
import '../features/upload/presentation/screens/handwritten_upload_screen.dart';
import '../features/upload/presentation/screens/upload_shell_screen.dart';
import 'route_guards.dart';
import 'route_names.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _examNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'exam');
final _uploadNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'upload');
final _libraryNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'library');
final _studyCompanionNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'study');
final _planNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'plan');

/// Custom transition builder for auth routes.
Widget _authTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  const begin = Offset(0.0, 0.08);
  const end = Offset.zero;
  final tween = Tween(begin: begin, end: end)
      .chain(CurveTween(curve: Curves.easeOutCubic));
  final fade = CurveTween(curve: Curves.easeOut);

  return FadeTransition(
    opacity: animation.drive(fade),
    child: SlideTransition(
      position: animation.drive(tween),
      child: child,
    ),
  );
}

/// Global [GoRouter] provider.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.splash,
    redirect: authGuard,
    routes: [
      // Splash
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      // Onboarding
      GoRoute(
        path: RouteNames.onboarding,
        pageBuilder: (context, state) => const CustomTransitionPage(
          child: OnboardingScreen(),
          transitionsBuilder: _authTransition,
        ),
      ),
      // Registration
      GoRoute(
        path: RouteNames.register,
        pageBuilder: (context, state) => const CustomTransitionPage(
          child: RegistrationScreen(),
          transitionsBuilder: _authTransition,
        ),
      ),
      // Class Selection
      GoRoute(
        path: RouteNames.classSelection,
        pageBuilder: (context, state) => const CustomTransitionPage(
          child: ClassSelectionScreen(),
          transitionsBuilder: _authTransition,
        ),
      ),
      // Settings
      GoRoute(
        path: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      // Main shell with bottom nav
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNav(navigationShell: navigationShell);
        },
        branches: [
          // Home tab
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: RouteNames.home,
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: RouteNames.dashboard,
                    builder: (context, state) => const DashboardScreen(),
                  ),
                  GoRoute(
                    path: RouteNames.analytics,
                    builder: (context, state) => const WeaknessAnalyticsScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Study Companion tab
          StatefulShellBranch(
            navigatorKey: _studyCompanionNavigatorKey,
            routes: [
              GoRoute(
                path: RouteNames.studyCompanion,
                builder: (context, state) => const StudyCompanionScreen(),
              ),
            ],
          ),
          // Exam tab
          StatefulShellBranch(
            navigatorKey: _examNavigatorKey,
            routes: [
              GoRoute(
                path: RouteNames.exam,
                builder: (context, state) => const ExamShellScreen(),
                routes: [
                  GoRoute(
                    path: RouteNames.examConfig,
                    builder: (context, state) => const ExamConfigScreen(),
                  ),
                  GoRoute(
                    path: RouteNames.examSession,
                    builder: (context, state) {
                      final examId = state.pathParameters['id']!;
                      return ExamSessionScreen(examId: examId);
                    },
                  ),
                  GoRoute(
                    path: RouteNames.examResult,
                    builder: (context, state) {
                      final attemptId = state.pathParameters['id']!;
                      return ExamResultScreen(attemptId: attemptId);
                    },
                  ),
                  GoRoute(
                    path: RouteNames.examHistory,
                    builder: (context, state) => const ExamHistoryScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Upload tab
          StatefulShellBranch(
            navigatorKey: _uploadNavigatorKey,
            routes: [
              GoRoute(
                path: RouteNames.upload,
                builder: (context, state) => const UploadShellScreen(),
                routes: [
                  GoRoute(
                    path: RouteNames.uploadHandwritten,
                    builder: (context, state) => const HandwrittenUploadScreen(),
                    routes: [
                      GoRoute(
                        path: 'result/:id',
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return HandwrittenResultScreen(id: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Library tab
          StatefulShellBranch(
            navigatorKey: _libraryNavigatorKey,
            routes: [
              GoRoute(
                path: RouteNames.library,
                builder: (context, state) => const LibraryScreen(),
              ),
            ],
          ),
          // Plan tab
          StatefulShellBranch(
            navigatorKey: _planNavigatorKey,
            routes: [
              GoRoute(
                path: RouteNames.plan,
                builder: (context, state) => const PlanShellScreen(),
                routes: [
                  GoRoute(
                    path: RouteNames.planCreate,
                    builder: (context, state) => const PlanCreateScreen(),
                  ),
                  GoRoute(
                    path: RouteNames.planDetail,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return PlanDetailScreen(id: id);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
