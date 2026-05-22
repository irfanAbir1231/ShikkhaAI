/// App-wide constant values.
class AppConstants {
  const AppConstants._();

  static const String appName = 'ShikkhaAI';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'AI-powered study companion for Bangladeshi students';

  // Grade levels
  static const List<String> gradeLevels = ['Class 8', 'Class 9', 'Class 10'];

  // Subjects
  static const List<String> subjects = [
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'Bangla',
    'English',
    'ICT',
  ];

  // Difficulty levels
  static const List<String> difficulties = ['easy', 'medium', 'hard'];

  // Responsive breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
}
