import 'package:hive/hive.dart';

import '../models/chat_session_model.dart';
import '../models/explanation_mode.dart';

/// Handles local persistence for Study Companion chat sessions.
class StudyCompanionLocalDataSource {
  StudyCompanionLocalDataSource(this._sessionsBox, this._settingsBox);

  final Box<String> _sessionsBox;
  final Box<String> _settingsBox;

  // ------------------------------------------------------------------
  // Sessions
  // ------------------------------------------------------------------

  List<ChatSession> getSessions() {
    final sessions = <ChatSession>[];
    for (final key in _sessionsBox.keys) {
      final json = _sessionsBox.get(key as String);
      if (json != null && json.isNotEmpty) {
        try {
          sessions.add(ChatSession.fromJsonString(json));
        } catch (_) {
          // Skip corrupted entries
        }
      }
    }
    // Sort by most recent first
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions;
  }

  ChatSession? getSessionById(String id) {
    final json = _sessionsBox.get(id);
    if (json == null || json.isEmpty) return null;
    try {
      return ChatSession.fromJsonString(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSession(ChatSession session) async {
    await _sessionsBox.put(session.id, session.toJsonString());
    await _enforceSessionLimit();
  }

  Future<void> deleteSession(String id) async {
    await _sessionsBox.delete(id);
  }

  Future<void> clearAllSessions() async {
    await _sessionsBox.clear();
  }

  // ------------------------------------------------------------------
  // Settings
  // ------------------------------------------------------------------

  ExplanationMode getLastUsedMode() {
    final value = _settingsBox.get('last_explanation_mode');
    if (value == null || value.isEmpty) {
      return ExplanationMode.easyEnglish;
    }
    return ExplanationMode.fromJson(value);
  }

  Future<void> setLastUsedMode(ExplanationMode mode) async {
    await _settingsBox.put('last_explanation_mode', mode.jsonValue);
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  static const int _maxSessions = 50;

  Future<void> _enforceSessionLimit() async {
    final keys = _sessionsBox.keys.toList();
    if (keys.length <= _maxSessions) return;

    // Fetch all sessions to sort by updatedAt
    final sessions = getSessions();
    final toDelete = sessions.sublist(_maxSessions);
    for (final session in toDelete) {
      await _sessionsBox.delete(session.id);
    }
  }
}
