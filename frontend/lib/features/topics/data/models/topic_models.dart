import 'dart:convert';

/// Represents a single topic with its completion status.
class TopicItem {
  const TopicItem({
    required this.id,
    required this.name,
    required this.subject,
    required this.completionPercentage,
    required this.attemptsCount,
    this.lastScore,
    this.lastAttempted,
    required this.isCompleted,
  });

  final String id;
  final String name;
  final String subject;
  final double completionPercentage;
  final int attemptsCount;
  final double? lastScore;
  final DateTime? lastAttempted;
  final bool isCompleted;

  factory TopicItem.fromJson(Map<String, dynamic> json) {
    return TopicItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['topic'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      completionPercentage: (json['completion_percentage'] as num?)?.toDouble() ?? 0.0,
      attemptsCount: json['attempts_count'] as int? ?? 0,
      lastScore: (json['last_score'] as num?)?.toDouble(),
      lastAttempted: json['last_attempted'] != null
          ? DateTime.tryParse(json['last_attempted'] as String)
          : null,
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subject': subject,
        'completion_percentage': completionPercentage,
        'attempts_count': attemptsCount,
        'last_score': lastScore,
        'last_attempted': lastAttempted?.toIso8601String(),
        'is_completed': isCompleted,
      };

  TopicItem copyWith({
    String? id,
    String? name,
    String? subject,
    double? completionPercentage,
    int? attemptsCount,
    double? lastScore,
    DateTime? lastAttempted,
    bool? isCompleted,
  }) {
    return TopicItem(
      id: id ?? this.id,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      attemptsCount: attemptsCount ?? this.attemptsCount,
      lastScore: lastScore ?? this.lastScore,
      lastAttempted: lastAttempted ?? this.lastAttempted,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Groups topics under a subject with aggregate stats.
class SubjectTopics {
  const SubjectTopics({
    required this.subject,
    this.iconName,
    required this.topics,
  });

  final String subject;
  final String? iconName;
  final List<TopicItem> topics;

  int get completedCount => topics.where((t) => t.isCompleted).length;
  int get totalCount => topics.length;

  double get overallCompletionPercentage {
    if (totalCount == 0) return 0;
    return topics.map((t) => t.completionPercentage).reduce((a, b) => a + b) / totalCount;
  }

  factory SubjectTopics.fromJson(Map<String, dynamic> json) {
    final topicsJson = json['topics'] as List<dynamic>? ?? const [];
    return SubjectTopics(
      subject: json['subject'] as String? ?? '',
      iconName: json['icon_name'] as String?,
      topics: topicsJson
          .map((t) => TopicItem.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'icon_name': iconName,
        'topics': topics.map((t) => t.toJson()).toList(),
      };
}

/// Root response wrapper for the topics screen.
class TopicsOverview {
  const TopicsOverview({
    required this.subjects,
    required this.totalTopics,
    required this.completedTopics,
  });

  final List<SubjectTopics> subjects;
  final int totalTopics;
  final int completedTopics;

  double get overallCompletionPercentage =>
      totalTopics == 0 ? 0 : (completedTopics / totalTopics) * 100;

  factory TopicsOverview.fromJson(Map<String, dynamic> json) {
    final subjectsJson = json['subjects'] as List<dynamic>? ?? const [];
    return TopicsOverview(
      subjects: subjectsJson
          .map((s) => SubjectTopics.fromJson(s as Map<String, dynamic>))
          .toList(),
      totalTopics: json['total_topics'] as int? ?? 0,
      completedTopics: json['completed_topics'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'subjects': subjects.map((s) => s.toJson()).toList(),
        'total_topics': totalTopics,
        'completed_topics': completedTopics,
      };

  String toJsonString() => jsonEncode(toJson());

  factory TopicsOverview.fromJsonString(String source) =>
      TopicsOverview.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
