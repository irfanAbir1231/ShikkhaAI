/// API configuration constants.
class ApiConstants {
  const ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 15);

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
}
