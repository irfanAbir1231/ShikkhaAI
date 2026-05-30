import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/color_tokens.dart';
import '../../../../theme/neu_decoration.dart';
import '../../../library/data/models/note_model.dart';
import '../../../library/presentation/providers/note_provider.dart';
import '../../../library/presentation/widgets/save_note_bottom_sheet.dart';
import '../../data/models/chat_message_model.dart';
import 'ai_typing_indicator.dart';
import 'markdown_message_card.dart';
import 'mode_badge.dart';

/// Chat message bubble for user, AI, and system messages.
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
  });

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return _SystemBubble(message: message);
    }
    if (message.isUser) {
      return _UserBubble(message: message);
    }
    return _AiBubble(message: message);
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(
          left: 64,
          right: 16,
          top: 4,
          bottom: 4,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: NeuDecoration.colored(
          color: AppColors.primary,
          radius: 18,
          depth: 1,
        ).copyWith(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            if (message.fileName != null) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.attach_file_rounded,
                    color: Colors.white70,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      message.fileName!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AiBubble extends ConsumerWidget {
  const _AiBubble({required this.message});

  final ChatMessage message;

  String _inferTopic(AppLocalizations l10n) {
    final mode = message.explanationMode?.localizedLabel(l10n);
    if (mode != null && mode.isNotEmpty) return mode;
    return l10n.scAiExplanation;
  }

  String _inferTitle(AppLocalizations l10n) {
    final first = message.content.split('\n').firstWhere(
          (l) => l.trim().isNotEmpty,
          orElse: () => l10n.scAiNote,
        );
    final clean = first.replaceAll(RegExp(r'[#*`>_-]'), '').trim();
    return clean.length > 60 ? '${clean.substring(0, 60)}…' : clean;
  }

  void _onSaveTap(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SaveNoteBottomSheet(
        defaultTitle: _inferTitle(l10n),
        defaultTopic: _inferTopic(l10n),
        onSave: (title, topic) async {
          final note = NoteModel(
            id: 'local-${DateTime.now().microsecondsSinceEpoch}',
            title: title,
            content: message.content,
            topic: topic,
            source: 'study_companion',
            createdAt: DateTime.now(),
          );
          await ref.read(noteRepositoryProvider).saveNote(note);
          ref.read(notesRefreshProvider.notifier).state++;
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context).practiceSavedToLibrary)),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final hasSources = message.sources != null && message.sources!.isNotEmpty;
    final hasPdfContext =
        message.pdfContext != null && message.pdfContext!.isNotEmpty;
    final canSave = !message.isLoading && message.content.trim().isNotEmpty;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(
          left: 16,
          right: 64,
          top: 4,
          bottom: 4,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.explanationMode != null) ...[
              ModeBadge(mode: message.explanationMode!),
              const SizedBox(height: 10),
            ],
            if (message.isLoading && message.content.isEmpty)
              const AiTypingIndicator()
            else
              MarkdownMessageCard(data: message.content),
            if (hasPdfContext) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.compare_arrows,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      l10n.scCrossReferenced,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (hasSources) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: message.sources!.map((s) {
                  final src = s['source']?.toString() ?? l10n.scSourceDefault;
                  final page = s['page'];
                  final label =
                      page != null ? l10n.scSourcePage(src, '$page') : src;
                  return Chip(
                    avatar: const Icon(Icons.menu_book, size: 14),
                    label: Text(label,
                        style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.08),
                  );
                }).toList(),
              ),
            ],
            if (canSave)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    message.isSaved ? Icons.bookmark : Icons.bookmark_border,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _onSaveTap(context, ref),
                  tooltip: l10n.practiceSaveAsNote,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SystemBubble extends StatelessWidget {
  const _SystemBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.divider.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}
