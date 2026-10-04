import '../models/insight.dart';
import '../services/api_client.dart';

class InsightsRepository {
  final ApiClient apiClient;

  InsightsRepository({required this.apiClient});

  Future<InsightModel> getInsights() async {
    final response = await apiClient.get('/insights');
    return InsightModel.fromJson(response.data as Map<String, dynamic>);
  }
}
