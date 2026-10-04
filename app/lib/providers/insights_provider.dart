import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/insight.dart';
import '../repositories/insights_repository.dart';
import 'auth_provider.dart';

final insightsRepositoryProvider = Provider<InsightsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return InsightsRepository(apiClient: apiClient);
});

class InsightsNotifier extends StateNotifier<AsyncValue<InsightModel>> {
  final InsightsRepository _repository;

  InsightsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadInsights();
  }

  Future<void> loadInsights() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repository.getInsights();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final insightsProvider =
    StateNotifierProvider<InsightsNotifier, AsyncValue<InsightModel>>((ref) {
  final repository = ref.watch(insightsRepositoryProvider);
  return InsightsNotifier(repository);
});
