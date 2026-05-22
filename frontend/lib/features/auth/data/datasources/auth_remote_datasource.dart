import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_service.dart';
import '../models/student_model.dart';

/// Remote data source for student / auth API calls.
class AuthRemoteDataSource {
  AuthRemoteDataSource({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  /// Registers a new student.
  Future<Student> register({
    required String name,
    required String email,
    required String gradeLevel,
  }) async {
    final data = await _apiService.post(
      ApiConstants.registerStudent,
      data: {
        'name': name,
        'email': email,
        'grade_level': gradeLevel,
      },
    );
    return Student.fromJson(data as Map<String, dynamic>);
  }

  /// Fetches a student by their ID.
  Future<Student> getStudentById(int id) async {
    final data = await _apiService.get(
      '${ApiConstants.studentById}/$id',
    );
    return Student.fromJson(data as Map<String, dynamic>);
  }
}
