import '../models/ai_chat.dart';
import '../services/api_client.dart';

class AiRepository {
  final ApiClient apiClient;

  AiRepository({required this.apiClient});

  Future<AiChatResponse> sendMessage(
    String message, {
    String? conversationId,
  }) async {
    final payload = <String, dynamic>{
      'message': message.trim(),
    };
    if (conversationId != null) {
      payload['conversation_id'] = conversationId;
    }

    final response = await apiClient.post(
      '/ai/chat',
      data: payload,
    );
    return AiChatResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ChatMessageItem>> getHistory() async {
    final response = await apiClient.get('/ai/history');
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => ChatMessageItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> clearHistory() async {
    await apiClient.delete('/ai/history');
  }

  Future<List<String>> getSuggestions() async {
    final response = await apiClient.get('/ai/suggestions');
    final data = AiSuggestionsResponse.fromJson(response.data as Map<String, dynamic>);
    return data.suggestions;
  }
}
