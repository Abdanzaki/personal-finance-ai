import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../repositories/budgets_repository.dart';
import 'auth_provider.dart';

final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BudgetsRepository(apiClient: apiClient);
});

final selectedBudgetMonthProvider = StateProvider<String>((ref) {
  return DateFormat('yyyy-MM').format(DateTime.now());
});

class BudgetsNotifier extends StateNotifier<AsyncValue<BudgetListResponse>> {
  final BudgetsRepository _repository;
  final Ref _ref;

  BudgetsNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    final month = _ref.read(selectedBudgetMonthProvider);
    state = const AsyncValue.loading();
    try {
      final result = await _repository.getBudgets(month: month);
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createBudget({
    required String category,
    required double limitAmount,
    required String periodMonth,
  }) async {
    await _repository.createBudget(
      category: category,
      limitAmount: limitAmount,
      periodMonth: periodMonth,
    );
    await loadBudgets();
  }

  Future<void> updateBudgetLimit(String id, double limitAmount) async {
    await _repository.updateBudget(id, limitAmount: limitAmount);
    await loadBudgets();
  }

  Future<void> deleteBudget(String id) async {
    await _repository.deleteBudget(id);
    await loadBudgets();
  }
}

final budgetsProvider =
    StateNotifierProvider<BudgetsNotifier, AsyncValue<BudgetListResponse>>((ref) {
  final repository = ref.watch(budgetsRepositoryProvider);
  ref.watch(selectedBudgetMonthProvider);
  return BudgetsNotifier(repository, ref);
});
