import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_service.dart';
import '../models/exam_config_model.dart';
import '../models/exam_enums.dart';
import '../models/exam_question_model.dart';
import '../models/exam_result_model.dart';
import '../models/exam_session_model.dart';

/// Remote data source for exam API calls.
class ExamRemoteDataSource {
  ExamRemoteDataSource({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  /// Generates a new exam session for the given student and config.
  Future<ExamSession> generateExam(ExamConfig config, int studentId) async {
    final data = await _apiService.post(
      ApiConstants.generateExam,
      data: {
        'student_id': studentId,
        'subject': config.subject,
        'topic': config.topic,
        'class_level': config.classLevel,
        'difficulty': config.difficulty.jsonValue,
        'num_questions': config.numQuestions,
      },
    );

    final json = data as Map<String, dynamic>;
    final examId = (json['exam_id'] as int).toString();
    final questionsJson = json['questions'] as List<dynamic>;

    final questions = questionsJson
        .map((q) => _mapBackendQuestion(q as Map<String, dynamic>, config.difficulty))
        .toList();

    final timeLimitSeconds = config.timeLimitMinutes * 60;

    return ExamSession(
      examId: examId,
      config: config,
      questions: questions,
      answers: const {},
      currentQuestionIndex: 0,
      questionStatuses: const {},
      startTime: DateTime.now(),
      timeRemainingSeconds: timeLimitSeconds,
    );
  }

  /// Submits an exam and returns the graded result.
  Future<ExamResult> submitExam(ExamSession session, int studentId) async {
    final answersPayload = session.answers.values
        .map(
          (a) => {
            'question_id': a.questionId,
            'answer': a.answer,
          },
        )
        .toList();

    final data = await _apiService.post(
      ApiConstants.submitExam,
      data: {
        'student_id': studentId,
        'exam_id': int.parse(session.examId),
        'answers': answersPayload,
      },
    );

    final json = data as Map<String, dynamic>;

    final scorePercentage = (json['score_percentage'] as num).toDouble();
    final totalMarks = session.totalMarks;
    final obtainedMarks = (scorePercentage / 100) * totalMarks;

    final timeTakenSeconds =
        (session.config.timeLimitMinutes * 60) - session.timeRemainingSeconds;

    return ExamResult(
      attemptId: (json['attempt_id'] as int).toString(),
      examId: session.examId,
      studentId: studentId,
      scorePercentage: scorePercentage,
      totalMarks: totalMarks,
      obtainedMarks: obtainedMarks,
      mcqCorrect: json['mcq_correct'] as int,
      mcqTotal: json['mcq_total'] as int,
      shortAnswerFeedback: _mapShortAnswerFeedback(json['short_answer_feedback']),
      weakTopics: _mapWeakTopics(json['weak_topics']),
      mcqFeedback: _mapMcqFeedback(json['mcq_feedback']),
      readinessScore: (json['readiness_score'] as num).toDouble(),
      timeTakenSeconds: timeTakenSeconds.clamp(0, 99999),
      submittedAt: session.endTime ?? DateTime.now(),
      subject: session.config.subject,
      topic: session.config.topic,
      difficulty: session.config.difficulty.jsonValue,
    );
  }

  /// Maps a backend question to the frontend [ExamQuestion] model.
  ///
  /// Backend questions may lack `correctAnswer`, `explanation`, `difficulty`,
  /// and `subParts`. We fill sensible defaults.
  ExamQuestion _mapBackendQuestion(
    Map<String, dynamic> json,
    ExamDifficulty defaultDifficulty,
  ) {
    final typeStr = json['type'] as String? ?? 'short_answer';
    final questionType = _mapQuestionType(typeStr);

    return ExamQuestion(
      id: json['id'] as String,
      type: questionType,
      topic: json['topic'] as String,
      prompt: json['prompt'] as String,
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      marks: json['marks'] as int? ?? 1,
      correctAnswer: json['correct_answer'] as String?,
      explanation: json['explanation'] as String?,
      difficulty: defaultDifficulty,
      subParts: null,
    );
  }

  QuestionType _mapQuestionType(String value) {
    return switch (value) {
      'mcq' => QuestionType.mcq,
      'short_answer' => QuestionType.shortAnswer,
      // Backend does not emit 'cq', but map defensively.
      _ => QuestionType.shortAnswer,
    };
  }

  List<ShortAnswerFeedback> _mapShortAnswerFeedback(dynamic raw) {
    if (raw is! List<dynamic>) return const [];
    return raw
        .map((e) => ShortAnswerFeedback.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<WeakTopic> _mapWeakTopics(dynamic raw) {
    if (raw is! List<dynamic>) return const [];
    return raw
        .map((e) => WeakTopic.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<McqFeedback> _mapMcqFeedback(dynamic raw) {
    if (raw is! List<dynamic>) return const [];
    return raw
        .map((e) => McqFeedback.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
