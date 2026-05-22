import 'package:flutter/material.dart';

/// Type of study task.
enum TaskType {
  reading,
  practice,
  revision,
  mockTest,
  rest,
}

extension TaskTypeExt on TaskType {
  String get label {
    return switch (this) {
      TaskType.reading => 'Reading',
      TaskType.practice => 'Practice',
      TaskType.revision => 'Revision',
      TaskType.mockTest => 'Mock Test',
      TaskType.rest => 'Rest',
    };
  }

  IconData get icon {
    return switch (this) {
      TaskType.reading => Icons.menu_book,
      TaskType.practice => Icons.edit_note,
      TaskType.revision => Icons.refresh,
      TaskType.mockTest => Icons.assignment,
      TaskType.rest => Icons.weekend,
    };
  }

  Color get color {
    return switch (this) {
      TaskType.reading => const Color(0xFF6366F1),
      TaskType.practice => const Color(0xFF22D3EE),
      TaskType.revision => const Color(0xFFFBBF24),
      TaskType.mockTest => const Color(0xFF34D399),
      TaskType.rest => const Color(0xFF94A3B8),
    };
  }
}

/// Configuration used to generate a study plan.
class StudyPlanConfig {
  const StudyPlanConfig({
    required this.id,
    required this.examDate,
    required this.weakSubjects,
    required this.dailyStudyMinutes,
    required this.createdAt,
    this.planTitle,
  });

  final String id;
  final DateTime examDate;
  final List<String> weakSubjects;
  final int dailyStudyMinutes;
  final DateTime createdAt;
  final String? planTitle;

  int get daysUntilExam {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exam = DateTime(examDate.year, examDate.month, examDate.day);
    return exam.difference(today).inDays;
  }

  StudyPlanConfig copyWith({
    String? id,
    DateTime? examDate,
    List<String>? weakSubjects,
    int? dailyStudyMinutes,
    DateTime? createdAt,
    String? planTitle,
  }) {
    return StudyPlanConfig(
      id: id ?? this.id,
      examDate: examDate ?? this.examDate,
      weakSubjects: weakSubjects ?? this.weakSubjects,
      dailyStudyMinutes: dailyStudyMinutes ?? this.dailyStudyMinutes,
      createdAt: createdAt ?? this.createdAt,
      planTitle: planTitle ?? this.planTitle,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'examDate': examDate.toIso8601String(),
        'weakSubjects': weakSubjects,
        'dailyStudyMinutes': dailyStudyMinutes,
        'createdAt': createdAt.toIso8601String(),
        'planTitle': planTitle,
      };

  factory StudyPlanConfig.fromJson(Map<String, dynamic> json) =>
      StudyPlanConfig(
        id: json['id'] as String,
        examDate: DateTime.parse(json['examDate'] as String),
        weakSubjects: (json['weakSubjects'] as List).cast<String>(),
        dailyStudyMinutes: json['dailyStudyMinutes'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        planTitle: json['planTitle'] as String?,
      );
}

/// A single study task.
class StudyTask {
  const StudyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.topic,
    required this.durationMinutes,
    required this.type,
    this.isCompleted = false,
    required this.scheduledDate,
  });

  final String id;
  final String title;
  final String description;
  final String subject;
  final String topic;
  final int durationMinutes;
  final TaskType type;
  final bool isCompleted;
  final DateTime scheduledDate;

  StudyTask copyWith({
    String? id,
    String? title,
    String? description,
    String? subject,
    String? topic,
    int? durationMinutes,
    TaskType? type,
    bool? isCompleted,
    DateTime? scheduledDate,
  }) {
    return StudyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      scheduledDate: scheduledDate ?? this.scheduledDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'subject': subject,
        'topic': topic,
        'durationMinutes': durationMinutes,
        'type': type.name,
        'isCompleted': isCompleted,
        'scheduledDate': scheduledDate.toIso8601String(),
      };

  factory StudyTask.fromJson(Map<String, dynamic> json) => StudyTask(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        subject: json['subject'] as String,
        topic: json['topic'] as String,
        durationMinutes: json['durationMinutes'] as int,
        type: TaskType.values.byName(json['type'] as String),
        isCompleted: json['isCompleted'] as bool,
        scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      );
}

/// A single day in the study plan.
class StudyDay {
  const StudyDay({
    required this.date,
    required this.tasks,
    this.isRestDay = false,
  });

  final DateTime date;
  final List<StudyTask> tasks;
  final bool isRestDay;

  int get totalMinutes =>
      tasks.fold(0, (sum, t) => sum + t.durationMinutes);

  int get completedTasks => tasks.where((t) => t.isCompleted).length;

  double get dayProgress =>
      tasks.isEmpty ? 0 : completedTasks / tasks.length;

  StudyDay copyWith({
    DateTime? date,
    List<StudyTask>? tasks,
    bool? isRestDay,
  }) {
    return StudyDay(
      date: date ?? this.date,
      tasks: tasks ?? this.tasks,
      isRestDay: isRestDay ?? this.isRestDay,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'tasks': tasks.map((e) => e.toJson()).toList(),
        'isRestDay': isRestDay,
      };

  factory StudyDay.fromJson(Map<String, dynamic> json) => StudyDay(
        date: DateTime.parse(json['date'] as String),
        tasks: (json['tasks'] as List)
            .map((e) => StudyTask.fromJson(e as Map<String, dynamic>))
            .toList(),
        isRestDay: json['isRestDay'] as bool,
      );
}

/// Complete study plan.
class StudyPlan {
  const StudyPlan({
    required this.id,
    required this.config,
    required this.days,
    this.isActive = true,
  });

  final String id;
  final StudyPlanConfig config;
  final List<StudyDay> days;
  final bool isActive;

  double get progressPercentage {
    final totalTasks = days.fold<int>(
      0,
      (sum, d) => sum + d.tasks.length,
    );
    if (totalTasks == 0) return 0;
    final completed = days.fold<int>(
      0,
      (sum, d) => sum + d.tasks.where((t) => t.isCompleted).length,
    );
    return (completed / totalTasks) * 100;
  }

  int get totalStudyHours =>
      days.fold(0, (sum, d) => sum + d.totalMinutes) ~/ 60;

  int get completedTasksCount => days.fold(
        0,
        (sum, d) => sum + d.completedTasks,
      );

  int get totalTasksCount => days.fold(
        0,
        (sum, d) => sum + d.tasks.length,
      );

  StudyDay? get todaySchedule {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    try {
      return days.firstWhere(
        (d) =>
            d.date.year == today.year &&
            d.date.month == today.month &&
            d.date.day == today.day,
      );
    } catch (_) {
      return null;
    }
  }

  List<StudyDay> get upcomingDays {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return days
        .where((d) => d.date.isAfter(today) || _isSameDay(d.date, today))
        .toList();
  }

  StudyPlan copyWith({
    String? id,
    StudyPlanConfig? config,
    List<StudyDay>? days,
    bool? isActive,
  }) {
    return StudyPlan(
      id: id ?? this.id,
      config: config ?? this.config,
      days: days ?? this.days,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'config': config.toJson(),
        'days': days.map((e) => e.toJson()).toList(),
        'isActive': isActive,
      };

  factory StudyPlan.fromJson(Map<String, dynamic> json) => StudyPlan(
        id: json['id'] as String,
        config: StudyPlanConfig.fromJson(
          json['config'] as Map<String, dynamic>,
        ),
        days: (json['days'] as List)
            .map((e) => StudyDay.fromJson(e as Map<String, dynamic>))
            .toList(),
        isActive: json['isActive'] as bool,
      );

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
