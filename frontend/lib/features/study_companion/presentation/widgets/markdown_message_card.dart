import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../theme/color_tokens.dart';

/// Renders markdown content with custom styling matching the app design.
class MarkdownMessageCard extends StatelessWidget {
  const MarkdownMessageCard({
    super.key,
    required this.data,
  });

  final String data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return MarkdownBody(
      data: data,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        h1: textTheme.titleLarge?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        h2: textTheme.titleMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 17,
        ),
        h3: textTheme.titleSmall?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        p: textTheme.bodyMedium?.copyWith(
          color: colors.onSurface,
          height: 1.6,
          fontSize: 14,
        ),
        strong: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        em: TextStyle(
          fontStyle: FontStyle.italic,
          color: colors.onSurface.withValues(alpha: 0.8),
        ),
        blockquote: textTheme.bodyMedium?.copyWith(
          color: AppColors.primary,
          fontStyle: FontStyle.italic,
          height: 1.5,
        ),
        blockquoteDecoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: const Border(
            left: BorderSide(
              color: AppColors.primary,
              width: 3,
            ),
          ),
        ),
        blockquotePadding: const EdgeInsets.all(12),
        listBullet: textTheme.bodyMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          backgroundColor: colors.surfaceContainerHighest,
          color: AppColors.primaryDark,
        ),
        codeblockDecoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        tableHead: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: colors.onSurface,
        ),
        tableBody: textTheme.bodyMedium?.copyWith(
          color: colors.onSurface,
        ),
        tableBorder: TableBorder.all(
          color: AppColors.divider,
          width: 1,
        ),
        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        checkbox: textTheme.bodyMedium?.copyWith(
          color: colors.onSurface,
        ),
      ),
    );
  }
}
