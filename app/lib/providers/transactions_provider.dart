import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../repositories/transactions_repository.dart';
import 'auth_provider.dart';

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TransactionsRepository(apiClient: apiClient);
});

class TransactionFilterState {
  final String search;
  final String category;
  final String type; // 'All' | 'income' | 'expense'
  final String sort; // 'date_desc' | 'date_asc' | 'amount_desc' | 'amount_asc'
  final DateTime? startDate;
  final DateTime? endDate;

  const TransactionFilterState({
    this.search = '',
    this.category = 'All',
    this.type = 'All',
    this.sort = 'date_desc',
    this.startDate,
    this.endDate,
  });

  TransactionFilterState copyWith({
    String? search,
    String? category,
    String? type,
    String? sort,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return TransactionFilterState(
      search: search ?? this.search,
      category: category ?? this.category,
      type: type ?? this.type,
      sort: sort ?? this.sort,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

final transactionFilterProvider = StateProvider<TransactionFilterState>((ref) {
  return const TransactionFilterState();
});

class TransactionsNotifier extends StateNotifier<AsyncValue<TransactionListResponse>> {
  final TransactionsRepository _repository;
  final Ref _ref;

  TransactionsNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    final filters = _ref.read(transactionFilterProvider);
    state = const AsyncValue.loading();
    try {
      final result = await _repository.getTransactions(
        category: filters.category == 'All' ? null : filters.category,
        type: filters.type == 'All' ? null : filters.type,
        search: filters.search.trim().isEmpty ? null : filters.search.trim(),
        sort: filters.sort,
        startDate: filters.startDate,
        endDate: filters.endDate,
      );
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createTransaction({
    required String type,
    required double amount,
    required String description,
    required String category,
    required DateTime date,
    required String paymentMethod,
  }) async {
    await _repository.createTransaction(
      type: type,
      amount: amount,
      description: description,
      category: category,
      date: date,
      paymentMethod: paymentMethod,
    );
    await loadTransactions();
  }

  Future<void> updateTransaction(
    String id, {
    String? type,
    double? amount,
    String? description,
    String? category,
    DateTime? date,
    String? paymentMethod,
  }) async {
    await _repository.updateTransaction(
      id,
      type: type,
      amount: amount,
      description: description,
      category: category,
      date: date,
      paymentMethod: paymentMethod,
    );
    await loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    await _repository.deleteTransaction(id);
    await loadTransactions();
  }
}

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, AsyncValue<TransactionListResponse>>((ref) {
  final repository = ref.watch(transactionsRepositoryProvider);
  // Re-run whenever filters change
  ref.watch(transactionFilterProvider);
  return TransactionsNotifier(repository, ref);
});
