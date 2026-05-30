import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/color_tokens.dart';

/// Types of questions supported in an exam.
enum QuestionType {
  mcq,
  shortAnswer,
  cq;

  String get label {
    return switch (this) {
      QuestionType.mcq => 'MCQ',
      QuestionType.shortAnswer => 'Short Answer',
      QuestionType.cq => 'CQ',
    };
  }

  String localizedLabel(AppLocalizations l10n) {
    return switch (this) {
      QuestionType.mcq => l10n.qTypeMcq,
      QuestionType.shortAnswer => l10n.qTypeShortAnswer,
      QuestionType.cq => l10n.qTypeCq,
    };
  }

  IconData get icon {
    return switch (this) {
      QuestionType.mcq => Icons.check_circle_outline,
      QuestionType.shortAnswer => Icons.short_text,
      QuestionType.cq => Icons.format_list_numbered,
    };
  }

  String get jsonValue => name;

  static QuestionType fromJson(String value) {
    return QuestionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => QuestionType.mcq,
    );
  }
}

/// Difficulty levels for exam generation.
enum ExamDifficulty {
  easy,
  medium,
  hard;

  String get label {
    return switch (this) {
      ExamDifficulty.easy => 'Easy',
      ExamDifficulty.medium => 'Medium',
      ExamDifficulty.hard => 'Hard',
    };
  }

  String localizedLabel(AppLocalizations l10n) {
    return switch (this) {
      ExamDifficulty.easy => l10n.diffEasy,
      ExamDifficulty.medium => l10n.diffMedium,
      ExamDifficulty.hard => l10n.diffHard,
    };
  }

  Color get color {
    return switch (this) {
      ExamDifficulty.easy => AppColors.success,
      ExamDifficulty.medium => AppColors.warning,
      ExamDifficulty.hard => AppColors.danger,
    };
  }

  String get jsonValue => name;

  static ExamDifficulty fromJson(String value) {
    return ExamDifficulty.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExamDifficulty.medium,
    );
  }
}

/// Exam style/type.
enum ExamType {
  practice,
  ssc,
  hsc;

  String get label {
    return switch (this) {
      ExamType.practice => 'Practice',
      ExamType.ssc => 'SSC',
      ExamType.hsc => 'HSC',
    };
  }

  String localizedLabel(AppLocalizations l10n) {
    return switch (this) {
      ExamType.practice => l10n.examTypePractice,
      ExamType.ssc => l10n.examTypeSsc,
      ExamType.hsc => l10n.examTypeHsc,
    };
  }

  String get subtitle {
    return switch (this) {
      ExamType.practice => 'Customizable quick exam',
      ExamType.ssc => 'SSC Board Exam Style',
      ExamType.hsc => 'HSC Board Exam Style',
    };
  }

  String localizedSubtitle(AppLocalizations l10n) {
    return switch (this) {
      ExamType.practice => l10n.examTypePracticeSubtitle,
      ExamType.ssc => l10n.examTypeSscSubtitle,
      ExamType.hsc => l10n.examTypeHscSubtitle,
    };
  }

  IconData get icon {
    return switch (this) {
      ExamType.practice => Icons.school_outlined,
      ExamType.ssc => Icons.assignment_outlined,
      ExamType.hsc => Icons.menu_book_outlined,
    };
  }

  /// Default time limit in minutes.
  int get defaultTimeLimitMinutes {
    return switch (this) {
      ExamType.practice => 30,
      ExamType.ssc => 180,
      ExamType.hsc => 180,
    };
  }

  /// Default number of questions.
  int get defaultNumQuestions {
    return switch (this) {
      ExamType.practice => 10,
      ExamType.ssc => 38,
      ExamType.hsc => 38,
    };
  }

  String get jsonValue => name;

  static ExamType fromJson(String value) {
    return ExamType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExamType.practice,
    );
  }
}

/// Status of a question during an exam session.
enum QuestionStatus {
  unanswered,
  answered,
  markedForReview;

  Color get color {
    return switch (this) {
      QuestionStatus.unanswered => AppColors.textSecondary,
      QuestionStatus.answered => AppColors.success,
      QuestionStatus.markedForReview => AppColors.warning,
    };
  }

  String get jsonValue => name;

  static QuestionStatus fromJson(String value) {
    return QuestionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => QuestionStatus.unanswered,
    );
  }
}
