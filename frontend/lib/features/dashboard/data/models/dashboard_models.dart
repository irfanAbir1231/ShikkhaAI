import 'package:flutter/material.dart';

/// Readiness score with breakdown.
class ReadinessScore {
  const ReadinessScore({
    required this.overall,
    required this.trend,
    required this.breakdown,
  });

  final double overall; // 0-100
  final double trend; // + or - percentage
  final Map<String, double> breakdown; // e.g. {'Conceptual': 78, 'Problem Solving': 65}

  factory ReadinessScore.fromJson(Map<String, dynamic> json) {
    final raw = (json['breakdown'] as Map?) ?? const {};
    return ReadinessScore(
      overall: (json['overall'] as num).toDouble(),
      trend: (json['trend'] as num).toDouble(),
      breakdown: raw.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
    );
  }

  Map<String, dynamic> toJson() => {
        'overall': overall,
        'trend': trend,
        'breakdown': breakdown,
      };
}

/// Weak subject item.
class WeakSubject {
  const WeakSubject({
    required this.name,
    required this.accuracy,
    required this.color,
    required this.icon,
  });

  final String name;
  final double accuracy; // 0-100
  final Color color;
  final IconData icon;

  factory WeakSubject.fromJson(Map<String, dynamic> json) {
    return WeakSubject(
      name: json['name'] as String,
      accuracy: (json['accuracy'] as num).toDouble(),
      color: _parseColor(json['color']),
      icon: _parseIcon(json['icon']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'accuracy': accuracy,
        'color': _colorToHex(color),
        'icon': _iconToName(icon),
      };

  static Color _parseColor(dynamic value) {
    if (value is String) {
      final hex = value.replaceFirst('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
      return Colors.grey;
    }
    if (value is int) return Color(value);
    return Colors.grey;
  }

  static String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  static IconData _parseIcon(dynamic value) {
    if (value is String) {
      return _iconMap[value] ?? Icons.menu_book;
    }
    if (value is int) {
      return IconData(value, fontFamily: 'MaterialIcons');
    }
    return Icons.menu_book;
  }

  static String _iconToName(IconData icon) {
    for (final entry in _iconMap.entries) {
      if (entry.value == icon) return entry.key;
    }
    return 'menu_book';
  }

  static final Map<String, IconData> _iconMap = {
    'science': Icons.science,
    'calculate': Icons.calculate,
    'translate': Icons.translate,
    'history_edu': Icons.history_edu,
    'public': Icons.public,
    'bolt': Icons.bolt,
    'biotech': Icons.biotech,
    'menu_book': Icons.menu_book,
    'eco': Icons.eco,
  };
}

/// Daily streak data.
class StreakData {
  const StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.weeklyActivity,
    required this.lastStudyDate,
  });

  final int currentStreak;
  final int longestStreak;
  final List<bool> weeklyActivity; // 7 days, true = studied
  final DateTime lastStudyDate;

  factory StreakData.fromJson(Map<String, dynamic> json) {
    return StreakData(
      currentStreak: json['current_streak'] as int? ?? json['currentStreak'] as int,
      longestStreak: json['longest_streak'] as int? ?? json['longestStreak'] as int,
      weeklyActivity: (json['weekly_activity'] as List? ?? json['weeklyActivity'] as List)
          .map((e) => e as bool)
          .toList(),
      lastStudyDate: DateTime.parse(
        json['last_study_date'] as String? ?? json['lastStudyDate'] as String,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'weekly_activity': weeklyActivity,
        'last_study_date': lastStudyDate.toIso8601String(),
      };
}

/// Point for improvement line chart.
class ImprovementPoint {
  const ImprovementPoint({
    required this.week,
    required this.score,
  });

  final String week;
  final double score;

  factory ImprovementPoint.fromJson(Map<String, dynamic> json) {
    return ImprovementPoint(
      week: json['week'] as String,
      score: (json['score'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'week': week,
        'score': score,
      };
}

/// Topic accuracy for bar chart.
class TopicAccuracy {
  const TopicAccuracy({
    required this.topic,
    required this.accuracy,
    required this.totalQuestions,
  });

  final String topic;
  final double accuracy; // 0-100
  final int totalQuestions;

  factory TopicAccuracy.fromJson(Map<String, dynamic> json) {
    return TopicAccuracy(
      topic: json['topic'] as String,
      accuracy: (json['accuracy'] as num).toDouble(),
      totalQuestions: json['total_questions'] as int? ?? json['totalQuestions'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'accuracy': accuracy,
        'total_questions': totalQuestions,
      };
}

/// Recent quiz result.
class RecentQuiz {
  const RecentQuiz({
    required this.id,
    required this.title,
    required this.subject,
    required this.score,
    required this.total,
    required this.date,
    required this.timeTaken,
  });

  final String id;
  final String title;
  final String subject;
  final int score;
  final int total;
  final DateTime date;
  final String timeTaken; // e.g. "12 min"

  factory RecentQuiz.fromJson(Map<String, dynamic> json) {
    return RecentQuiz(
      id: json['id'].toString(),
      title: json['title'] as String,
      subject: json['subject'] as String,
      score: json['score'] as int,
      total: json['total'] as int,
      date: DateTime.parse(json['date'] as String),
      timeTaken: json['time_taken'] as String? ?? json['timeTaken'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'score': score,
        'total': total,
        'date': date.toIso8601String(),
        'time_taken': timeTaken,
      };
}

/// AI recommendation card.
class AIRecommendation {
  const AIRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
  });

  final String id;
  final String title;
  final String description;
  final RecommendationType type;
  final RecommendationPriority priority;

  factory AIRecommendation.fromJson(Map<String, dynamic> json) {
    return AIRecommendation(
      id: json['id'].toString(),
      title: json['title'] as String,
      description: json['description'] as String,
      type: RecommendationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RecommendationType.study,
      ),
      priority: RecommendationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => RecommendationPriority.medium,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.name,
        'priority': priority.name,
      };
}

enum RecommendationType { study, practice, review, challenge }

enum RecommendationPriority { high, medium, low }

/// Complete dashboard data snapshot.
class DashboardData {
  const DashboardData({
    required this.readiness,
    required this.weakSubjects,
    required this.streak,
    required this.improvement,
    required this.topicAccuracy,
    required this.recentQuizzes,
    required this.recommendations,
  });

  final ReadinessScore readiness;
  final List<WeakSubject> weakSubjects;
  final StreakData streak;
  final List<ImprovementPoint> improvement;
  final List<TopicAccuracy> topicAccuracy;
  final List<RecentQuiz> recentQuizzes;
  final List<AIRecommendation> recommendations;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      readiness:
          ReadinessScore.fromJson(json['readiness'] as Map<String, dynamic>),
      weakSubjects: (json['weak_subjects'] as List? ?? json['weakSubjects'] as List)
          .map((e) => WeakSubject.fromJson(e as Map<String, dynamic>))
          .toList(),
      streak: StreakData.fromJson(json['streak'] as Map<String, dynamic>),
      improvement: (json['improvement'] as List)
          .map((e) => ImprovementPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      topicAccuracy: (json['topic_accuracy'] as List? ?? json['topicAccuracy'] as List)
          .map((e) => TopicAccuracy.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentQuizzes: (json['recent_quizzes'] as List? ?? json['recentQuizzes'] as List)
          .map((e) => RecentQuiz.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommendations: (json['recommendations'] as List)
          .map((e) => AIRecommendation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'readiness': readiness.toJson(),
        'weak_subjects': weakSubjects.map((e) => e.toJson()).toList(),
        'streak': streak.toJson(),
        'improvement': improvement.map((e) => e.toJson()).toList(),
        'topic_accuracy': topicAccuracy.map((e) => e.toJson()).toList(),
        'recent_quizzes': recentQuizzes.map((e) => e.toJson()).toList(),
        'recommendations': recommendations.map((e) => e.toJson()).toList(),
      };
}
