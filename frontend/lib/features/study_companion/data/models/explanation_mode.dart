import 'package:flutter/material.dart';

/// The 7 AI explanation modes available in the Study Companion.
enum ExplanationMode {
  easyBengali('Easy Bengali', 'সহজ বাংলায় বুঝুন', Icons.translate),
  easyEnglish('Easy English', 'Simple English', Icons.language),
  explainLike10('Explain Like I\'m 10', 'Super simple!', Icons.child_care),
  summary('Summary', 'Quick overview', Icons.summarize),
  importantQuestions('Important Questions', 'Key exam questions', Icons.quiz),
  commonMistakes('Common Mistakes', 'Avoid errors', Icons.error_outline),
  examTips('Exam Tips', 'Score higher', Icons.school);

  const ExplanationMode(this.label, this.subtitle, this.icon);

  final String label;
  final String subtitle;
  final IconData icon;

  String get jsonValue => name;

  static ExplanationMode fromJson(String value) {
    return ExplanationMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExplanationMode.easyEnglish,
    );
  }
}
