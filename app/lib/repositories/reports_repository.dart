import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../models/report.dart';
import '../services/api_client.dart';
import '../utils/download_helper.dart';

class ReportsRepository {
  final ApiClient apiClient;

  ReportsRepository({required this.apiClient});

  Future<ReportSummaryModel> getSummary({
    String timeframe = 'monthly',
    String? month,
  }) async {
    final queryParams = <String, dynamic>{
      'timeframe': timeframe,
    };
    if (month != null && month.isNotEmpty) {
      queryParams['month'] = month;
    }

    final response = await apiClient.get(
      '/reports/summary',
      queryParameters: queryParams,
    );

    return ReportSummaryModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> exportCsv({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{
      'format': 'csv',
    };
    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate.toIso8601String();
    }

    final response = await apiClient.get<String>(
      '/reports/export',
      queryParameters: queryParams,
      options: Options(responseType: ResponseType.plain),
    );

    return response.data ?? '';
  }

  Future<void> downloadCsvFile({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final csvContent = await exportCsv(startDate: startDate, endDate: endDate);
    final fileName = 'finance_ledger_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
    downloadFile(csvContent, fileName, mimeType: 'text/csv');
  }
}
