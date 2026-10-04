import '../utils/json.dart';

class InsightModel {
  final String status;
  final String largestExpenseCategory;
  final double momSpendingChangePct;
  final String recommendation;

  const InsightModel({
    required this.status,
    required this.largestExpenseCategory,
    required this.momSpendingChangePct,
    required this.recommendation,
  });

  factory InsightModel.fromJson(Map<String, dynamic> json) {
    return InsightModel(
      status: json['status'] as String? ?? 'active',
      largestExpenseCategory: json['largest_expense_category'] as String? ?? 'Housing & Rent',
      momSpendingChangePct: parseDouble(json['mom_spending_change_pct']),
      recommendation: json['recommendation'] as String? ?? 'No new recommendations.',
    );
  }
}
