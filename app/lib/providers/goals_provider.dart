import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/goal.dart';
import '../repositories/goals_repository.dart';
import 'auth_provider.dart';

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return GoalsRepository(apiClient: apiClient);
});

class GoalsNotifier extends StateNotifier<AsyncValue<GoalListResponse>> {
  final GoalsRepository _repository;

  GoalsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadGoals();
  }

  Future<void> loadGoals() async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.getGoals();
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createGoal({
    required String title,
    required String category,
    required double targetAmount,
    double? initialDeposit,
    required String targetDate,
    String? imageUrl,
  }) async {
    await _repository.createGoal(
      title: title,
      category: category,
      targetAmount: targetAmount,
      initialDeposit: initialDeposit,
      targetDate: targetDate,
      imageUrl: imageUrl,
    );
    await loadGoals();
  }

  Future<void> updateGoal(
    String id, {
    String? title,
    String? category,
    double? targetAmount,
    String? targetDate,
    String? imageUrl,
    bool? isCompleted,
  }) async {
    await _repository.updateGoal(
      id,
      title: title,
      category: category,
      targetAmount: targetAmount,
      targetDate: targetDate,
      imageUrl: imageUrl,
      isCompleted: isCompleted,
    );
    await loadGoals();
  }

  Future<void> deleteGoal(String id) async {
    await _repository.deleteGoal(id);
    await loadGoals();
  }

  Future<void> addContribution(
    String goalId, {
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    await _repository.addContribution(
      goalId,
      amount: amount,
      date: date,
      note: note,
    );
    await loadGoals();
  }

  Future<List<ContributionModel>> getContributions(String goalId) async {
    return await _repository.getContributions(goalId);
  }
}

final goalsProvider =
    StateNotifierProvider<GoalsNotifier, AsyncValue<GoalListResponse>>((ref) {
  final repository = ref.watch(goalsRepositoryProvider);
  return GoalsNotifier(repository);
});
