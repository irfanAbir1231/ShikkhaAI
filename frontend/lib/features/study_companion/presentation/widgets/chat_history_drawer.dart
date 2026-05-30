import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/color_tokens.dart';

import '../../data/models/chat_session_model.dart';
import '../providers/study_companion_provider.dart';

/// Side drawer listing past chat sessions.
class ChatHistoryDrawer extends ConsumerWidget {
  const ChatHistoryDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(chatSessionsProvider);
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFB87A4B), Color(0xFF8B5A2B), Color(0xFF6B3E1F)],
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.scChatHistory,
                          style: textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          l10n.scConversationsCount(sessions.length),
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // New Chat button
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(currentChatProvider.notifier).startNewChat();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.scNewChat),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            // Session list
            Expanded(
              child: sessions.isEmpty
                  ? _EmptyHistory(textTheme: textTheme, l10n: l10n)
                  : ListView.builder(
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        return _SessionTile(
                          session: session,
                          onTap: () {
                            ref
                                .read(currentChatProvider.notifier)
                                .loadSession(session.id);
                            Navigator.of(context).pop();
                          },
                          onDelete: () {
                            ref
                                .read(chatSessionsProvider.notifier)
                                .deleteSession(session.id);
                          },
                        );
                      },
                    ),
            ),
            if (sessions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.scClearHistoryTitle),
                        content: Text(l10n.scClearHistoryBody),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text(l10n.commonCancel),
                          ),
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(chatSessionsProvider.notifier)
                                  .clearAll();
                              Navigator.of(ctx).pop();
                            },
                            child: Text(
                              l10n.commonClear,
                              style: const TextStyle(color: AppColors.danger),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.danger,
                    size: 18,
                  ),
                  label: Text(
                    l10n.examClearAll,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  final ChatSession session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final dateStr = DateFormat('MMM d, h:mm a').format(session.updatedAt);

    return Dismissible(
      key: ValueKey(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.danger.withValues(alpha: 0.1),
        child: const Icon(
          Icons.delete_rounded,
          color: AppColors.danger,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(
            Icons.chat_bubble_outline_rounded,
            color: AppColors.primary,
            size: 18,
          ),
        ),
        title: Text(
          session.title,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$dateStr · ${l10n.scMessagesCount(session.messageCount)}',
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.textTheme, required this.l10n});

  final TextTheme? textTheme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.scNoConversations,
            style: textTheme?.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.scStartNewChat,
            style: textTheme?.bodySmall?.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
