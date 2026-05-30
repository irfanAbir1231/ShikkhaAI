import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/study_companion_local_datasource.dart';
import '../../data/datasources/study_companion_remote_datasource.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/models/chat_session_model.dart';
import '../../data/models/explanation_mode.dart';
import '../../data/repositories/study_companion_repository.dart';

String _generateId() {
  return '${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(999999)}';
}

final _random = Random();

// ------------------------------------------------------------------
// Repository
// ------------------------------------------------------------------
final studyCompanionRepositoryProvider = Provider<StudyCompanionRepository>(
  (ref) {
    final sessionsBox = Hive.box<String>(StorageKeys.chatSessionsBox);
    final settingsBox = Hive.box<String>(StorageKeys.chatSettingsBox);
    return StudyCompanionRepository(
      localDataSource: StudyCompanionLocalDataSource(sessionsBox, settingsBox),
      remoteDataSource: StudyCompanionRemoteDataSource(),
    );
  },
);

// ------------------------------------------------------------------
// Explanation Mode
// ------------------------------------------------------------------
final explanationModeProvider = StateProvider<ExplanationMode>((ref) {
  final repo = ref.read(studyCompanionRepositoryProvider);
  return repo.getLastUsedMode();
});

// ------------------------------------------------------------------
// File Attachment
// ------------------------------------------------------------------
final fileAttachmentProvider = StateProvider<(String name, String path)?>(
  (ref) => null,
);

// ------------------------------------------------------------------
// Chat Sessions List
// ------------------------------------------------------------------
final chatSessionsProvider =
    StateNotifierProvider<ChatSessionsNotifier, List<ChatSession>>(
  (ref) => ChatSessionsNotifier(
    ref.watch(studyCompanionRepositoryProvider),
  ),
);

class ChatSessionsNotifier extends StateNotifier<List<ChatSession>> {
  ChatSessionsNotifier(this._repo) : super([]) {
    loadSessions();
  }

  final StudyCompanionRepository _repo;

  void loadSessions() {
    state = _repo.getChatHistory();
  }

  Future<void> deleteSession(String id) async {
    await _repo.deleteSession(id);
    loadSessions();
  }

  Future<void> clearAll() async {
    await _repo.clearAllSessions();
    loadSessions();
  }

  Future<void> refresh() async {
    loadSessions();
  }
}

// ------------------------------------------------------------------
// Current Active Chat
// ------------------------------------------------------------------
final currentChatProvider =
    StateNotifierProvider<CurrentChatNotifier, ChatSession?>(
  (ref) => CurrentChatNotifier(
    ref.watch(studyCompanionRepositoryProvider),
    ref,
  ),
);

class CurrentChatNotifier extends StateNotifier<ChatSession?> {
  CurrentChatNotifier(this._repo, this._ref) : super(null);

  final StudyCompanionRepository _repo;
  final Ref _ref;
  StreamSubscription<String>? _responseSub;

  /// Starts a fresh chat session.
  void startNewChat() {
    _responseSub?.cancel();
    state = null;
  }

  /// Loads an existing session.
  void loadSession(String sessionId) {
    _responseSub?.cancel();
    final session = _repo.getSessionById(sessionId);
    state = session;
  }

  /// Sends a user message and streams the AI response.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final mode = _ref.read(explanationModeProvider);
    final file = _ref.read(fileAttachmentProvider);

    // Resolve student info for the API call
    final student = _ref.read(studentProvider);
    final studentId = student?.id;
    final classLevel = student?.gradeLevel ?? '8';
    const subject = 'science'; // ChromaDB currently only has class 8 science

    if (studentId == null) {
      // No authenticated student — show a local error message
      _appendErrorMessage(
        'You must be logged in to use the AI Study Companion.',
        mode,
      );
      return;
    }

    // Create session if needed
    final sessionId = state?.id ?? _generateId();
    final now = DateTime.now();

    // Build user message
    final userMessage = ChatMessage(
      id: _generateId(),
      role: MessageRole.user,
      content: text.trim(),
      timestamp: now,
      fileName: file?.$1,
      filePath: file?.$2,
    );

    // Build loading AI message
    final aiMessageId = _generateId();
    final aiLoadingMessage = ChatMessage(
      id: aiMessageId,
      role: MessageRole.ai,
      content: '',
      explanationMode: mode,
      timestamp: now,
      isLoading: true,
    );

    // Update state immediately with user + loading AI
    final messages = [
      ...?state?.messages,
      userMessage,
      aiLoadingMessage,
    ];
    state = ChatSession(
      id: sessionId,
      title: state?.title ?? ChatSession.generateTitle([userMessage]),
      messages: messages,
      createdAt: state?.createdAt ?? now,
      updatedAt: now,
      fileName: state?.fileName ?? file?.$1,
      filePath: state?.filePath ?? file?.$2,
    );

    // Clear file attachment after sending
    _ref.read(fileAttachmentProvider.notifier).state = null;

    // Save partial session
    await _repo.saveSession(state!);
    _ref.read(chatSessionsProvider.notifier).loadSessions();

    // Stream AI response
    _responseSub?.cancel();
    final stream = _repo.sendMessage(
      query: text.trim(),
      mode: mode,
      fileName: file?.$1,
      studentId: studentId,
      subject: subject,
      classLevel: classLevel,
    );

    var lastContent = '';
    await for (final chunk in stream) {
      lastContent = chunk;
      _updateAiMessage(aiMessageId, chunk, isLoading: true);
    }

    // Mark as complete
    _updateAiMessage(aiMessageId, lastContent, isLoading: false);

    // Save final session
    if (state != null) {
      await _repo.saveSession(state!);
      _ref.read(chatSessionsProvider.notifier).loadSessions();
    }
  }

  void _updateAiMessage(String id, String content, {required bool isLoading}) {
    if (state == null) return;
    final updatedMessages = state!.messages.map((m) {
      if (m.id == id) {
        return m.copyWith(content: content, isLoading: isLoading);
      }
      return m;
    }).toList();
    state = state!.copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );
  }

  void _appendErrorMessage(String errorText, ExplanationMode mode) {
    if (state == null) return;
    final errorMessage = ChatMessage(
      id: _generateId(),
      role: MessageRole.ai,
      content: errorText,
      explanationMode: mode,
      timestamp: DateTime.now(),
      isLoading: false,
    );
    state = state!.copyWith(
      messages: [...state!.messages, errorMessage],
      updatedAt: DateTime.now(),
    );
  }

  /// Updates the explanation mode and persists it.
  void setMode(ExplanationMode mode) {
    _ref.read(explanationModeProvider.notifier).state = mode;
    _repo.setLastUsedMode(mode);
  }

  @override
  void dispose() {
    _responseSub?.cancel();
    super.dispose();
  }
}
