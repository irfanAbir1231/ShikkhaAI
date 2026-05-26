import 'package:flutter/material.dart';

import '../../../../theme/color_tokens.dart';

/// Maps a subject name to a color.
Color subjectColor(String subject) {
  final lower = subject.toLowerCase();
  if (lower.contains('science')) return const Color(0xFF10B981);
  if (lower.contains('math') || lower.contains('mathematics')) {
    return const Color(0xFF3B82F6);
  }
  if (lower.contains('physics')) return const Color(0xFF8B5CF6);
  if (lower.contains('chemistry')) return const Color(0xFFF59E0B);
  if (lower.contains('biology')) return const Color(0xFFEC4899);
  if (lower.contains('english')) return const Color(0xFF6366F1);
  if (lower.contains('bangla') || lower.contains('bengali')) {
    return const Color(0xFFEF4444);
  }
  if (lower.contains('ict')) return const Color(0xFF06B6D4);
  return AppColors.primary;
}

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
