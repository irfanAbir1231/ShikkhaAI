import 'dart:convert';

import 'exam_enums.dart';

/// Configuration for generating a new exam.
class ExamConfig {
  const ExamConfig({
    required this.subject,
    required this.topic,
    this.classLevel = '8',
    this.difficulty = ExamDifficulty.medium,
    this.numQuestions = 10,
    this.examType = ExamType.practice,
    this.timeLimitMinutes = 30,
  });

  final String subject;
  final String topic;
  final String classLevel;
  final ExamDifficulty difficulty;
  final int numQuestions;
  final ExamType examType;
  final int timeLimitMinutes;

  factory ExamConfig.defaultConfig() => const ExamConfig(
        subject: 'Science',
        topic: 'General',
        classLevel: '8',
        difficulty: ExamDifficulty.medium,
        numQuestions: 10,
        examType: ExamType.practice,
        timeLimitMinutes: 30,
      );

  int get totalMarks {
    if (examType == ExamType.ssc || examType == ExamType.hsc) {
      return 30 + (5 * 10) + (3 * 5); // 30 MCQ + 5 CQ + 3 Short Answer
    }
    return numQuestions;
  }

  ExamConfig copyWith({
    String? subject,
    String? topic,
    String? classLevel,
    ExamDifficulty? difficulty,
    int? numQuestions,
    ExamType? examType,
    int? timeLimitMinutes,
  }) {
    return ExamConfig(
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      classLevel: classLevel ?? this.classLevel,
      difficulty: difficulty ?? this.difficulty,
      numQuestions: numQuestions ?? this.numQuestions,
      examType: examType ?? this.examType,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'topic': topic,
        'classLevel': classLevel,
        'difficulty': difficulty.jsonValue,
        'numQuestions': numQuestions,
        'examType': examType.jsonValue,
        'timeLimitMinutes': timeLimitMinutes,
      };

  factory ExamConfig.fromJson(Map<String, dynamic> json) {
    return ExamConfig(
      subject: json['subject'] as String,
      topic: json['topic'] as String,
      classLevel: json['classLevel'] as String? ?? '8',
      difficulty: ExamDifficulty.fromJson(
        json['difficulty'] as String? ?? 'medium',
      ),
      numQuestions: json['numQuestions'] as int? ?? 10,
      examType: ExamType.fromJson(json['examType'] as String? ?? 'practice'),
      timeLimitMinutes: json['timeLimitMinutes'] as int? ?? 30,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory ExamConfig.fromJsonString(String source) =>
      ExamConfig.fromJson(jsonDecode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'ExamConfig(subject: $subject, topic: $topic, type: $examType)';
}
