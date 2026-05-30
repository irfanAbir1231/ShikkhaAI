import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

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

  String localizedLabel(AppLocalizations l10n) {
    return switch (this) {
      ExplanationMode.easyBengali => l10n.scModeEasyBengaliLabel,
      ExplanationMode.easyEnglish => l10n.scModeEasyEnglishLabel,
      ExplanationMode.explainLike10 => l10n.scModeExplain10Label,
      ExplanationMode.summary => l10n.scModeSummaryLabel,
      ExplanationMode.importantQuestions => l10n.scModeImportantQLabel,
      ExplanationMode.commonMistakes => l10n.scModeCommonMistakesLabel,
      ExplanationMode.examTips => l10n.scModeExamTipsLabel,
    };
  }

  String localizedSubtitle(AppLocalizations l10n) {
    return switch (this) {
      ExplanationMode.easyBengali => l10n.scModeEasyBengaliSubtitle,
      ExplanationMode.easyEnglish => l10n.scModeEasyEnglishSubtitle,
      ExplanationMode.explainLike10 => l10n.scModeExplain10Subtitle,
      ExplanationMode.summary => l10n.scModeSummarySubtitle,
      ExplanationMode.importantQuestions => l10n.scModeImportantQSubtitle,
      ExplanationMode.commonMistakes => l10n.scModeCommonMistakesSubtitle,
      ExplanationMode.examTips => l10n.scModeExamTipsSubtitle,
    };
  }

  String get jsonValue => name;

  static ExplanationMode fromJson(String value) {
    return ExplanationMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExplanationMode.easyEnglish,
    );
  }
}
