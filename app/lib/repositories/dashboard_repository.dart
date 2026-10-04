import '../models/dashboard.dart';
import '../services/api_client.dart';

class DashboardRepository {
  final ApiClient apiClient;

  DashboardRepository({required this.apiClient});

  Future<DashboardSummaryModel> getSummary() async {
    final response = await apiClient.get('/dashboard/summary');
    return DashboardSummaryModel.fromJson(response.data as Map<String, dynamic>);
  }
}
