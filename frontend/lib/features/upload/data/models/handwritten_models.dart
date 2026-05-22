import 'package:flutter/material.dart';

/// Upload lifecycle status.
enum UploadStatus {
  selecting,
  preview,
  processing,
  completed,
  error,
}

extension UploadStatusExt on UploadStatus {
  String get label {
    return switch (this) {
      UploadStatus.selecting => 'Select Image',
      UploadStatus.preview => 'Preview',
      UploadStatus.processing => 'Processing',
      UploadStatus.completed => 'Completed',
      UploadStatus.error => 'Error',
    };
  }
}

/// A handwritten answer upload record.
class HandwrittenUpload {
  const HandwrittenUpload({
    required this.id,
    this.imagePath,
    this.subject,
    required this.uploadedAt,
    required this.status,
  });

  final String id;
  final String? imagePath;
  final String? subject;
  final DateTime uploadedAt;
  final UploadStatus status;

  HandwrittenUpload copyWith({
    String? id,
    String? imagePath,
    String? subject,
    DateTime? uploadedAt,
    UploadStatus? status,
  }) {
    return HandwrittenUpload(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      subject: subject ?? this.subject,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'subject': subject,
        'uploadedAt': uploadedAt.toIso8601String(),
        'status': status.name,
      };

  factory HandwrittenUpload.fromJson(Map<String, dynamic> json) =>
      HandwrittenUpload(
        id: json['id'] as String,
        imagePath: json['imagePath'] as String?,
        subject: json['subject'] as String?,
        uploadedAt: DateTime.parse(json['uploadedAt'] as String),
        status: UploadStatus.values.byName(json['status'] as String),
      );
}

/// Feedback for a single evaluation category.
class HandwrittenFeedback {
  const HandwrittenFeedback({
    required this.category,
    required this.score,
    required this.comment,
    required this.suggestions,
  });

  final String category; // Legibility, Spelling, Grammar, Structure, Content
  final double score; // 0-100
  final String comment;
  final List<String> suggestions;

  Color get scoreColor {
    if (score >= 80) return const Color(0xFF34D399);
    if (score >= 60) return const Color(0xFFFBBF24);
    return const Color(0xFFF87171);
  }

  HandwrittenFeedback copyWith({
    String? category,
    double? score,
    String? comment,
    List<String>? suggestions,
  }) {
    return HandwrittenFeedback(
      category: category ?? this.category,
      score: score ?? this.score,
      comment: comment ?? this.comment,
      suggestions: suggestions ?? this.suggestions,
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'score': score,
        'comment': comment,
        'suggestions': suggestions,
      };

  factory HandwrittenFeedback.fromJson(Map<String, dynamic> json) =>
      HandwrittenFeedback(
        category: json['category'] as String,
        score: (json['score'] as num).toDouble(),
        comment: json['comment'] as String,
        suggestions: (json['suggestions'] as List).cast<String>(),
      );
}

/// A weak area identified in the handwritten work.
class WeakArea {
  const WeakArea({
    required this.area,
    required this.description,
    required this.severity,
  });

  final String area;
  final String description;
  final double severity; // 0-100

  Color get severityColor {
    if (severity >= 70) return const Color(0xFFF87171);
    if (severity >= 40) return const Color(0xFFFBBF24);
    return const Color(0xFF34D399);
  }

  WeakArea copyWith({
    String? area,
    String? description,
    double? severity,
  }) {
    return WeakArea(
      area: area ?? this.area,
      description: description ?? this.description,
      severity: severity ?? this.severity,
    );
  }

  Map<String, dynamic> toJson() => {
        'area': area,
        'description': description,
        'severity': severity,
      };

  factory WeakArea.fromJson(Map<String, dynamic> json) => WeakArea(
        area: json['area'] as String,
        description: json['description'] as String,
        severity: (json['severity'] as num).toDouble(),
      );
}

/// Complete AI evaluation result for a handwritten upload.
class HandwrittenEvaluation {
  const HandwrittenEvaluation({
    required this.id,
    required this.uploadId,
    required this.overallScore,
    required this.grade,
    required this.feedback,
    required this.weakAreas,
    required this.aiComment,
    required this.evaluatedAt,
  });

  final String id;
  final String uploadId;
  final double overallScore; // 0-100
  final String grade; // A, B, C, D, F
  final List<HandwrittenFeedback> feedback;
  final List<WeakArea> weakAreas;
  final String aiComment;
  final DateTime evaluatedAt;

  double get averageFeedbackScore {
    if (feedback.isEmpty) return 0;
    return feedback.map((f) => f.score).reduce((a, b) => a + b) / feedback.length;
  }

  HandwrittenEvaluation copyWith({
    String? id,
    String? uploadId,
    double? overallScore,
    String? grade,
    List<HandwrittenFeedback>? feedback,
    List<WeakArea>? weakAreas,
    String? aiComment,
    DateTime? evaluatedAt,
  }) {
    return HandwrittenEvaluation(
      id: id ?? this.id,
      uploadId: uploadId ?? this.uploadId,
      overallScore: overallScore ?? this.overallScore,
      grade: grade ?? this.grade,
      feedback: feedback ?? this.feedback,
      weakAreas: weakAreas ?? this.weakAreas,
      aiComment: aiComment ?? this.aiComment,
      evaluatedAt: evaluatedAt ?? this.evaluatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'uploadId': uploadId,
        'overallScore': overallScore,
        'grade': grade,
        'feedback': feedback.map((e) => e.toJson()).toList(),
        'weakAreas': weakAreas.map((e) => e.toJson()).toList(),
        'aiComment': aiComment,
        'evaluatedAt': evaluatedAt.toIso8601String(),
      };

  factory HandwrittenEvaluation.fromJson(Map<String, dynamic> json) =>
      HandwrittenEvaluation(
        id: json['id'] as String,
        uploadId: json['uploadId'] as String,
        overallScore: (json['overallScore'] as num).toDouble(),
        grade: json['grade'] as String,
        feedback: (json['feedback'] as List)
            .map((e) => HandwrittenFeedback.fromJson(e as Map<String, dynamic>))
            .toList(),
        weakAreas: (json['weakAreas'] as List)
            .map((e) => WeakArea.fromJson(e as Map<String, dynamic>))
            .toList(),
        aiComment: json['aiComment'] as String,
        evaluatedAt: DateTime.parse(json['evaluatedAt'] as String),
      );
}
