import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_service.dart';
import '../models/student_model.dart';

/// Remote data source for student / auth API calls.
class AuthRemoteDataSource {
  AuthRemoteDataSource({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  /// Registers a new student.
  ///
  /// Returns the raw response containing `student` and `access_token`.
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String gradeLevel,
    required String password,
  }) async {
    final data = await _apiService.post(
      ApiConstants.registerStudent,
      data: {
        'name': name,
        'email': email,
        'grade_level': gradeLevel,
        'password': password,
      },
    );
    return data as Map<String, dynamic>;
  }

  /// Logs in an existing student.
  ///
  /// Returns the raw response containing `access_token`, `token_type`, and `student`.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final data = await _apiService.post(
      ApiConstants.loginStudent,
      data: {
        'email': email,
        'password': password,
      },
    );
    return data as Map<String, dynamic>;
  }

  /// Fetches a student by their ID.
  Future<Student> getStudentById(int id) async {
    final data = await _apiService.get(
      '${ApiConstants.studentById}/$id',
    );
    return Student.fromJson(data as Map<String, dynamic>);
  }
}
