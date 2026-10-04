class ChatMessageItem {
  final String? id;
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime createdAt;
  final List<String> factsUsed;
  final bool isError;

  ChatMessageItem({
    this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.factsUsed = const [],
    this.isError = false,
  });

  bool get isUser => role == 'user';

  factory ChatMessageItem.fromJson(Map<String, dynamic> json) {
    return ChatMessageItem(
      id: json['id']?.toString(),
      role: json['role'] as String? ?? 'assistant',
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      factsUsed: (json['facts_used'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isError: json['is_error'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'role': role,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'facts_used': factsUsed,
      'is_error': isError,
    };
  }
}

class AiChatResponse {
  final String answer;
  final List<String> factsUsed;
  final String? conversationId;

  AiChatResponse({
    required this.answer,
    this.factsUsed = const [],
    this.conversationId,
  });

  factory AiChatResponse.fromJson(Map<String, dynamic> json) {
    return AiChatResponse(
      answer: json['answer'] as String? ?? '',
      factsUsed: (json['facts_used'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      conversationId: json['conversation_id'] as String?,
    );
  }
}

class AiSuggestionsResponse {
  final List<String> suggestions;

  AiSuggestionsResponse({required this.suggestions});

  factory AiSuggestionsResponse.fromJson(Map<String, dynamic> json) {
    return AiSuggestionsResponse(
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
