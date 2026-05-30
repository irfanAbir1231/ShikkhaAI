import 'package:flutter/material.dart';

import '../../../../theme/color_tokens.dart';

/// Type of practice suggestion.
enum SuggestionType {
  quickPractice,
  deepDive,
  revision,
  mockTest,
}

extension SuggestionTypeExt on SuggestionType {
  String get label {
    return switch (this) {
      SuggestionType.quickPractice => 'Quick Practice',
      SuggestionType.deepDive => 'Deep Dive',
      SuggestionType.revision => 'Revision',
      SuggestionType.mockTest => 'Mock Test',
    };
  }

  IconData get icon {
    return switch (this) {
      SuggestionType.quickPractice => Icons.bolt,
      SuggestionType.deepDive => Icons.menu_book,
      SuggestionType.revision => Icons.refresh,
      SuggestionType.mockTest => Icons.assignment,
    };
  }

  Color get color {
    return switch (this) {
      SuggestionType.quickPractice => AppColors.primary,
      SuggestionType.deepDive => AppColors.primaryLight,
      SuggestionType.revision => AppColors.primaryDark,
      SuggestionType.mockTest => AppColors.success,
    };
  }
}

/// Accuracy data for a single topic.
class TopicAccuracy {
  const TopicAccuracy({
    required this.topic,
    required this.chapter,
    required this.subject,
    required this.accuracy,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.trend,
    required this.lastAttempted,
  });

  final String topic;
  final String chapter;
  final String subject;
  final double accuracy; // 0-100
  final int totalQuestions;
  final int correctAnswers;
  final double trend; // percentage point change
  final DateTime lastAttempted;

  double get incorrectAnswers => (totalQuestions - correctAnswers).toDouble();

  TopicAccuracy copyWith({
    String? topic,
    String? chapter,
    String? subject,
    double? accuracy,
    int? totalQuestions,
    int? correctAnswers,
    double? trend,
    DateTime? lastAttempted,
  }) {
    return TopicAccuracy(
      topic: topic ?? this.topic,
      chapter: chapter ?? this.chapter,
      subject: subject ?? this.subject,
      accuracy: accuracy ?? this.accuracy,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      trend: trend ?? this.trend,
      lastAttempted: lastAttempted ?? this.lastAttempted,
    );
  }

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'chapter': chapter,
        'subject': subject,
        'accuracy': accuracy,
        'total_questions': totalQuestions,
        'correct_answers': correctAnswers,
        'trend': trend,
        'last_attempted': lastAttempted.toIso8601String(),
      };

  factory TopicAccuracy.fromJson(Map<String, dynamic> json) => TopicAccuracy(
        topic: json['topic'] as String,
        chapter: json['chapter'] as String,
        subject: json['subject'] as String,
        accuracy: (json['accuracy'] as num).toDouble(),
        totalQuestions: json['total_questions'] as int? ?? json['totalQuestions'] as int,
        correctAnswers: json['correct_answers'] as int? ?? json['correctAnswers'] as int,
        trend: (json['trend'] as num).toDouble(),
        lastAttempted: DateTime.parse(
          json['last_attempted'] as String? ?? json['lastAttempted'] as String,
        ),
      );
}

/// A weak chapter with actionable insights.
class WeakChapter {
  const WeakChapter({
    required this.chapterName,
    required this.subject,
    required this.accuracy,
    required this.weaknessRank,
    required this.relatedTopics,
    required this.suggestedAction,
    required this.trend,
    required this.timeSpentMinutes,
  });

  final String chapterName;
  final String subject;
  final double accuracy; // 0-100
  final int weaknessRank; // 1 = weakest
  final List<String> relatedTopics;
  final String suggestedAction;
  final double trend; // negative = getting worse
  final int timeSpentMinutes;

  bool get isImproving => trend > 0;
  bool get isDeclining => trend < -5;

  WeakChapter copyWith({
    String? chapterName,
    String? subject,
    double? accuracy,
    int? weaknessRank,
    List<String>? relatedTopics,
    String? suggestedAction,
    double? trend,
    int? timeSpentMinutes,
  }) {
    return WeakChapter(
      chapterName: chapterName ?? this.chapterName,
      subject: subject ?? this.subject,
      accuracy: accuracy ?? this.accuracy,
      weaknessRank: weaknessRank ?? this.weaknessRank,
      relatedTopics: relatedTopics ?? this.relatedTopics,
      suggestedAction: suggestedAction ?? this.suggestedAction,
      trend: trend ?? this.trend,
      timeSpentMinutes: timeSpentMinutes ?? this.timeSpentMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'chapter_name': chapterName,
        'subject': subject,
        'accuracy': accuracy,
        'weakness_rank': weaknessRank,
        'related_topics': relatedTopics,
        'suggested_action': suggestedAction,
        'trend': trend,
        'time_spent_minutes': timeSpentMinutes,
      };

  factory WeakChapter.fromJson(Map<String, dynamic> json) => WeakChapter(
        chapterName: json['chapter_name'] as String? ?? json['chapterName'] as String,
        subject: json['subject'] as String,
        accuracy: (json['accuracy'] as num).toDouble(),
        weaknessRank: json['weakness_rank'] as int? ?? json['weaknessRank'] as int,
        relatedTopics: (json['related_topics'] as List? ?? json['relatedTopics'] as List).cast<String>(),
        suggestedAction: json['suggested_action'] as String? ?? json['suggestedAction'] as String,
        trend: (json['trend'] as num).toDouble(),
        timeSpentMinutes: json['time_spent_minutes'] as int? ?? json['timeSpentMinutes'] as int,
      );
}

/// A single point in the improvement timeline.
class ImprovementPoint {
  const ImprovementPoint({
    required this.date,
    required this.overallScore,
    required this.topicScores,
    this.examId,
  });

  final DateTime date;
  final double overallScore; // 0-100
  final Map<String, double> topicScores; // topic -> score
  final String? examId;

  ImprovementPoint copyWith({
    DateTime? date,
    double? overallScore,
    Map<String, double>? topicScores,
    String? examId,
  }) {
    return ImprovementPoint(
      date: date ?? this.date,
      overallScore: overallScore ?? this.overallScore,
      topicScores: topicScores ?? this.topicScores,
      examId: examId ?? this.examId,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'overall_score': overallScore,
        'topic_scores': topicScores,
        'exam_id': examId,
      };

  factory ImprovementPoint.fromJson(Map<String, dynamic> json) =>
      ImprovementPoint(
        date: DateTime.parse(json['date'] as String),
        overallScore: (json['overall_score'] as num? ?? json['overallScore'] as num).toDouble(),
        topicScores: (json['topic_scores'] as Map<String, dynamic>? ?? json['topicScores'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
        examId: json['exam_id'] as String? ?? json['examId'] as String?,
      );
}

/// Single day activity record.
class DailyActivity {
  const DailyActivity({
    required this.date,
    required this.isActive,
    this.performanceScore,
    this.questionsAnswered,
    this.studyMinutes,
  });

  final DateTime date;
  final bool isActive;
  final double? performanceScore; // null if not active
  final int? questionsAnswered;
  final int? studyMinutes;

  DailyActivity copyWith({
    DateTime? date,
    bool? isActive,
    double? performanceScore,
    int? questionsAnswered,
    int? studyMinutes,
  }) {
    return DailyActivity(
      date: date ?? this.date,
      isActive: isActive ?? this.isActive,
      performanceScore: performanceScore ?? this.performanceScore,
      questionsAnswered: questionsAnswered ?? this.questionsAnswered,
      studyMinutes: studyMinutes ?? this.studyMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'is_active': isActive,
        'performance_score': performanceScore,
        'questions_answered': questionsAnswered,
        'study_minutes': studyMinutes,
      };

  factory DailyActivity.fromJson(Map<String, dynamic> json) => DailyActivity(
        date: DateTime.parse(json['date'] as String),
        isActive: json['is_active'] as bool? ?? json['isActive'] as bool,
        performanceScore: json['performance_score'] != null
            ? (json['performance_score'] as num).toDouble()
            : json['performanceScore'] != null
                ? (json['performanceScore'] as num).toDouble()
                : null,
        questionsAnswered: json['questions_answered'] as int? ?? json['questionsAnswered'] as int?,
        studyMinutes: json['study_minutes'] as int? ?? json['studyMinutes'] as int?,
      );
}

/// Streak data with 30-day activity history.
class DailyStreakData {
  const DailyStreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.last30Days,
  });

  final int currentStreak;
  final int longestStreak;
  final List<DailyActivity> last30Days;

  DailyStreakData copyWith({
    int? currentStreak,
    int? longestStreak,
    List<DailyActivity>? last30Days,
  }) {
    return DailyStreakData(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      last30Days: last30Days ?? this.last30Days,
    );
  }

  Map<String, dynamic> toJson() => {
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'last_30_days': last30Days.map((e) => e.toJson()).toList(),
      };

  factory DailyStreakData.fromJson(Map<String, dynamic> json) =>
      DailyStreakData(
        currentStreak: json['current_streak'] as int? ?? json['currentStreak'] as int,
        longestStreak: json['longest_streak'] as int? ?? json['longestStreak'] as int,
        last30Days: (json['last_30_days'] as List? ?? json['last30Days'] as List)
            .map((e) => DailyActivity.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// A personalized practice suggestion.
class PracticeSuggestion {
  const PracticeSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.topic,
    required this.type,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.potentialImpact,
    required this.subject,
    this.noteId,
  });

  final String id;
  final String title;
  final String description;
  final String topic;
  final SuggestionType type;
  final String difficulty; // easy, medium, hard
  final int estimatedMinutes;
  final double potentialImpact; // 0-100
  final String subject;
  final String? noteId; // pre-generated weak-topic note id

  PracticeSuggestion copyWith({
    String? id,
    String? title,
    String? description,
    String? topic,
    SuggestionType? type,
    String? difficulty,
    int? estimatedMinutes,
    double? potentialImpact,
    String? subject,
    String? noteId,
  }) {
    return PracticeSuggestion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      topic: topic ?? this.topic,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      potentialImpact: potentialImpact ?? this.potentialImpact,
      subject: subject ?? this.subject,
      noteId: noteId ?? this.noteId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'topic': topic,
        'type': type.name,
        'difficulty': difficulty,
        'estimated_minutes': estimatedMinutes,
        'potential_impact': potentialImpact,
        'subject': subject,
        'note_id': noteId,
      };

  factory PracticeSuggestion.fromJson(Map<String, dynamic> json) =>
      PracticeSuggestion(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        topic: json['topic'] as String,
        type: SuggestionType.values.byName(json['type'] as String),
        difficulty: json['difficulty'] as String,
        estimatedMinutes: json['estimated_minutes'] as int? ?? json['estimatedMinutes'] as int,
        potentialImpact: (json['potential_impact'] as num? ?? json['potentialImpact'] as num).toDouble(),
        subject: json['subject'] as String,
        noteId: json['note_id']?.toString(),
      );
}

/// Complete analytics snapshot.
class AnalyticsSummary {
  const AnalyticsSummary({
    required this.topicAccuracy,
    required this.weakChapters,
    required this.improvementHistory,
    required this.streakData,
    required this.practiceSuggestions,
    required this.averageAccuracy,
    required this.totalQuestionsAttempted,
    required this.totalStudyMinutes,
  });

  final List<TopicAccuracy> topicAccuracy;
  final List<WeakChapter> weakChapters;
  final List<ImprovementPoint> improvementHistory;
  final DailyStreakData streakData;
  final List<PracticeSuggestion> practiceSuggestions;
  final double averageAccuracy;
  final int totalQuestionsAttempted;
  final int totalStudyMinutes;

  AnalyticsSummary copyWith({
    List<TopicAccuracy>? topicAccuracy,
    List<WeakChapter>? weakChapters,
    List<ImprovementPoint>? improvementHistory,
    DailyStreakData? streakData,
    List<PracticeSuggestion>? practiceSuggestions,
    double? averageAccuracy,
    int? totalQuestionsAttempted,
    int? totalStudyMinutes,
  }) {
    return AnalyticsSummary(
      topicAccuracy: topicAccuracy ?? this.topicAccuracy,
      weakChapters: weakChapters ?? this.weakChapters,
      improvementHistory: improvementHistory ?? this.improvementHistory,
      streakData: streakData ?? this.streakData,
      practiceSuggestions: practiceSuggestions ?? this.practiceSuggestions,
      averageAccuracy: averageAccuracy ?? this.averageAccuracy,
      totalQuestionsAttempted:
          totalQuestionsAttempted ?? this.totalQuestionsAttempted,
      totalStudyMinutes: totalStudyMinutes ?? this.totalStudyMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'topic_accuracy': topicAccuracy.map((e) => e.toJson()).toList(),
        'weak_chapters': weakChapters.map((e) => e.toJson()).toList(),
        'improvement_history':
            improvementHistory.map((e) => e.toJson()).toList(),
        'streak_data': streakData.toJson(),
        'practice_suggestions':
            practiceSuggestions.map((e) => e.toJson()).toList(),
        'average_accuracy': averageAccuracy,
        'total_questions_attempted': totalQuestionsAttempted,
        'total_study_minutes': totalStudyMinutes,
      };

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) =>
      AnalyticsSummary(
        topicAccuracy: (json['topic_accuracy'] as List? ?? json['topicAccuracy'] as List)
            .map((e) => TopicAccuracy.fromJson(e as Map<String, dynamic>))
            .toList(),
        weakChapters: (json['weak_chapters'] as List? ?? json['weakChapters'] as List)
            .map((e) => WeakChapter.fromJson(e as Map<String, dynamic>))
            .toList(),
        improvementHistory: (json['improvement_history'] as List? ?? json['improvementHistory'] as List)
            .map((e) => ImprovementPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        streakData:
            DailyStreakData.fromJson(json['streak_data'] as Map<String, dynamic>? ?? json['streakData'] as Map<String, dynamic>),
        practiceSuggestions: (json['practice_suggestions'] as List? ?? json['practiceSuggestions'] as List)
            .map((e) =>
                PracticeSuggestion.fromJson(e as Map<String, dynamic>))
            .toList(),
        averageAccuracy: (json['average_accuracy'] as num? ?? json['averageAccuracy'] as num).toDouble(),
        totalQuestionsAttempted: json['total_questions_attempted'] as int? ?? json['totalQuestionsAttempted'] as int,
        totalStudyMinutes: json['total_study_minutes'] as int? ?? json['totalStudyMinutes'] as int,
      );
}
