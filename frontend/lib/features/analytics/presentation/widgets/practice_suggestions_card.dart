import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common_widgets/animations/animated_scale_tap.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/color_tokens.dart';
import '../../../library/data/models/note_model.dart';
import '../../../library/presentation/providers/note_provider.dart';
import '../../data/models/analytics_models.dart';

/// Horizontal scrollable cards for personalized practice suggestions.
class PracticeSuggestionsCard extends StatelessWidget {
  const PracticeSuggestionsCard({super.key, required this.suggestions});

  final List<PracticeSuggestion> suggestions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppLocalizations.of(context).practiceTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _SuggestionCard(suggestion: suggestions[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _SuggestionCard extends ConsumerWidget {
  const _SuggestionCard({required this.suggestion});

  final PracticeSuggestion suggestion;

  void _openNote(BuildContext context) {
    final noteId = suggestion.noteId;
    if (noteId != null) {
      context.push('/library/note/$noteId');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).practiceNoteUnavailable)),
      );
    }
  }

  Future<void> _saveAsNote(BuildContext context, WidgetRef ref) async {
    final content = '${suggestion.description}\n\n---\n'
        '**Topic:** ${suggestion.topic}\n'
        '**Estimated time:** ${suggestion.estimatedMinutes} min\n'
        '**Potential impact:** ${suggestion.potentialImpact.toStringAsFixed(0)}%';
    final note = NoteModel(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      title: suggestion.title,
      content: content,
      topic: suggestion.topic,
      subject: suggestion.subject,
      source: 'practice',
      createdAt: DateTime.now(),
    );
    await ref.read(noteRepositoryProvider).saveNote(note);
    ref.read(notesRefreshProvider.notifier).state++;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).practiceSavedToLibrary)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final typeColor = suggestion.type.color;
    final l10n = AppLocalizations.of(context);

    return AnimatedScaleTap(
      onTap: () => _openNote(context),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    suggestion.type.icon,
                    color: typeColor,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    suggestion.type.label,
                    style: textTheme.bodySmall?.copyWith(
                      color: typeColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.bookmark_border, size: 18),
                  onPressed: () => _saveAsNote(context, ref),
                  tooltip: l10n.practiceSaveAsNote,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              suggestion.title,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              suggestion.description,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.minutesShort(suggestion.estimatedMinutes),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.trending_up,
                  size: 14,
                  color: AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.impactPercent(suggestion.potentialImpact.toStringAsFixed(0)),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Impact bar
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: suggestion.potentialImpact / 100,
                minHeight: 4,
                backgroundColor: AppColors.divider.withValues(alpha: 0.5),
                valueColor: AlwaysStoppedAnimation<Color>(typeColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
