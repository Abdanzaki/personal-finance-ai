import '../models/budget.dart';
import '../services/api_client.dart';

class BudgetsRepository {
  final ApiClient apiClient;

  BudgetsRepository({required this.apiClient});

  Future<BudgetListResponse> getBudgets({String? month}) async {
    final queryParams = <String, dynamic>{};
    if (month != null && month.isNotEmpty) {
      queryParams['month'] = month;
    }

    final response = await apiClient.get(
      '/budgets',
      queryParameters: queryParams,
    );

    return BudgetListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<BudgetModel> getBudget(String id) async {
    final response = await apiClient.get('/budgets/$id');
    return BudgetModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<BudgetModel> createBudget({
    required String category,
    required double limitAmount,
    required String periodMonth,
  }) async {
    final response = await apiClient.post(
      '/budgets',
      data: {
        'category': category.trim(),
        'limit_amount': limitAmount,
        'period_month': periodMonth,
      },
    );
    return BudgetModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<BudgetModel> updateBudget(
    String id, {
    required double limitAmount,
  }) async {
    final response = await apiClient.put(
      '/budgets/$id',
      data: {
        'limit_amount': limitAmount,
      },
    );
    return BudgetModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteBudget(String id) async {
    await apiClient.delete('/budgets/$id');
  }
}
