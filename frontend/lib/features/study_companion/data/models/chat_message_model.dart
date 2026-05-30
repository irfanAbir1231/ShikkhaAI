import 'dart:convert';

import 'explanation_mode.dart';

/// Represents a single message in a chat conversation.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.explanationMode,
    required this.timestamp,
    this.fileName,
    this.filePath,
    this.isLoading = false,
    this.sources,
    this.pdfContext,
    this.isSaved = false,
  });

  final String id;
  final MessageRole role;
  final String content;
  final ExplanationMode? explanationMode;
  final DateTime timestamp;
  final String? fileName;
  final String? filePath;
  final bool isLoading;
  final List<Map<String, dynamic>>? sources;
  final String? pdfContext;
  final bool isSaved;

  bool get isUser => role == MessageRole.user;
  bool get isAi => role == MessageRole.ai;
  bool get isSystem => role == MessageRole.system;

  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    ExplanationMode? explanationMode,
    DateTime? timestamp,
    String? fileName,
    String? filePath,
    bool? isLoading,
    List<Map<String, dynamic>>? sources,
    String? pdfContext,
    bool? isSaved,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      explanationMode: explanationMode ?? this.explanationMode,
      timestamp: timestamp ?? this.timestamp,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      isLoading: isLoading ?? this.isLoading,
      sources: sources ?? this.sources,
      pdfContext: pdfContext ?? this.pdfContext,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'content': content,
        'explanationMode': explanationMode?.jsonValue,
        'timestamp': timestamp.toIso8601String(),
        'fileName': fileName,
        'filePath': filePath,
        'isLoading': isLoading,
        'sources': sources,
        'pdfContext': pdfContext,
        'isSaved': isSaved,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      role: MessageRole.fromJson(json['role'] as String),
      content: json['content'] as String,
      explanationMode: json['explanationMode'] != null
          ? ExplanationMode.fromJson(json['explanationMode'] as String)
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
      fileName: json['fileName'] as String?,
      filePath: json['filePath'] as String?,
      isLoading: json['isLoading'] as bool? ?? false,
      sources: (json['sources'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      pdfContext: json['pdfContext'] as String?,
      isSaved: json['isSaved'] as bool? ?? false,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory ChatMessage.fromJsonString(String source) =>
      ChatMessage.fromJson(jsonDecode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'ChatMessage(id: $id, role: $role, content: ${content.substring(0, content.length > 20 ? 20 : content.length)}...)';
}

enum MessageRole {
  user,
  ai,
  system;

  static MessageRole fromJson(String value) {
    return MessageRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageRole.system,
    );
  }
}
