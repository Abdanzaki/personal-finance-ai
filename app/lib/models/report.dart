import '../utils/json.dart';

class ReportSummaryModel {
  final String timeframe;
  final String? month;
  final bool auditReady;
  final double tax80cLimit;
  final double tax80cUtilized;

  const ReportSummaryModel({
    required this.timeframe,
    this.month,
    required this.auditReady,
    required this.tax80cLimit,
    required this.tax80cUtilized,
  });

  double get taxRemainingGap => (tax80cLimit - tax80cUtilized).clamp(0.0, double.infinity);
  double get taxProgressPercentage => tax80cLimit > 0 ? (tax80cUtilized / tax80cLimit) * 100 : 0.0;

  factory ReportSummaryModel.fromJson(Map<String, dynamic> json) {
    return ReportSummaryModel(
      timeframe: json['timeframe'] as String? ?? 'monthly',
      month: json['month'] as String?,
      auditReady: json['audit_ready'] as bool? ?? true,
      tax80cLimit: parseDouble(json['tax_80c_limit'], 150000.0),
      tax80cUtilized: parseDouble(json['tax_80c_utilized']),
    );
  }
}
