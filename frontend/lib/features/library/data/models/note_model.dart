import 'dart:convert';

/// Saved note (from study companion AI bubble, practice suggestion, or topic notes).
class NoteModel {
  const NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.topic,
    this.subject,
    this.classLevel,
    required this.source,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String content; // markdown
  final String topic;   // primary grouping key
  final String? subject;
  final String? classLevel;
  final String source;  // 'study_companion' | 'practice' | 'topic_notes'
  final DateTime createdAt;
  final DateTime? updatedAt;

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    String? topic,
    String? subject,
    String? classLevel,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      topic: topic ?? this.topic,
      subject: subject ?? this.subject,
      classLevel: classLevel ?? this.classLevel,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Serializes to snake_case to match the backend contract.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'topic': topic,
        'subject': subject,
        'class_level': classLevel,
        'source': source,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  /// Deserializes from snake_case (backend) with camelCase fallback (local cache).
  factory NoteModel.fromJson(Map<String, dynamic> json) => NoteModel(
        id: json['id'].toString(),
        title: json['title'] as String,
        content: json['content'] as String,
        topic: json['topic'] as String,
        subject: json['subject'] as String?,
        classLevel: json['class_level'] as String? ?? json['classLevel'] as String?,
        source: json['source'] as String,
        createdAt: DateTime.parse(
          json['created_at'] as String? ?? json['createdAt'] as String,
        ),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : json['updatedAt'] != null
                ? DateTime.parse(json['updatedAt'] as String)
                : null,
      );

  String toJsonString() => jsonEncode(toJson());

  factory NoteModel.fromJsonString(String source) =>
      NoteModel.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
