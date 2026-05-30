import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/color_tokens.dart';

import '../../data/models/chat_message_model.dart';
import '../../data/models/explanation_mode.dart';
import '../providers/study_companion_provider.dart';
import '../widgets/chat_history_drawer.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/explanation_mode_selector.dart';
import '../widgets/message_input_bar.dart';
import '../widgets/welcome_card.dart';

/// Main AI Study Companion chat screen.
class StudyCompanionScreen extends ConsumerStatefulWidget {
  const StudyCompanionScreen({super.key});

  @override
  ConsumerState<StudyCompanionScreen> createState() =>
      _StudyCompanionScreenState();
}

class _StudyCompanionScreenState extends ConsumerState<StudyCompanionScreen> {
  final _scrollController = ScrollController();
  int _lastMessageCount = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentChatProvider);
    final messages = session?.messages ?? const <ChatMessage>[];
    final selectedMode = ref.watch(explanationModeProvider);
    final hasMessages = messages.isNotEmpty;

    final isLoading = hasMessages && messages.last.isLoading;

    // Only auto-scroll when a new message is appended (or when the last
    // message is still streaming). Rebuilds caused by typing in the input
    // field no longer trigger an unwanted scroll.
    final shouldScroll =
        messages.length > _lastMessageCount || isLoading;
    _lastMessageCount = messages.length;
    if (shouldScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    return Scaffold(
      drawer: const ChatHistoryDrawer(),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          _buildAppBar(context, hasMessages, selectedMode),
          Expanded(
            child: hasMessages
                ? _buildMessageList(messages)
                : _buildEmptyState(),
          ),
          _ModeSelectorHeader(
            selectedMode: selectedMode,
            onModeSelected: (mode) {
              ref.read(currentChatProvider.notifier).setMode(mode);
            },
          ),
          MessageInputBar(
            isLoading: isLoading,
            onSend: (text) {
              ref.read(currentChatProvider.notifier).sendMessage(text);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    bool hasMessages,
    ExplanationMode selectedMode,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB87A4B), Color(0xFF8B5A2B), Color(0xFF6B3E1F)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.scTitle,
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      selectedMode.localizedLabel(l10n),
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (hasMessages)
                IconButton(
                  icon: const Icon(
                    Icons.add_comment_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    ref.read(currentChatProvider.notifier).startNewChat();
                  },
                  tooltip: l10n.scNewChat,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: WelcomeCard(
        onSuggestionTap: (suggestion) {
          ref.read(currentChatProvider.notifier).sendMessage(suggestion);
        },
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return ChatMessageBubble(message: messages[index]);
      },
    );
  }
}

/// Persistent header + horizontal mode selector shown above the input bar.
/// Makes "Study Mode" discoverable at all times — not hidden inside the
/// empty-state welcome card.
class _ModeSelectorHeader extends StatelessWidget {
  const _ModeSelectorHeader({
    required this.selectedMode,
    required this.onModeSelected,
  });

  final ExplanationMode selectedMode;
  final ValueChanged<ExplanationMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final divider = isDark ? AppColors.dividerDark : AppColors.divider;
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: divider, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.scStudyMode,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedMode.localizedSubtitle(l10n),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          ExplanationModeSelector(
            selectedMode: selectedMode,
            onModeSelected: onModeSelected,
          ),
        ],
      ),
    );
  }
}
