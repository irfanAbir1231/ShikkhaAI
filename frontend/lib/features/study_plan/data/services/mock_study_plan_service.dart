import '../models/study_plan_models.dart';

/// Generates realistic study plans from configuration.
class MockStudyPlanService {
  static StudyPlan generatePlan(StudyPlanConfig config) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final examDate = DateTime(
      config.examDate.year,
      config.examDate.month,
      config.examDate.day,
    );

    final totalDays = examDate.difference(today).inDays;
    if (totalDays <= 0) {
      return StudyPlan(
        id: 'plan_${config.id}',
        config: config,
        days: const [],
      );
    }

    final days = <StudyDay>[];
    final subjects = config.weakSubjects.isNotEmpty
        ? config.weakSubjects
        : ['General Study'];

    // Task templates per subject
    final taskTemplates = <String, List<_TaskTemplate>>{
      'Trigonometry': [
        const _TaskTemplate('Trig Identity Practice', 'Solve 10 identity proofs', TaskType.practice, 30),
        const _TaskTemplate('Formula Revision', 'Review sine/cosine formulas', TaskType.revision, 20),
        const _TaskTemplate('Word Problems', 'Apply trig to real-world problems', TaskType.practice, 40),
      ],
      'Chemical Bonding': [
        const _TaskTemplate('Lewis Structures', 'Draw 15 Lewis dot diagrams', TaskType.practice, 35),
        const _TaskTemplate('Bond Types Review', 'Revise ionic vs covalent bonds', TaskType.reading, 25),
        const _TaskTemplate('Molecular Geometry', 'Predict shapes using VSEPR', TaskType.practice, 30),
      ],
      'Thermodynamics': [
        const _TaskTemplate('Laws of Thermodynamics', 'Review 1st and 2nd law', TaskType.reading, 30),
        const _TaskTemplate('Numerical Problems', 'Solve heat engine problems', TaskType.practice, 40),
        const _TaskTemplate('Entropy Concepts', 'Understand entropy changes', TaskType.revision, 20),
      ],
      'Quadratic Equations': [
        const _TaskTemplate('Formula Method Drill', 'Solve 20 equations using formula', TaskType.practice, 30),
        const _TaskTemplate('Factorization Practice', 'Factorize complex quadratics', TaskType.practice, 30),
        const _TaskTemplate('Nature of Roots', 'Determine roots without solving', TaskType.revision, 20),
      ],
      'Cell Biology': [
        const _TaskTemplate('Organelles Flashcards', 'Review cell organelle functions', TaskType.revision, 25),
        const _TaskTemplate('Diagram Drawing', 'Draw plant and animal cells', TaskType.practice, 30),
        const _TaskTemplate('Cell Division', 'Review mitosis and meiosis stages', TaskType.reading, 25),
      ],
      'General Study': [
        const _TaskTemplate('Concept Review', 'Read and summarize key concepts', TaskType.reading, 30),
        const _TaskTemplate('Practice Problems', 'Solve chapter-end exercises', TaskType.practice, 35),
        const _TaskTemplate('Quick Revision', 'Review notes from previous sessions', TaskType.revision, 20),
      ],
    };

    for (var i = 0; i < totalDays; i++) {
      final date = today.add(Duration(days: i));
      final isRestDay = i % 7 == 6; // Every 7th day is rest
      final isMockTestDay = i % 7 == 5 && i > 0; // Every 6th day is mock test

      if (isRestDay) {
        days.add(StudyDay(
          date: date,
          tasks: const [],
          isRestDay: true,
        ));
        continue;
      }

      final dailyTasks = <StudyTask>[];
      var remainingMinutes = config.dailyStudyMinutes;

      if (isMockTestDay) {
        // Mock test day: 1 mock test + light revision
        dailyTasks.add(StudyTask(
          id: 'task_${config.id}_${i}_mock',
          title: 'Mock Test',
          description: 'Full mock test under timed conditions',
          subject: subjects[i % subjects.length],
          topic: 'Mixed Topics',
          durationMinutes: remainingMinutes > 90 ? 90 : remainingMinutes,
          type: TaskType.mockTest,
          scheduledDate: date,
        ));
        remainingMinutes -= dailyTasks.last.durationMinutes;
      } else {
        // Regular study day: distribute tasks across subjects
        final subject = subjects[i % subjects.length];
        final templates = taskTemplates[subject] ?? taskTemplates['General Study']!;

        for (var j = 0; j < templates.length && remainingMinutes > 0; j++) {
          final template = templates[j];
          final duration = template.duration < remainingMinutes
              ? template.duration
              : remainingMinutes;

          dailyTasks.add(StudyTask(
            id: 'task_${config.id}_${i}_$j',
            title: template.title,
            description: template.description,
            subject: subject,
            topic: template.title,
            durationMinutes: duration,
            type: template.type,
            scheduledDate: date,
          ));
          remainingMinutes -= duration;
        }
      }

      days.add(StudyDay(
        date: date,
        tasks: dailyTasks,
      ));
    }

    return StudyPlan(
      id: 'plan_${config.id}',
      config: config,
      days: days,
    );
  }
}

class _TaskTemplate {
  const _TaskTemplate(this.title, this.description, this.type, this.duration);

  final String title;
  final String description;
  final TaskType type;
  final int duration;
}
