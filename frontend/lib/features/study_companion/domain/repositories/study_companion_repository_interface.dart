import '../../data/models/chat_session_model.dart';
import '../../data/models/explanation_mode.dart';

/// Abstract repository for Study Companion operations.
abstract class StudyCompanionRepositoryInterface {
  /// Sends a message and returns the AI response as a stream.
  Stream<String> sendMessage({
    required String query,
    required ExplanationMode mode,
    String? fileName,
  });

  /// Gets all saved chat sessions, most recent first.
  List<ChatSession> getChatHistory();

  /// Gets a specific session by ID.
  ChatSession? getSessionById(String id);

  /// Saves a chat session locally.
  Future<void> saveSession(ChatSession session);

  /// Deletes a session by ID.
  Future<void> deleteSession(String id);

  /// Clears all chat history.
  Future<void> clearAllSessions();

  /// Gets the last used explanation mode.
  ExplanationMode getLastUsedMode();

  /// Saves the last used explanation mode.
  Future<void> setLastUsedMode(ExplanationMode mode);
}
