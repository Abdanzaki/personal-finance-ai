import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_chat.dart';
import '../repositories/ai_repository.dart';
import '../services/api_client.dart';
import 'auth_provider.dart';

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AiRepository(apiClient: apiClient);
});

class AiChatState {
  final List<ChatMessageItem> messages;
  final List<String> suggestions;
  final bool isLoadingHistory;
  final bool isSending;
  final bool isAiNotConfigured;
  final String? errorMessage;

  const AiChatState({
    this.messages = const [],
    this.suggestions = const [
      'Where did most of my money go this month?',
      'How much did I spend on food?',
      'Compare this month vs last month',
      'Which categories could I reduce?',
      'Am I exceeding any budgets?',
      'Help me create a monthly savings plan',
    ],
    this.isLoadingHistory = false,
    this.isSending = false,
    this.isAiNotConfigured = false,
    this.errorMessage,
  });

  AiChatState copyWith({
    List<ChatMessageItem>? messages,
    List<String>? suggestions,
    bool? isLoadingHistory,
    bool? isSending,
    bool? isAiNotConfigured,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      suggestions: suggestions ?? this.suggestions,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      isSending: isSending ?? this.isSending,
      isAiNotConfigured: isAiNotConfigured ?? this.isAiNotConfigured,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AiChatNotifier extends StateNotifier<AiChatState> {
  final AiRepository _repository;

  AiChatNotifier(this._repository) : super(const AiChatState()) {
    init();
  }

  Future<void> init() async {
    state = state.copyWith(isLoadingHistory: true, clearError: true);
    try {
      // 1. Load suggested prompts
      try {
        final suggestions = await _repository.getSuggestions();
        if (suggestions.isNotEmpty) {
          state = state.copyWith(suggestions: suggestions);
        }
      } catch (_) {
        // Fallback to initial default suggestions if suggestions request fails
      }

      // 2. Load conversation history
      final history = await _repository.getHistory();
      state = state.copyWith(
        messages: history,
        isLoadingHistory: false,
        isAiNotConfigured: false,
        clearError: true,
      );
    } on ApiException catch (e) {
      if (e.isAiNotConfigured) {
        state = state.copyWith(
          isLoadingHistory: false,
          isAiNotConfigured: true,
          errorMessage: e.message,
        );
      } else {
        state = state.copyWith(
          isLoadingHistory: false,
          errorMessage: e.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingHistory: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || state.isSending) return;

    // Optimistic user message append
    final userMessage = ChatMessageItem(
      role: 'user',
      content: query,
      createdAt: DateTime.now(),
    );

    final updatedMessages = List<ChatMessageItem>.from(state.messages)..add(userMessage);

    state = state.copyWith(
      messages: updatedMessages,
      isSending: true,
      clearError: true,
    );

    try {
      final response = await _repository.sendMessage(query);

      final assistantMessage = ChatMessageItem(
        role: 'assistant',
        content: response.answer,
        createdAt: DateTime.now(),
        factsUsed: response.factsUsed,
      );

      state = state.copyWith(
        messages: List<ChatMessageItem>.from(state.messages)..add(assistantMessage),
        isSending: false,
        isAiNotConfigured: false,
        clearError: true,
      );
    } on ApiException catch (e) {
      if (e.isAiNotConfigured) {
        state = state.copyWith(
          isSending: false,
          isAiNotConfigured: true,
          errorMessage: e.message,
        );
      } else {
        final errMessage = ChatMessageItem(
          role: 'assistant',
          content: 'Unable to complete request: ${e.message}',
          createdAt: DateTime.now(),
          isError: true,
        );
        state = state.copyWith(
          messages: List<ChatMessageItem>.from(state.messages)..add(errMessage),
          isSending: false,
          errorMessage: e.message,
        );
      }
    } catch (e) {
      final errMessage = ChatMessageItem(
        role: 'assistant',
        content: 'An unexpected error occurred: ${e.toString()}',
        createdAt: DateTime.now(),
        isError: true,
      );
      state = state.copyWith(
        messages: List<ChatMessageItem>.from(state.messages)..add(errMessage),
        isSending: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> clearHistory() async {
    try {
      await _repository.clearHistory();
      state = state.copyWith(messages: const [], clearError: true);
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void retryConfiguration() {
    state = state.copyWith(isAiNotConfigured: false, clearError: true);
    init();
  }
}

final aiChatProvider = StateNotifierProvider<AiChatNotifier, AiChatState>((ref) {
  final repository = ref.watch(aiRepositoryProvider);
  return AiChatNotifier(repository);
});
