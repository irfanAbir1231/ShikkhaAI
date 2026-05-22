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

  Future<void> markOnboarded() => _local.setOnboarded(true);

  // ------------------------------------------------------------------
  // Remote
  // ------------------------------------------------------------------

  /// Registers a new student and persists locally on success.
  Future<Result<Student>> registerStudent({
    required String name,
    required String email,
    required String gradeLevel,
  }) async {
    try {
      final student = await _remote.register(
        name: name,
        email: email,
        gradeLevel: gradeLevel,
      );
      await _local.saveStudent(student);
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
    await _local.setOnboarded(false);
  }
}
