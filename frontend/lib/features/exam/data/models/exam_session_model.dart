import 'dart:convert';

import 'exam_answer_model.dart';
import 'exam_config_model.dart';
import 'exam_enums.dart';
import 'exam_question_model.dart';

/// Represents an in-progress exam session.
class ExamSession {
  const ExamSession({
    required this.examId,
    required this.config,
    required this.questions,
    this.answers = const {},
    this.currentQuestionIndex = 0,
    this.questionStatuses = const {},
    required this.startTime,
    this.endTime,
    this.isSubmitted = false,
    required this.timeRemainingSeconds,
  });

  final String examId;
  final ExamConfig config;
  final List<ExamQuestion> questions;
  final Map<String, ExamAnswer> answers;
  final int currentQuestionIndex;
  final Map<String, QuestionStatus> questionStatuses;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isSubmitted;
  final int timeRemainingSeconds;

  int get totalQuestions => questions.length;
  int get answeredCount =>
      questionStatuses.values.where((s) => s == QuestionStatus.answered).length;
  int get markedCount => questionStatuses.values
      .where((s) => s == QuestionStatus.markedForReview)
      .length;
  int get unansweredCount => totalQuestions - answeredCount;

  ExamQuestion? get currentQuestion {
    if (currentQuestionIndex < 0 || currentQuestionIndex >= totalQuestions) {
      return null;
    }
    return questions[currentQuestionIndex];
  }

  String? get currentQuestionId => currentQuestion?.id;

  ExamAnswer? getAnswerFor(String questionId) => answers[questionId];

  QuestionStatus getStatusFor(String questionId) {
    return questionStatuses[questionId] ?? QuestionStatus.unanswered;
  }

  double get progress {
    if (totalQuestions == 0) return 0;
    return answeredCount / totalQuestions;
  }

  bool get isComplete => answeredCount == totalQuestions;

  int get totalMarks => questions.fold(0, (sum, q) => sum + q.marks);

  ExamSession setAnswer(String questionId, String answer, {int? timeSpent}) {
    final newAnswers = Map<String, ExamAnswer>.from(answers);
    newAnswers[questionId] = ExamAnswer(
      questionId: questionId,
      answer: answer,
      timeSpentSeconds: timeSpent ??
          (answers[questionId]?.timeSpentSeconds ?? 0),
    );

    final newStatuses = Map<String, QuestionStatus>.from(questionStatuses);
    newStatuses[questionId] = QuestionStatus.answered;

    return copyWith(answers: newAnswers, questionStatuses: newStatuses);
  }

  ExamSession markForReview(String questionId) {
    final currentStatus = getStatusFor(questionId);
    final newStatus = currentStatus == QuestionStatus.markedForReview
        ? (answers.containsKey(questionId)
            ? QuestionStatus.answered
            : QuestionStatus.unanswered)
        : QuestionStatus.markedForReview;

    final newStatuses = Map<String, QuestionStatus>.from(questionStatuses);
    newStatuses[questionId] = newStatus;

    return copyWith(questionStatuses: newStatuses);
  }

  ExamSession navigateToQuestion(int index) {
    if (index < 0 || index >= totalQuestions) return this;
    return copyWith(currentQuestionIndex: index);
  }

  ExamSession tickTimer() {
    if (timeRemainingSeconds <= 0) return this;
    return copyWith(timeRemainingSeconds: timeRemainingSeconds - 1);
  }

  ExamSession submit() {
    return copyWith(
      isSubmitted: true,
      endTime: DateTime.now(),
      timeRemainingSeconds: 0,
    );
  }

  ExamSession copyWith({
    String? examId,
    ExamConfig? config,
    List<ExamQuestion>? questions,
    Map<String, ExamAnswer>? answers,
    int? currentQuestionIndex,
    Map<String, QuestionStatus>? questionStatuses,
    DateTime? startTime,
    DateTime? endTime,
    bool? isSubmitted,
    int? timeRemainingSeconds,
  }) {
    return ExamSession(
      examId: examId ?? this.examId,
      config: config ?? this.config,
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      questionStatuses: questionStatuses ?? this.questionStatuses,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      timeRemainingSeconds: timeRemainingSeconds ?? this.timeRemainingSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'examId': examId,
        'config': config.toJson(),
        'questions': questions.map((q) => q.toJson()).toList(),
        'answers': answers.map(
          (k, v) => MapEntry(k, v.toJson()),
        ),
        'currentQuestionIndex': currentQuestionIndex,
        'questionStatuses': questionStatuses.map(
          (k, v) => MapEntry(k, v.jsonValue),
        ),
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'isSubmitted': isSubmitted,
        'timeRemainingSeconds': timeRemainingSeconds,
      };

  factory ExamSession.fromJson(Map<String, dynamic> json) {
    return ExamSession(
      examId: json['examId'] as String,
      config: ExamConfig.fromJson(json['config'] as Map<String, dynamic>),
      questions: (json['questions'] as List<dynamic>)
          .map((e) => ExamQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      answers: (json['answers'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, ExamAnswer.fromJson(v as Map<String, dynamic>))) ??
          const {},
      currentQuestionIndex: json['currentQuestionIndex'] as int? ?? 0,
      questionStatuses:
          (json['questionStatuses'] as Map<String, dynamic>?)
                  ?.map((k, v) => MapEntry(k, QuestionStatus.fromJson(v as String))) ??
              const {},
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      isSubmitted: json['isSubmitted'] as bool? ?? false,
      timeRemainingSeconds: json['timeRemainingSeconds'] as int? ?? 0,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory ExamSession.fromJsonString(String source) =>
      ExamSession.fromJson(jsonDecode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'ExamSession(examId: $examId, questions: $totalQuestions, answered: $answeredCount)';
}
