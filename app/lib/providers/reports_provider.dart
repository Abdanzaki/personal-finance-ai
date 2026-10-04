import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report.dart';
import '../repositories/reports_repository.dart';
import 'auth_provider.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReportsRepository(apiClient: apiClient);
});

final reportsTimeframeProvider = StateProvider<String>((ref) {
  return 'monthly';
});

class ReportsNotifier extends StateNotifier<AsyncValue<ReportSummaryModel>> {
  final ReportsRepository _repository;
  final Ref _ref;

  ReportsNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadSummary();
  }

  Future<void> loadSummary() async {
    final timeframe = _ref.read(reportsTimeframeProvider);
    state = const AsyncValue.loading();
    try {
      final summary = await _repository.getSummary(timeframe: timeframe);
      state = AsyncValue.data(summary);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> downloadCsv({DateTime? startDate, DateTime? endDate}) async {
    await _repository.downloadCsvFile(startDate: startDate, endDate: endDate);
  }
}

final reportsProvider =
    StateNotifierProvider<ReportsNotifier, AsyncValue<ReportSummaryModel>>((ref) {
  final repository = ref.watch(reportsRepositoryProvider);
  ref.watch(reportsTimeframeProvider);
  return ReportsNotifier(repository, ref);
});
