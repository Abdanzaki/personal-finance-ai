import '../utils/json.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String? accountId;
  final String type; // 'income' | 'expense'
  final double amount;
  final String description;
  final String category;
  final DateTime date;
  final String paymentMethod;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    this.accountId,
    required this.type,
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
    required this.paymentMethod,
    this.createdAt,
    this.updatedAt,
  });

  bool get isIncome => type.toLowerCase() == 'income';
  bool get isExpense => type.toLowerCase() == 'expense';

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      accountId: json['account_id'] as String?,
      type: json['type'] as String? ?? 'expense',
      amount: parseDouble(json['amount']),
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      date: DateTime.parse(json['date'] as String),
      paymentMethod: json['payment_method'] as String? ?? 'UPI',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'account_id': accountId,
        'type': type,
        'amount': amount,
        'description': description,
        'category': category,
        'date': date.toIso8601String(),
        'payment_method': paymentMethod,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };
}

class TransactionListResponse {
  final List<TransactionModel> items;
  final int total;
  final int page;
  final int size;

  const TransactionListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
  });

  factory TransactionListResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['items'] as List<dynamic>? ?? [];
    return TransactionListResponse(
      items: rawList.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)).toList(),
      total: parseInt(json['total']),
      page: parseInt(json['page'], 1),
      size: parseInt(json['size'], 50),
    );
  }
}
