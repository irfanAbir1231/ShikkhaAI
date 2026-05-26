import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/exception_mapper.dart';
import '../../../../core/utils/result.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/student_model.dart';

/// Repository that coordinates local persistence and remote API calls
/// for the authentication / onboarding flow.
class AuthRepository {
  AuthRepository(
    this._local, {
    AuthRemoteDataSource? remote,
  }) : _remote = remote ?? AuthRemoteDataSource();

  final AuthLocalDataSource _local;
  final AuthRemoteDataSource _remote;

  // ------------------------------------------------------------------
  // Local state
  // ------------------------------------------------------------------
  bool get isOnboarded => _local.isOnboarded;

  Student? get currentStudent => _local.getStudent();

  bool get isRegistered => _local.isRegistered;

  bool get isAuthenticated => _local.isAuthenticated;

  Future<void> markOnboarded() => _local.setOnboarded(true);

  // ------------------------------------------------------------------
  // Remote
  // ------------------------------------------------------------------

  /// Registers a new student, stores token locally, and persists student on success.
  Future<Result<Student>> registerStudent({
    required String name,
    required String email,
    required String gradeLevel,
    required String password,
  }) async {
    try {
      final response = await _remote.register(
        name: name,
        email: email,
        gradeLevel: gradeLevel,
        password: password,
      );
      final studentJson = response['student'] as Map<String, dynamic>;
      final token = response['access_token'] as String;
      final student = Student.fromJson(studentJson);
      await _local.saveStudent(student);
      await _local.saveToken(token);
      return Result.success(student);
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  /// Logs in an existing student and persists token + student locally.
  Future<Result<Student>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remote.login(
        email: email,
        password: password,
      );
      final studentJson = response['student'] as Map<String, dynamic>;
      final token = response['access_token'] as String;
      final student = Student.fromJson(studentJson);
      await _local.saveStudent(student);
      await _local.saveToken(token);
      return Result.success(student);
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  /// Fetches a student by ID from the backend.
  Future<Result<Student>> getStudentById(int id) async {
    try {
      final student = await _remote.getStudentById(id);
      return Result.success(student);
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  Future<void> logout() async {
    await _local.clearStudent();
    await _local.clearToken();
    await _local.setOnboarded(false);
  }
}
