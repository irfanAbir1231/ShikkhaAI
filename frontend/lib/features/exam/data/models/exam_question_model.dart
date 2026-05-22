import 'dart:convert';

import 'exam_enums.dart';

/// Represents a single question in an exam.
class ExamQuestion {
  const ExamQuestion({
    required this.id,
    required this.type,
    required this.topic,
    required this.prompt,
    this.options = const [],
    required this.marks,
    this.correctAnswer,
    this.explanation,
    this.difficulty = ExamDifficulty.medium,
    this.subParts,
  });

  final String id;
  final QuestionType type;
  final String topic;
  final String prompt;
  final List<String> options;
  final int marks;
  final String? correctAnswer;
  final String? explanation;
  final ExamDifficulty difficulty;

  /// For CQ questions: list of sub-part prompts like ['(a)', '(b)', '(c)'].
  final List<String>? subParts;

  bool get isMcq => type == QuestionType.mcq;
  bool get isShortAnswer => type == QuestionType.shortAnswer;
  bool get isCq => type == QuestionType.cq;

  ExamQuestion copyWith({
    String? id,
    QuestionType? type,
    String? topic,
    String? prompt,
    List<String>? options,
    int? marks,
    String? correctAnswer,
    String? explanation,
    ExamDifficulty? difficulty,
    List<String>? subParts,
  }) {
    return ExamQuestion(
      id: id ?? this.id,
      type: type ?? this.type,
      topic: topic ?? this.topic,
      prompt: prompt ?? this.prompt,
      options: options ?? this.options,
      marks: marks ?? this.marks,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      difficulty: difficulty ?? this.difficulty,
      subParts: subParts ?? this.subParts,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.jsonValue,
        'topic': topic,
        'prompt': prompt,
        'options': options,
        'marks': marks,
        'correctAnswer': correctAnswer,
        'explanation': explanation,
        'difficulty': difficulty.jsonValue,
        'subParts': subParts,
      };

  factory ExamQuestion.fromJson(Map<String, dynamic> json) {
    return ExamQuestion(
      id: json['id'] as String,
      type: QuestionType.fromJson(json['type'] as String),
      topic: json['topic'] as String,
      prompt: json['prompt'] as String,
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      marks: json['marks'] as int,
      correctAnswer: json['correctAnswer'] as String?,
      explanation: json['explanation'] as String?,
      difficulty: ExamDifficulty.fromJson(
        json['difficulty'] as String? ?? 'medium',
      ),
      subParts: (json['subParts'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory ExamQuestion.fromJsonString(String source) =>
      ExamQuestion.fromJson(jsonDecode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'ExamQuestion(id: $id, type: $type, topic: $topic, marks: $marks)';
}
