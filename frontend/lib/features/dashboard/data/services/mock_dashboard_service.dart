import 'package:flutter/material.dart';

import '../models/dashboard_models.dart';

/// Mock service that simulates network delay and returns rich dashboard data.
class MockDashboardService {
  const MockDashboardService._();

  static Future<DashboardData> fetchDashboard() async {
    await Future.delayed(const Duration(milliseconds: 800));

    return DashboardData(
      readiness: const ReadinessScore(
        overall: 74,
        trend: 5.2,
        breakdown: {
          'Conceptual': 78,
          'Problem Solving': 65,
          'Memorization': 82,
          'Application': 71,
        },
      ),
      weakSubjects: const [
        WeakSubject(
          name: 'Physics',
          accuracy: 52,
          color: Color(0xFF6366F1),
          icon: Icons.science,
        ),
        WeakSubject(
          name: 'Chemistry',
          accuracy: 61,
          color: Color(0xFF22D3EE),
          icon: Icons.biotech,
        ),
        WeakSubject(
          name: 'Higher Math',
          accuracy: 45,
          color: Color(0xFFF87171),
          icon: Icons.calculate,
        ),
        WeakSubject(
          name: 'Biology',
          accuracy: 68,
          color: Color(0xFF34D399),
          icon: Icons.eco,
        ),
      ],
      streak: StreakData(
        currentStreak: 12,
        longestStreak: 18,
        weeklyActivity: const [true, true, false, true, true, true, false],
        lastStudyDate: DateTime(2026, 5, 22),
      ),
      improvement: const [
        ImprovementPoint(week: 'W1', score: 58),
        ImprovementPoint(week: 'W2', score: 62),
        ImprovementPoint(week: 'W3', score: 60),
        ImprovementPoint(week: 'W4', score: 67),
        ImprovementPoint(week: 'W5', score: 70),
        ImprovementPoint(week: 'W6', score: 68),
        ImprovementPoint(week: 'W7', score: 74),
        ImprovementPoint(week: 'W8', score: 78),
      ],
      topicAccuracy: const [
        TopicAccuracy(topic: 'Algebra', accuracy: 82, totalQuestions: 45),
        TopicAccuracy(topic: 'Geometry', accuracy: 64, totalQuestions: 32),
        TopicAccuracy(topic: 'Mechanics', accuracy: 48, totalQuestions: 28),
        TopicAccuracy(topic: 'Organic', accuracy: 71, totalQuestions: 38),
        TopicAccuracy(topic: 'Cell Bio', accuracy: 89, totalQuestions: 50),
        TopicAccuracy(topic: 'Calculus', accuracy: 55, totalQuestions: 22),
      ],
      recentQuizzes: [
        RecentQuiz(
          id: '1',
          title: 'Class 8 Science Mid-Term',
          subject: 'Science',
          score: 18,
          total: 25,
          date: DateTime(2026, 5, 22),
          timeTaken: '14 min',
        ),
        RecentQuiz(
          id: '2',
          title: 'Math Problem Set #4',
          subject: 'Mathematics',
          score: 12,
          total: 20,
          date: DateTime(2026, 5, 21),
          timeTaken: '22 min',
        ),
        RecentQuiz(
          id: '3',
          title: 'Bangla Grammar Quiz',
          subject: 'Bangla',
          score: 15,
          total: 15,
          date: DateTime(2026, 5, 19),
          timeTaken: '8 min',
        ),
        RecentQuiz(
          id: '4',
          title: 'English Vocabulary Test',
          subject: 'English',
          score: 9,
          total: 12,
          date: DateTime(2026, 5, 17),
          timeTaken: '10 min',
        ),
      ],
      recommendations: const [
        AIRecommendation(
          id: 'r1',
          title: 'Master Newton\'s Laws',
          description:
              'Your accuracy in Mechanics is 48%. Spend 20 mins on interactive problem sets.',
          type: RecommendationType.study,
          priority: RecommendationPriority.high,
        ),
        AIRecommendation(
          id: 'r2',
          title: 'Daily Calculus Drills',
          description:
              'Consistent practice can boost your Calculus score from 55% to 75% in 2 weeks.',
          type: RecommendationType.practice,
          priority: RecommendationPriority.medium,
        ),
        AIRecommendation(
          id: 'r3',
          title: 'Review Past Mistakes',
          description:
              'You have 12 unanswered questions in Geometry. Review them to solidify concepts.',
          type: RecommendationType.review,
          priority: RecommendationPriority.medium,
        ),
        AIRecommendation(
          id: 'r4',
          title: 'Weekly Challenge',
          description:
              'Try the advanced mixed-subject quiz to test your overall readiness.',
          type: RecommendationType.challenge,
          priority: RecommendationPriority.low,
        ),
      ],
    );
  }
}
