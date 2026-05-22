/// Centralized route path strings for [go_router].
class RouteNames {
  const RouteNames._();

  // Root
  static const String splash = '/';
  static const String onboarding = '/auth/onboarding';
  static const String register = '/auth/register';
  static const String classSelection = '/auth/class-selection';

  // Shell routes (bottom nav tabs)
  static const String home = '/home';
  static const String exam = '/exam';
  static const String upload = '/upload';
  static const String library = '/library';
  static const String studyCompanion = '/study';
  static const String plan = '/plan';

  // Nested routes
  static const String dashboard = 'dashboard';
  static const String analytics = 'analytics';
  static const String studyPlan = 'study-plan';
  static const String examConfig = 'config';
  static const String examSession = 'session/:id';
  static const String examResult = 'result/:id';
  static const String examHistory = 'history';
  static const String uploadChapter = 'chapter';
  static const String uploadHandwritten = 'handwritten';
  static const String uploadHandwrittenResult = 'handwritten/result/:id';
  static const String uploadHistory = 'history';
  static const String planCreate = 'create';
  static const String planDetail = 'detail/:id';
  static const String settings = '/settings';
}
