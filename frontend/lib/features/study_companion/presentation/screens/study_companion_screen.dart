import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final _listKey = GlobalKey<AnimatedListState>();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentChatProvider);
    final messages = session?.messages ?? <ChatMessage>[];
    final selectedMode = ref.watch(explanationModeProvider);
    final hasMessages = messages.isNotEmpty;

    // Check if the last message is loading
    final isLoading = messages.isNotEmpty && messages.last.isLoading;

    // Auto-scroll when messages change
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      drawer: const ChatHistoryDrawer(),
      body: Column(
        children: [
          // App Bar area
          _buildAppBar(context, hasMessages),
          // Content area
          Expanded(
            child: hasMessages
                ? _buildMessageList(messages)
                : _buildEmptyState(selectedMode),
          ),
          // Mode selector (above input)
          if (hasMessages)
            ExplanationModeSelector(
              selectedMode: selectedMode,
              onModeSelected: (mode) {
                ref.read(currentChatProvider.notifier).setMode(mode);
              },
            ),
          // Input bar
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

  Widget _buildAppBar(BuildContext context, bool hasMessages) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              // Drawer/menu button
              Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.white),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  );
                },
              ),
              // Avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Study Companion',
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Always here to help',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              // New chat button
              if (hasMessages)
                IconButton(
                  icon: const Icon(
                    Icons.add_comment_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    ref.read(currentChatProvider.notifier).startNewChat();
                  },
                  tooltip: 'New Chat',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ExplanationMode selectedMode) {
    return SingleChildScrollView(
      child: Column(
        children: [
          WelcomeCard(
            onSuggestionTap: (suggestion) {
              ref.read(currentChatProvider.notifier).sendMessage(suggestion);
            },
          ),
          const SizedBox(height: 8),
          ExplanationModeSelector(
            selectedMode: selectedMode,
            onModeSelected: (mode) {
              ref.read(currentChatProvider.notifier).setMode(mode);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessage> messages) {
    return ListView.builder(
      key: _listKey,
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return ChatMessageBubble(message: messages[index]);
      },
    );
  }
}
