import '../models/analytics_models.dart';

/// Generates rich mock analytics data for the weakness analytics dashboard.
class MockAnalyticsService {
  static Future<AnalyticsSummary> fetchAnalytics() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return AnalyticsSummary(
      topicAccuracy: _topicAccuracyData,
      weakChapters: _weakChaptersData,
      improvementHistory: _improvementHistoryData,
      streakData: _streakData,
      practiceSuggestions: _practiceSuggestionsData,
      averageAccuracy: 62.5,
      totalQuestionsAttempted: 342,
      totalStudyMinutes: 1280,
    );
  }

  static final List<TopicAccuracy> _topicAccuracyData = [
    TopicAccuracy(
      topic: 'Force & Motion',
      chapter: 'Newton\'s Laws',
      subject: 'Physics',
      accuracy: 85.0,
      totalQuestions: 40,
      correctAnswers: 34,
      trend: 5.0,
      lastAttempted: _today,
    ),
    TopicAccuracy(
      topic: 'Organic Chemistry',
      chapter: 'Hydrocarbons',
      subject: 'Chemistry',
      accuracy: 72.0,
      totalQuestions: 50,
      correctAnswers: 36,
      trend: -3.0,
      lastAttempted: _today.subtract(const Duration(days: 2)),
    ),
    TopicAccuracy(
      topic: 'Cell Biology',
      chapter: 'Cell Structure',
      subject: 'Biology',
      accuracy: 68.0,
      totalQuestions: 25,
      correctAnswers: 17,
      trend: 2.0,
      lastAttempted: _today.subtract(const Duration(days: 1)),
    ),
    TopicAccuracy(
      topic: 'Quadratic Equations',
      chapter: 'Algebra',
      subject: 'Mathematics',
      accuracy: 55.0,
      totalQuestions: 40,
      correctAnswers: 22,
      trend: -8.0,
      lastAttempted: _today.subtract(const Duration(days: 3)),
    ),
    TopicAccuracy(
      topic: 'Thermodynamics',
      chapter: 'Heat & Energy',
      subject: 'Physics',
      accuracy: 48.0,
      totalQuestions: 35,
      correctAnswers: 17,
      trend: -12.0,
      lastAttempted: _today.subtract(const Duration(days: 5)),
    ),
    TopicAccuracy(
      topic: 'Chemical Bonding',
      chapter: 'Atomic Structure',
      subject: 'Chemistry',
      accuracy: 42.0,
      totalQuestions: 30,
      correctAnswers: 13,
      trend: -5.0,
      lastAttempted: _today.subtract(const Duration(days: 4)),
    ),
    TopicAccuracy(
      topic: 'Photosynthesis',
      chapter: 'Plant Physiology',
      subject: 'Biology',
      accuracy: 78.0,
      totalQuestions: 20,
      correctAnswers: 16,
      trend: 8.0,
      lastAttempted: _today.subtract(const Duration(days: 6)),
    ),
    TopicAccuracy(
      topic: 'Trigonometry',
      chapter: 'Advanced Math',
      subject: 'Mathematics',
      accuracy: 35.0,
      totalQuestions: 45,
      correctAnswers: 16,
      trend: -10.0,
      lastAttempted: _today.subtract(const Duration(days: 7)),
    ),
  ];

  static final List<WeakChapter> _weakChaptersData = [
    const WeakChapter(
      chapterName: 'Trigonometry',
      subject: 'Mathematics',
      accuracy: 35.0,
      weaknessRank: 1,
      relatedTopics: ['Sine/Cosine', 'Identities', 'Heights & Distances'],
      suggestedAction:
          'Focus on basic trig ratios first. Practice 10 identity proofs daily.',
      trend: -10.0,
      timeSpentMinutes: 45,
    ),
    const WeakChapter(
      chapterName: 'Chemical Bonding',
      subject: 'Chemistry',
      accuracy: 42.0,
      weaknessRank: 2,
      relatedTopics: ['Ionic Bonds', 'Covalent Bonds', 'Metallic Bonds'],
      suggestedAction:
          'Revise Lewis dot structures. Draw 5 bonding diagrams per day.',
      trend: -5.0,
      timeSpentMinutes: 60,
    ),
    const WeakChapter(
      chapterName: 'Thermodynamics',
      subject: 'Physics',
      accuracy: 48.0,
      weaknessRank: 3,
      relatedTopics: ['Laws of Thermodynamics', 'Entropy', 'Heat Engines'],
      suggestedAction:
          'Watch video lectures on 1st & 2nd law. Solve numerical problems.',
      trend: -12.0,
      timeSpentMinutes: 30,
    ),
    const WeakChapter(
      chapterName: 'Quadratic Equations',
      subject: 'Mathematics',
      accuracy: 55.0,
      weaknessRank: 4,
      relatedTopics: ['Formula Method', 'Factorization', 'Nature of Roots'],
      suggestedAction:
          'Practice discriminant-based problems. Focus on real-world applications.',
      trend: -8.0,
      timeSpentMinutes: 50,
    ),
    const WeakChapter(
      chapterName: 'Cell Biology',
      subject: 'Biology',
      accuracy: 68.0,
      weaknessRank: 5,
      relatedTopics: ['Organelles', 'Cell Division', 'Membrane Transport'],
      suggestedAction:
          'Create labeled diagrams of plant and animal cells. Review mitosis stages.',
      trend: 2.0,
      timeSpentMinutes: 40,
    ),
  ];

  static final List<ImprovementPoint> _improvementHistoryData = [
    ImprovementPoint(
      date: _today.subtract(const Duration(days: 28)),
      overallScore: 45.0,
      topicScores: const {
        'Force & Motion': 60.0,
        'Organic Chemistry': 50.0,
        'Quadratic Equations': 40.0,
      },
      examId: 'exam_001',
    ),
    ImprovementPoint(
      date: _today.subtract(const Duration(days: 21)),
      overallScore: 50.0,
      topicScores: const {
        'Force & Motion': 65.0,
        'Organic Chemistry': 55.0,
        'Quadratic Equations': 42.0,
      },
      examId: 'exam_002',
    ),
    ImprovementPoint(
      date: _today.subtract(const Duration(days: 14)),
      overallScore: 55.0,
      topicScores: const {
        'Force & Motion': 70.0,
        'Organic Chemistry': 58.0,
        'Quadratic Equations': 48.0,
        'Thermodynamics': 45.0,
      },
      examId: 'exam_003',
    ),
    ImprovementPoint(
      date: _today.subtract(const Duration(days: 10)),
      overallScore: 58.0,
      topicScores: const {
        'Force & Motion': 75.0,
        'Organic Chemistry': 60.0,
        'Quadratic Equations': 50.0,
        'Thermodynamics': 48.0,
        'Chemical Bonding': 40.0,
      },
      examId: 'exam_004',
    ),
    ImprovementPoint(
      date: _today.subtract(const Duration(days: 7)),
      overallScore: 60.0,
      topicScores: const {
        'Force & Motion': 78.0,
        'Organic Chemistry': 65.0,
        'Quadratic Equations': 52.0,
        'Thermodynamics': 50.0,
        'Chemical Bonding': 42.0,
        'Trigonometry': 38.0,
      },
      examId: 'exam_005',
    ),
    ImprovementPoint(
      date: _today.subtract(const Duration(days: 3)),
      overallScore: 62.0,
      topicScores: const {
        'Force & Motion': 82.0,
        'Organic Chemistry': 68.0,
        'Quadratic Equations': 53.0,
        'Thermodynamics': 49.0,
        'Chemical Bonding': 44.0,
        'Trigonometry': 37.0,
        'Cell Biology': 65.0,
      },
      examId: 'exam_006',
    ),
    ImprovementPoint(
      date: _today,
      overallScore: 62.5,
      topicScores: const {
        'Force & Motion': 85.0,
        'Organic Chemistry': 72.0,
        'Quadratic Equations': 55.0,
        'Thermodynamics': 48.0,
        'Chemical Bonding': 42.0,
        'Trigonometry': 35.0,
        'Cell Biology': 68.0,
        'Photosynthesis': 78.0,
      },
      examId: 'exam_007',
    ),
  ];

  static DailyStreakData get _streakData {
    final days = <DailyActivity>[];
    for (var i = 29; i >= 0; i--) {
      final date = _today.subtract(Duration(days: i));
      // Simulate a streak: last 12 days active, then some gaps
      final active = i < 12 || (i >= 15 && i <= 18) || (i >= 22 && i <= 25);
      days.add(
        DailyActivity(
          date: date,
          isActive: active,
          performanceScore: active ? 50 + (30 - i) * 0.8 : null,
          questionsAnswered: active ? 15 + (i % 5) * 5 : null,
          studyMinutes: active ? 30 + (i % 3) * 15 : null,
        ),
      );
    }
    return DailyStreakData(
      currentStreak: 12,
      longestStreak: 18,
      last30Days: days,
    );
  }

  static final List<PracticeSuggestion> _practiceSuggestionsData = [
    const PracticeSuggestion(
      id: 'sugg_1',
      title: 'Trig Identity Drills',
      description:
          'Master fundamental identities through rapid-fire practice. Focus on sin²θ + cos²θ = 1 variants.',
      topic: 'Trigonometry',
      type: SuggestionType.quickPractice,
      difficulty: 'medium',
      estimatedMinutes: 15,
      potentialImpact: 85.0,
      subject: 'Mathematics',
    ),
    const PracticeSuggestion(
      id: 'sugg_2',
      title: 'Lewis Structure Workshop',
      description:
          'Draw Lewis structures for 20 compounds. Learn to predict molecular geometry from bond pairs.',
      topic: 'Chemical Bonding',
      type: SuggestionType.deepDive,
      difficulty: 'hard',
      estimatedMinutes: 45,
      potentialImpact: 78.0,
      subject: 'Chemistry',
    ),
    const PracticeSuggestion(
      id: 'sugg_3',
      title: 'Thermo Laws Revision',
      description:
          'Review First and Second Laws of Thermodynamics with solved examples from previous board exams.',
      topic: 'Thermodynamics',
      type: SuggestionType.revision,
      difficulty: 'medium',
      estimatedMinutes: 30,
      potentialImpact: 72.0,
      subject: 'Physics',
    ),
    const PracticeSuggestion(
      id: 'sugg_4',
      title: 'Quadratic Word Problems',
      description:
          'Apply quadratic equations to real-world scenarios: projectile motion, profit maximization.',
      topic: 'Quadratic Equations',
      type: SuggestionType.mockTest,
      difficulty: 'hard',
      estimatedMinutes: 60,
      potentialImpact: 65.0,
      subject: 'Mathematics',
    ),
    const PracticeSuggestion(
      id: 'sugg_5',
      title: 'Cell Organelles Flashcards',
      description:
          'Quick revision of cell organelles and their functions using interactive flashcards.',
      topic: 'Cell Biology',
      type: SuggestionType.quickPractice,
      difficulty: 'easy',
      estimatedMinutes: 10,
      potentialImpact: 55.0,
      subject: 'Biology',
    ),
  ];

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
