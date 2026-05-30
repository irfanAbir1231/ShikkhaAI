import 'package:flutter/material.dart';

import '../../../../theme/color_tokens.dart';

/// Subject color — single pastel-blue accent for minimalist consistency.
Color subjectColor(String subject) => AppColors.primary;

/// Maps a subject name to a Material icon.
IconData subjectIcon(String subject) {
  final lower = subject.toLowerCase();
  if (lower.contains('science')) return Icons.science;
  if (lower.contains('math') || lower.contains('mathematics')) {
    return Icons.calculate;
  }
  if (lower.contains('physics')) return Icons.speed;
  if (lower.contains('chemistry')) return Icons.local_florist;
  if (lower.contains('biology')) return Icons.biotech;
  if (lower.contains('english')) return Icons.translate;
  if (lower.contains('bangla') || lower.contains('bengali')) {
    return Icons.menu_book;
  }
  if (lower.contains('ict')) return Icons.computer;
  return Icons.school;
}
