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
}

/// Point for improvement line chart.
class ImprovementPoint {
  const ImprovementPoint({
    required this.week,
    required this.score,
  });

  final String week;
  final double score;
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
}
