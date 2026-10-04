import '../models/goal.dart';
import '../services/api_client.dart';

class GoalsRepository {
  final ApiClient apiClient;

  GoalsRepository({required this.apiClient});

  Future<GoalListResponse> getGoals() async {
    final response = await apiClient.get('/goals');
    return GoalListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SavingsGoalModel> getGoal(String id) async {
    final response = await apiClient.get('/goals/$id');
    return SavingsGoalModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SavingsGoalModel> createGoal({
    required String title,
    required String category,
    required double targetAmount,
    double? initialDeposit,
    required String targetDate,
    String? imageUrl,
  }) async {
    final data = <String, dynamic>{
      'title': title.trim(),
      'category': category.trim(),
      'target_amount': targetAmount,
      'target_date': targetDate,
    };
    if (initialDeposit != null && initialDeposit > 0) {
      data['initial_deposit'] = initialDeposit;
    }
    if (imageUrl != null) {
      data['image_url'] = imageUrl;
    }

    final response = await apiClient.post(
      '/goals',
      data: data,
    );
    return SavingsGoalModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SavingsGoalModel> updateGoal(
    String id, {
    String? title,
    String? category,
    double? targetAmount,
    String? targetDate,
    String? imageUrl,
    bool? isCompleted,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title.trim();
    if (category != null) data['category'] = category.trim();
    if (targetAmount != null) data['target_amount'] = targetAmount;
    if (targetDate != null) data['target_date'] = targetDate;
    if (imageUrl != null) data['image_url'] = imageUrl;
    if (isCompleted != null) data['is_completed'] = isCompleted;

    final response = await apiClient.put(
      '/goals/$id',
      data: data,
    );
    return SavingsGoalModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteGoal(String id) async {
    await apiClient.delete('/goals/$id');
  }

  Future<ContributionModel> addContribution(
    String goalId, {
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final data = <String, dynamic>{
      'amount': amount,
      'date': date.toIso8601String(),
    };
    if (note != null && note.trim().isNotEmpty) {
      data['note'] = note.trim();
    }

    final response = await apiClient.post(
      '/goals/$goalId/contributions',
      data: data,
    );
    return ContributionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ContributionModel>> getContributions(String goalId) async {
    final response = await apiClient.get('/goals/$goalId/contributions');
    final rawList = response.data as List<dynamic>? ?? [];
    return rawList.map((e) => ContributionModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
