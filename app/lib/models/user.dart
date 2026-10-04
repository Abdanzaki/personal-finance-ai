import '../utils/json.dart';

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String currency;
  final double? monthlyIncomeTarget;
  final double? monthlySavingsTarget;
  final bool isActive;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.currency = 'INR',
    this.monthlyIncomeTarget,
    this.monthlySavingsTarget,
    this.isActive = true,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      currency: json['currency'] as String? ?? 'INR',
      monthlyIncomeTarget: parseDoubleOrNull(json['monthly_income_target']),
      monthlySavingsTarget: parseDoubleOrNull(json['monthly_savings_target']),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'currency': currency,
        'monthly_income_target': monthlyIncomeTarget,
        'monthly_savings_target': monthlySavingsTarget,
        'is_active': isActive,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? currency,
    double? monthlyIncomeTarget,
    double? monthlySavingsTarget,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      currency: currency ?? this.currency,
      monthlyIncomeTarget: monthlyIncomeTarget ?? this.monthlyIncomeTarget,
      monthlySavingsTarget: monthlySavingsTarget ?? this.monthlySavingsTarget,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
