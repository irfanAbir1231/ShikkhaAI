import 'dart:convert';

/// Feedback for a single short-answer question.
class ShortAnswerFeedback {
  const ShortAnswerFeedback({
    required this.questionId,
    required this.status,
    required this.feedback,
    required this.awardedMarks,
  });

  final String questionId;
  final String status;
  final String feedback;
  final double awardedMarks;

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'status': status,
        'feedback': feedback,
        'awardedMarks': awardedMarks,
      };

  factory ShortAnswerFeedback.fromJson(Map<String, dynamic> json) {
    return ShortAnswerFeedback(
      questionId: (json['questionId'] ?? json['question_id']) as String,
      status: json['status'] as String,
      feedback: json['feedback'] as String,
      awardedMarks: ((json['awardedMarks'] ?? json['awarded_marks']) as num).toDouble(),
    );
  }
}

/// A weak topic identified from exam performance.
class WeakTopic {
  const WeakTopic({
    required this.topic,
    required this.reason,
    this.score,
  });

  final String topic;
  final String reason;
  final double? score;

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'reason': reason,
        'score': score,
      };

  factory WeakTopic.fromJson(Map<String, dynamic> json) {
    return WeakTopic(
      topic: json['topic'] as String,
      reason: json['reason'] as String,
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
    );
  }
}

/// Feedback for a single MCQ question.
class McqFeedback {
  const McqFeedback({
    required this.questionId,
    required this.correct,
    this.correctAnswer = '',
    this.submittedAnswer = '',
  });

  final String questionId;
  final bool correct;
  final String correctAnswer;
  final String submittedAnswer;

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'correct': correct,
        'correctAnswer': correctAnswer,
        'submittedAnswer': submittedAnswer,
      };

  factory McqFeedback.fromJson(Map<String, dynamic> json) {
    return McqFeedback(
      questionId: (json['questionId'] ?? json['question_id']) as String,
      correct: json['correct'] as bool? ?? false,
      correctAnswer: (json['correctAnswer'] ?? json['correct_answer']) as String? ?? '',
      submittedAnswer: (json['submittedAnswer'] ?? json['submitted_answer']) as String? ?? '',
    );
  }
}

/// Final graded result of an exam attempt.
class ExamResult {
  const ExamResult({
    required this.attemptId,
    required this.examId,
    required this.studentId,
    required this.scorePercentage,
    required this.totalMarks,
    required this.obtainedMarks,
    required this.mcqCorrect,
    required this.mcqTotal,
    this.shortAnswerFeedback = const [],
    this.weakTopics = const [],
    this.mcqFeedback = const [],
    required this.readinessScore,
    required this.timeTakenSeconds,
    required this.submittedAt,
    this.subject = '',
    this.topic = '',
    this.difficulty = '',
  });

  final String attemptId;
  final String examId;
  final int studentId;
  final double scorePercentage;
  final int totalMarks;
  final double obtainedMarks;
  final int mcqCorrect;
  final int mcqTotal;
  final List<ShortAnswerFeedback> shortAnswerFeedback;
  final List<WeakTopic> weakTopics;
  final List<McqFeedback> mcqFeedback;
  final double readinessScore;
  final int timeTakenSeconds;
  final DateTime submittedAt;
  final String subject;
  final String topic;
  final String difficulty;

  /// Grade letter based on score percentage.
  String get grade {
    if (scorePercentage >= 80) return 'A+';
    if (scorePercentage >= 70) return 'A';
    if (scorePercentage >= 60) return 'A-';
    if (scorePercentage >= 50) return 'B';
    if (scorePercentage >= 40) return 'C';
    return 'F';
  }

  /// Predicted marks based on readiness score.
  double get predictedMarks {
    return (readinessScore / 100) * totalMarks;
  }

  /// Confidence level for the prediction.
  String get predictionConfidence {
    if (readinessScore >= 80) return 'High';
    if (readinessScore >= 60) return 'Medium';
    return 'Low';
  }

  String get formattedTimeTaken {
    final hours = timeTakenSeconds ~/ 3600;
    final minutes = (timeTakenSeconds % 3600) ~/ 60;
    final seconds = timeTakenSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    return '${minutes}m ${seconds}s';
  }

  Map<String, dynamic> toJson() => {
        'attemptId': attemptId,
        'examId': examId,
        'studentId': studentId,
        'scorePercentage': scorePercentage,
        'totalMarks': totalMarks,
        'obtainedMarks': obtainedMarks,
        'mcqCorrect': mcqCorrect,
        'mcqTotal': mcqTotal,
        'shortAnswerFeedback':
            shortAnswerFeedback.map((f) => f.toJson()).toList(),
        'weakTopics': weakTopics.map((t) => t.toJson()).toList(),
        'mcqFeedback': mcqFeedback.map((f) => f.toJson()).toList(),
        'readinessScore': readinessScore,
        'timeTakenSeconds': timeTakenSeconds,
        'submittedAt': submittedAt.toIso8601String(),
        'subject': subject,
        'topic': topic,
        'difficulty': difficulty,
      };

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    return ExamResult(
      attemptId: json['attemptId'] as String,
      examId: json['examId'] as String,
      studentId: json['studentId'] as int,
      scorePercentage: (json['scorePercentage'] as num).toDouble(),
      totalMarks: json['totalMarks'] as int,
      obtainedMarks: (json['obtainedMarks'] as num).toDouble(),
      mcqCorrect: json['mcqCorrect'] as int,
      mcqTotal: json['mcqTotal'] as int,
      shortAnswerFeedback: (json['shortAnswerFeedback'] as List<dynamic>?)
              ?.map((e) => ShortAnswerFeedback.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      weakTopics: (json['weakTopics'] as List<dynamic>?)
              ?.map((e) => WeakTopic.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      mcqFeedback: (json['mcqFeedback'] as List<dynamic>?)
              ?.map((e) => McqFeedback.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      readinessScore: (json['readinessScore'] as num).toDouble(),
      timeTakenSeconds: json['timeTakenSeconds'] as int,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      subject: json['subject'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? '',
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory ExamResult.fromJsonString(String source) =>
      ExamResult.fromJson(jsonDecode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'ExamResult(attemptId: $attemptId, score: $scorePercentage%, grade: $grade)';
}
