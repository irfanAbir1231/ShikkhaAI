import 'dart:convert';

/// Represents a student's answer to a single question.
class ExamAnswer {
  const ExamAnswer({
    required this.questionId,
    required this.answer,
    this.timeSpentSeconds = 0,
  });

  final String questionId;
  final String answer;
  final int timeSpentSeconds;

  ExamAnswer copyWith({
    String? questionId,
    String? answer,
    int? timeSpentSeconds,
  }) {
    return ExamAnswer(
      questionId: questionId ?? this.questionId,
      answer: answer ?? this.answer,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'answer': answer,
        'timeSpentSeconds': timeSpentSeconds,
      };

  factory ExamAnswer.fromJson(Map<String, dynamic> json) {
    return ExamAnswer(
      questionId: json['questionId'] as String,
      answer: json['answer'] as String,
      timeSpentSeconds: json['timeSpentSeconds'] as int? ?? 0,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory ExamAnswer.fromJsonString(String source) =>
      ExamAnswer.fromJson(jsonDecode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'ExamAnswer(questionId: $questionId, answer: ${answer.length > 20 ? '${answer.substring(0, 20)}...' : answer})';
}
