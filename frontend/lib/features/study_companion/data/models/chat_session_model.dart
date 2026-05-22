import 'dart:convert';

import 'chat_message_model.dart';

/// Represents a full chat session with its message history.
class ChatSession {
  const ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.fileName,
    this.filePath,
  });

  final String id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? fileName;
  final String? filePath;

  int get messageCount => messages.length;

  /// Derives a title from the first user message, or uses a default.
  static String generateTitle(List<ChatMessage> messages) {
    final firstUser = messages.firstWhere(
      (m) => m.isUser,
      orElse: () => ChatMessage(
        id: '',
        role: MessageRole.user,
        content: 'New Chat',
        timestamp: DateTime.now(),
      ),
    );
    final text = firstUser.content;
    if (text.length <= 30) return text;
    return '${text.substring(0, 30)}...';
  }

  ChatSession copyWith({
    String? id,
    String? title,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fileName,
    String? filePath,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': messages.map((m) => m.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'fileName': fileName,
        'filePath': filePath,
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String,
      title: json['title'] as String,
      messages: (json['messages'] as List<dynamic>)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      fileName: json['fileName'] as String?,
      filePath: json['filePath'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory ChatSession.fromJsonString(String source) =>
      ChatSession.fromJson(jsonDecode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'ChatSession(id: $id, title: $title, messages: ${messages.length})';
}
