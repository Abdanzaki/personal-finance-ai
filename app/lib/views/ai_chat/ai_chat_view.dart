import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/ai_chat.dart';
import '../../providers/ai_chat_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class AiChatView extends ConsumerStatefulWidget {
  const AiChatView({super.key});

  @override
  ConsumerState<AiChatView> createState() => _AiChatViewState();
}

class _AiChatViewState extends ConsumerState<AiChatView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? textToSend]) {
    final query = textToSend ?? _textController.text.trim();
    if (query.isEmpty) return;

    if (textToSend == null) {
      _textController.clear();
    }
    _focusNode.unfocus();

    ref.read(aiChatProvider.notifier).sendMessage(query);
    _scrollToBottom();
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Clear Conversation?', style: AppTypography.titleLarge),
        content: Text(
          'This will permanently delete your AI conversation history from the server. Deterministic ledger facts and past transactions are not affected.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Cancel', style: AppTypography.labelLarge.copyWith(color: AppColors.outline)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.debitCrimson,
              foregroundColor: AppColors.onError,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ref.read(aiChatProvider.notifier).clearHistory();
            },
            child: const Text('Clear History'),
          ),
        ],
      ),
    );
  }

  void _showFactsDialog(BuildContext context, List<String> facts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin, vertical: AppSpacing.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.spaceMd),
                  decoration: BoxDecoration(
                    color: AppColors.slate200,
                    borderRadius: AppRadii.borderFull,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.verified, color: AppColors.growthEmerald, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Deterministic Grounding Facts (${facts.length})',
                      style: AppTypography.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.of(sheetCtx).pop(),
                  ),
                ],
              ),
              Text(
                'These facts were computed directly from your SQLite ledger by Python and supplied to Gemini to strictly eliminate arithmetic hallucination.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const Divider(height: AppSpacing.spaceLg),
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  itemCount: facts.length,
                  separatorBuilder: (context, index) => const Divider(height: 12),
                  itemBuilder: (_, idx) {
                    final fact = facts[idx];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.growthEmerald,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            fact,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForPrompt(String prompt) {
    final lower = prompt.toLowerCase();
    if (lower.contains('where') || lower.contains('money')) return Icons.pie_chart;
    if (lower.contains('food') || lower.contains('dining')) return Icons.restaurant;
    if (lower.contains('compare') || lower.contains('month')) return Icons.trending_up;
    if (lower.contains('budget') || lower.contains('exceed')) return Icons.warning_amber_rounded;
    if (lower.contains('savings') || lower.contains('plan')) return Icons.savings;
    if (lower.contains('gadget') || lower.contains('afford')) return Icons.shopping_bag;
    if (lower.contains('reduce') || lower.contains('cut')) return Icons.content_cut;
    return Icons.auto_awesome;
  }

  List<TextSpan> _parseFormattedText(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: baseStyle,
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(fontWeight: FontWeight.w700),
      ));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);

    // Auto-scroll when new messages arrive
    ref.listen<AiChatState>(aiChatProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length ||
          prev?.isSending != next.isSending) {
        _scrollToBottom();
      }
    });

    return Column(
      children: [
        // 1. Co-Pilot Header Status Banner
        _buildHeaderBanner(chatState),

        // 2. Unconfigured State Alert Card (HTTP 503 ai_not_configured)
        if (chatState.isAiNotConfigured)
          _buildUnconfiguredBanner()
        else ...[
          // 3. Quick Suggestion Prompts Track
          _buildPromptChips(chatState),

          const SizedBox(height: AppSpacing.spaceSm),

          // 4. Chat Message Thread
          Expanded(
            child: chatState.isLoadingHistory
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.growthEmerald,
                      strokeWidth: 2.5,
                    ),
                  )
                : _buildMessageList(chatState),
          ),
        ],

        // 5. Chat Input Bar
        _buildInputBar(chatState),
      ],
    );
  }

  Widget _buildHeaderBanner(AiChatState chatState) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.margin),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spaceMd,
          vertical: AppSpacing.spaceSm,
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.onPrimary,
                    size: 20,
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: chatState.isAiNotConfigured
                        ? AppColors.debitCrimson
                        : AppColors.growthEmerald,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surfaceContainerLowest,
                      width: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Financial Intelligence Co-Pilot',
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: chatState.isAiNotConfigured
                              ? AppColors.crimson50
                              : AppColors.secondaryContainer,
                          borderRadius: AppRadii.borderFull,
                        ),
                        child: Text(
                          chatState.isAiNotConfigured ? 'Offline' : 'v3.4 Grounded',
                          style: AppTypography.labelSmall.copyWith(
                            color: chatState.isAiNotConfigured
                                ? AppColors.debitCrimson
                                : AppColors.onSecondaryContainer,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    chatState.isAiNotConfigured
                        ? 'Gemini AI not configured on server'
                        : 'Online • Live Ledger & Budgets Synced',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (chatState.messages.isNotEmpty)
              IconButton(
                tooltip: 'Clear chat history',
                icon: const Icon(Icons.delete_outline, color: AppColors.outline, size: 20),
                onPressed: _confirmClearHistory,
              ),
            IconButton(
              tooltip: 'Sync financial telemetries',
              icon: const Icon(Icons.sync, color: AppColors.outline, size: 20),
              onPressed: () => ref.read(aiChatProvider.notifier).init(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnconfiguredBanner() {
    return Expanded(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(AppSpacing.spaceLg),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: AppRadii.borderLg,
              border: Border.all(color: AppColors.amberAlert.withAlpha(120), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.amber50,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.amberAlert.withAlpha(80)),
                  ),
                  child: const Icon(
                    Icons.key_off_rounded,
                    color: AppColors.amberDark,
                    size: 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.spaceMd),
                Text(
                  'AI Assistant Not Configured',
                  style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.spaceSm),
                Text(
                  'To enable real-time Gemini AI insights on your personal finance records, please set the GEMINI_API_KEY environment variable on the backend server.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.spaceMd),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.spaceSm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: AppRadii.borderDefault,
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.terminal, size: 16, color: AppColors.outline),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'backend/.env -> GEMINI_API_KEY=your_key_here',
                          style: AppTypography.labelSmall.copyWith(
                            fontFamily: 'monospace',
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.spaceSm),
                Text(
                  'Refer to README.md under "Gemini AI Configuration" for setup steps. Real AI answers will only be generated once configured (no mock chats).',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.outline),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.spaceLg),
                AppButton(
                  label: 'Check Server Connection Again',
                  variant: AppButtonVariant.primary,
                  icon: Icons.refresh,
                  onPressed: () {
                    ref.read(aiChatProvider.notifier).retryConfiguration();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPromptChips(AiChatState chatState) {
    final suggestions = chatState.suggestions;
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
      child: Row(
        children: suggestions.map((prompt) {
          final icon = _iconForPrompt(prompt);
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.spaceSm),
            child: InkWell(
              borderRadius: AppRadii.borderFull,
              onTap: chatState.isSending ? null : () => _sendMessage(prompt),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: AppRadii.borderFull,
                  border: Border.all(color: AppColors.slate200),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x05000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: AppColors.growthEmerald),
                    const SizedBox(width: 6),
                    Text(
                      prompt,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessageList(AiChatState chatState) {
    if (chatState.messages.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: AppColors.onPrimary, size: 28),
              ),
              const SizedBox(height: AppSpacing.spaceMd),
              Text(
                'Personal Finance Co-Pilot',
                style: AppTypography.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.spaceSm),
              Container(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  'Ask questions about your transactions, category totals, budgets, and savings goals. All metrics are computed deterministically before Gemini analyzes them.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final totalCount = chatState.messages.length + (chatState.isSending ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.margin,
        vertical: AppSpacing.spaceSm,
      ),
      itemCount: totalCount,
      itemBuilder: (context, idx) {
        if (idx == chatState.messages.length && chatState.isSending) {
          return _buildTypingBubble();
        }

        final msg = chatState.messages[idx];
        return _buildChatBubble(msg);
      },
    );
  }

  Widget _buildChatBubble(ChatMessageItem msg) {
    final isUser = msg.isUser;
    final timeStr = DateFormat('h:mm a').format(msg.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spaceMd),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: msg.isError ? AppColors.debitCrimson : AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                msg.isError ? Icons.error_outline : Icons.auto_awesome,
                color: AppColors.onPrimary,
                size: 16,
              ),
            ),
            const SizedBox(width: AppSpacing.spaceSm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.spaceMd),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.primaryContainer
                        : (msg.isError ? AppColors.crimsonSubtleBg : AppColors.surfaceContainerLowest),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                      bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                    ),
                    border: msg.isError ? Border.all(color: AppColors.crimsonBorder) : null,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: _parseFormattedText(
                            msg.content,
                            AppTypography.bodyMedium.copyWith(
                              color: isUser
                                  ? AppColors.onPrimary
                                  : (msg.isError ? AppColors.debitCrimson : AppColors.textPrimary),
                              height: 1.45,
                            ),
                          ),
                        ),
                      ),
                      if (msg.factsUsed.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.spaceSm),
                        InkWell(
                          onTap: () => _showFactsDialog(context, msg.factsUsed),
                          borderRadius: AppRadii.borderFull,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.emerald50,
                              borderRadius: AppRadii.borderFull,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified, size: 12, color: AppColors.growthEmerald),
                                const SizedBox(width: 4),
                                Text(
                                  'Grounded with ${msg.factsUsed.length} ledger facts',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.growthEmerald,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.chevron_right, size: 12, color: AppColors.growthEmerald),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  timeStr,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.outline,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spaceMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.onPrimary, size: 16),
          ),
          const SizedBox(width: AppSpacing.spaceSm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.zero,
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.growthEmerald,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Analyzing financial telemetries...',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(AiChatState chatState) {
    final isUnconfigured = chatState.isAiNotConfigured;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.slate200, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: AppRadii.borderDefault,
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 18, color: AppColors.primaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      enabled: !isUnconfigured && !chatState.isSending,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: isUnconfigured
                            ? 'Configure GEMINI_API_KEY to ask questions...'
                            : 'Ask Personal Finance AI anything...',
                        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.outline),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.spaceSm),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isUnconfigured || chatState.isSending)
                  ? AppColors.surfaceContainerHighest
                  : AppColors.growthEmerald,
              borderRadius: AppRadii.borderDefault,
            ),
            child: IconButton(
              icon: Icon(
                Icons.send,
                color: (isUnconfigured || chatState.isSending)
                    ? AppColors.outline
                    : AppColors.onPrimary,
                size: 20,
              ),
              onPressed: (isUnconfigured || chatState.isSending) ? null : () => _sendMessage(),
            ),
          ),
        ],
      ),
    );
  }
}
