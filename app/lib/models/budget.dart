class BudgetModel {
  final String id;
  final String userId;
  final String category;
  final double limitAmount;
  final String periodMonth; // 'YYYY-MM'
  final double spentAmount;
  final double remainingAmount;
  final double percentageUsed;
  final bool isWarning;
  final bool isExceeded;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BudgetModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.limitAmount,
    required this.periodMonth,
    required this.spentAmount,
    required this.remainingAmount,
    required this.percentageUsed,
    required this.isWarning,
    required this.isExceeded,
    this.createdAt,
    this.updatedAt,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      category: json['category'] as String,
      limitAmount: (json['limit_amount'] as num).toDouble(),
      periodMonth: json['period_month'] as String,
      spentAmount: (json['spent_amount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remaining_amount'] as num?)?.toDouble() ?? 0.0,
      percentageUsed: (json['percentage_used'] as num?)?.toDouble() ?? 0.0,
      isWarning: json['is_warning'] as bool? ?? false,
      isExceeded: json['is_exceeded'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'category': category,
        'limit_amount': limitAmount,
        'period_month': periodMonth,
        'spent_amount': spentAmount,
        'remaining_amount': remainingAmount,
        'percentage_used': percentageUsed,
        'is_warning': isWarning,
        'is_exceeded': isExceeded,
      };
}

class BudgetListResponse {
  final String month;
  final double totalBudget;
  final double totalSpent;
  final List<BudgetModel> items;

  const BudgetListResponse({
    required this.month,
    required this.totalBudget,
    required this.totalSpent,
    required this.items,
  });

  double get totalRemaining => (totalBudget - totalSpent).clamp(0.0, double.infinity);
  double get overallPercentageUsed => totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0.0;

  factory BudgetListResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return BudgetListResponse(
      month: json['month'] as String? ?? '',
      totalBudget: (json['total_budget'] as num?)?.toDouble() ?? 0.0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
      items: rawItems.map((e) => BudgetModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
