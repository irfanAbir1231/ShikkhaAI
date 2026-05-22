import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../../core/constants/storage_keys.dart';
import '../models/student_model.dart';

/// Handles all local persistence for authentication / onboarding state.
class AuthLocalDataSource {
  AuthLocalDataSource(this._studentBox, this._settingsBox);

  final Box<String> _studentBox;
  final Box<bool> _settingsBox;

  // ------------------------------------------------------------------
  // Onboarding
  // ------------------------------------------------------------------
  bool get isOnboarded =>
      _settingsBox.get(StorageKeys.isOnboarded) ?? false;

  Future<void> setOnboarded(bool value) =>
      _settingsBox.put(StorageKeys.isOnboarded, value);

  // ------------------------------------------------------------------
  // Student
  // ------------------------------------------------------------------
  Student? getStudent() {
    final json = _studentBox.get(StorageKeys.studentData);
    if (json == null || json.isEmpty) return null;
    try {
      return Student.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveStudent(Student student) =>
      _studentBox.put(StorageKeys.studentData, jsonEncode(student.toJson()));

  Future<void> clearStudent() =>
      _studentBox.delete(StorageKeys.studentData);

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------
  bool get isRegistered => getStudent() != null;
}
