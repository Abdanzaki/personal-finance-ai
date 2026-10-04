class RecentTransactionItem {
  final String id;
  final String title;
  final double amount;
  final String type;
  final String category;
  final DateTime date;

  const RecentTransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
  });

  bool get isIncome => type.toLowerCase() == 'income';
  bool get isExpense => type.toLowerCase() == 'expense';

  factory RecentTransactionItem.fromJson(Map<String, dynamic> json) {
    return RecentTransactionItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Transaction',
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String? ?? 'expense',
      category: json['category'] as String? ?? 'General',
      date: DateTime.parse(json['date'] as String),
    );
  }
}

class DashboardSummaryModel {
  final double totalBalance;
  final String primaryAccount;
  final double monthlyIn;
  final double monthlyOut;
  final double netSavings;
  final double savingsRatePct;
  final List<RecentTransactionItem> recentTransactions;
  final Map<String, dynamic> aiPulse;

  const DashboardSummaryModel({
    required this.totalBalance,
    required this.primaryAccount,
    required this.monthlyIn,
    required this.monthlyOut,
    required this.netSavings,
    required this.savingsRatePct,
    required this.recentTransactions,
    required this.aiPulse,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawRecent = json['recent_transactions'] as List<dynamic>? ?? [];
    return DashboardSummaryModel(
      totalBalance: (json['total_balance'] as num?)?.toDouble() ?? 0.0,
      primaryAccount: json['primary_account'] as String? ?? 'Primary Account',
      monthlyIn: (json['monthly_in'] as num?)?.toDouble() ?? 0.0,
      monthlyOut: (json['monthly_out'] as num?)?.toDouble() ?? 0.0,
      netSavings: (json['net_savings'] as num?)?.toDouble() ?? 0.0,
      savingsRatePct: (json['savings_rate_pct'] as num?)?.toDouble() ?? 0.0,
      recentTransactions: rawRecent.map((e) => RecentTransactionItem.fromJson(e as Map<String, dynamic>)).toList(),
      aiPulse: json['ai_pulse'] as Map<String, dynamic>? ?? {
        'title': 'AI Intelligence Pulse',
        'message': 'AI telemetry active and calculated from actual ledger records.',
      },
    );
  }
}
