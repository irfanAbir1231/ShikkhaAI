import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/models/student_model.dart';
import '../../data/repositories/auth_repository.dart';

// ------------------------------------------------------------------
// Repository
// ------------------------------------------------------------------
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final studentBox = Hive.box<String>(StorageKeys.studentBox);
  final settingsBox = Hive.box<bool>(StorageKeys.settingsBox);
  return AuthRepository(
    AuthLocalDataSource(studentBox, settingsBox),
  );
});

// ------------------------------------------------------------------
// Derived state
// ------------------------------------------------------------------
final studentProvider = Provider<Student?>((ref) {
  return ref.watch(authRepositoryProvider).currentStudent;
});

final isOnboardedProvider = Provider<bool>((ref) {
  return ref.watch(authRepositoryProvider).isOnboarded;
});

final isRegisteredProvider = Provider<bool>((ref) {
  return ref.watch(authRepositoryProvider).isRegistered;
});

// ------------------------------------------------------------------
// Registration form fields (ephemeral)
// ------------------------------------------------------------------
final registrationNameProvider = StateProvider<String>((ref) => '');
final registrationEmailProvider = StateProvider<String>((ref) => '');

// ------------------------------------------------------------------
// Registration API call
// ------------------------------------------------------------------
final registerStudentProvider =
    AsyncNotifierProvider<RegisterStudentNotifier, void>(
  RegisterStudentNotifier.new,
);

class RegisterStudentNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Nothing to preload
  }

  Future<Student> register({
    required String name,
    required String email,
    required String gradeLevel,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.registerStudent(
        name: name,
        email: email,
        gradeLevel: gradeLevel,
      );

      return result.when(
        success: (student) {
          state = const AsyncValue.data(null);
          return student;
        },
        failure: (failure) {
          state = AsyncValue.error(failure.message, StackTrace.current);
          throw Exception(failure.message);
        },
      );
    } catch (e, st) {
      final message = e is Failure ? e.message : e.toString();
      state = AsyncValue.error(message, st);
      rethrow;
    }
  }
}

// ------------------------------------------------------------------
// Fetch student by ID
// ------------------------------------------------------------------
final getStudentProvider =
    FutureProvider.family<Student?, int>((ref, studentId) async {
  final repo = ref.read(authRepositoryProvider);
  final result = await repo.getStudentById(studentId);
  return result.when(
    success: (student) => student,
    failure: (failure) => throw Exception(failure.message),
  );
});
