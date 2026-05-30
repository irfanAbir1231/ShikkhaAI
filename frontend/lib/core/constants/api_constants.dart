/// API configuration constants.
class ApiConstants {
  const ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.52.75.70:8000',
  );

  static const Duration connectTimeout = Duration(seconds: 8);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 8);

  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Endpoints
  static const String registerStudent = '/student/register';
  static const String loginStudent = '/student/login';
  static const String studentById = '/student';
  static const String generateExam = '/exam/generate';
  static const String submitExam = '/exam/submit';
  static const String studentTopics = '/student'; // GET /student/{id}/topics

  // Dashboard / Analytics (GET /student/{id}/dashboard, /student/{id}/analytics)
  static const String studentDashboardSuffix = '/dashboard';
  static const String studentAnalyticsSuffix = '/analytics';

  // Study Companion (RAG)
  static const String studyCompanionAsk = '/study-companion/ask';
  static const String studyCompanionTopicNotes = '/study-companion/topic-notes';

  // Study Plan
  static const String studyPlanGenerate = '/study-plan/generate';
  static const String studyPlanById = '/study-plan';
  static const String studyPlanTaskProgressSuffix = '/progress';

  // Notes
  static const String notes = '/notes';

  // Practice
  static const String practiceGenerate = '/practice/generate';
}
