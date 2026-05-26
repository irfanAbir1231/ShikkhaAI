import '../models/topic_models.dart';

/// Returns hardcoded topic data for development and UI testing.
class MockTopicsService {
  const MockTopicsService();

  Future<TopicsOverview> fetchTopicsOverview(int studentId) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

    return const TopicsOverview(
      subjects: [
        SubjectTopics(
          subject: 'Science',
          iconName: 'science',
          topics: [
            TopicItem(
              id: 's1',
              name: 'Force and Motion',
              subject: 'Science',
              completionPercentage: 85,
              attemptsCount: 3,
              lastScore: 90,
              isCompleted: true,
            ),
            TopicItem(
              id: 's2',
              name: 'Acids, Bases and Salts',
              subject: 'Science',
              completionPercentage: 45,
              attemptsCount: 1,
              lastScore: 45,
              isCompleted: false,
            ),
            TopicItem(
              id: 's3',
              name: 'Cell Structure',
              subject: 'Science',
              completionPercentage: 72,
              attemptsCount: 2,
              lastScore: 80,
              isCompleted: true,
            ),
            TopicItem(
              id: 's4',
              name: 'Photosynthesis',
              subject: 'Science',
              completionPercentage: 0,
              attemptsCount: 0,
              isCompleted: false,
            ),
            TopicItem(
              id: 's5',
              name: 'Electricity',
              subject: 'Science',
              completionPercentage: 60,
              attemptsCount: 2,
              lastScore: 65,
              isCompleted: true,
            ),
          ],
        ),
        SubjectTopics(
          subject: 'Mathematics',
          iconName: 'math',
          topics: [
            TopicItem(
              id: 'm1',
              name: 'Algebraic Expressions',
              subject: 'Mathematics',
              completionPercentage: 92,
              attemptsCount: 4,
              lastScore: 95,
              isCompleted: true,
            ),
            TopicItem(
              id: 'm2',
              name: 'Linear Equations',
              subject: 'Mathematics',
              completionPercentage: 78,
              attemptsCount: 2,
              lastScore: 82,
              isCompleted: true,
            ),
            TopicItem(
              id: 'm3',
              name: 'Geometry',
              subject: 'Mathematics',
              completionPercentage: 30,
              attemptsCount: 1,
              lastScore: 30,
              isCompleted: false,
            ),
            TopicItem(
              id: 'm4',
              name: 'Statistics',
              subject: 'Mathematics',
              completionPercentage: 0,
              attemptsCount: 0,
              isCompleted: false,
            ),
          ],
        ),
        SubjectTopics(
          subject: 'Bangla',
          iconName: 'bangla',
          topics: [
            TopicItem(
              id: 'b1',
              name: 'Grammar',
              subject: 'Bangla',
              completionPercentage: 55,
              attemptsCount: 2,
              lastScore: 58,
              isCompleted: false,
            ),
            TopicItem(
              id: 'b2',
              name: 'Literature',
              subject: 'Bangla',
              completionPercentage: 0,
              attemptsCount: 0,
              isCompleted: false,
            ),
          ],
        ),
      ],
      totalTopics: 11,
      completedTopics: 5,
    );
  }
}
