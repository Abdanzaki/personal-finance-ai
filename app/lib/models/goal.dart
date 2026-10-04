import '../utils/json.dart';

class SavingsGoalModel {
  final String id;
  final String userId;
  final String title;
  final String category;
  final double targetAmount;
  final double currentAmount;
  final String targetDate; // 'YYYY-MM-DD'
  final String? imageUrl;
  final bool isCompleted;
  final double progressPercentage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SavingsGoalModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    this.imageUrl,
    required this.isCompleted,
    required this.progressPercentage,
    this.createdAt,
    this.updatedAt,
  });

  double get remainingAmount => (targetAmount - currentAmount).clamp(0.0, double.infinity);

  factory SavingsGoalModel.fromJson(Map<String, dynamic> json) {
    return SavingsGoalModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      targetAmount: parseDouble(json['target_amount']),
      currentAmount: parseDouble(json['current_amount']),
      targetDate: json['target_date'] as String,
      imageUrl: json['image_url'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      progressPercentage: parseDouble(json['progress_percentage']),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'category': category,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
        'target_date': targetDate,
        'image_url': imageUrl,
        'is_completed': isCompleted,
        'progress_percentage': progressPercentage,
      };
}

class GoalListResponse {
  final double totalSaved;
  final double totalTarget;
  final int activeGoalsCount;
  final List<SavingsGoalModel> goals;

  const GoalListResponse({
    required this.totalSaved,
    required this.totalTarget,
    required this.activeGoalsCount,
    required this.goals,
  });

  double get overallProgressPercentage => totalTarget > 0 ? (totalSaved / totalTarget) * 100 : 0.0;

  factory GoalListResponse.fromJson(Map<String, dynamic> json) {
    final rawGoals = json['goals'] as List<dynamic>? ?? [];
    return GoalListResponse(
      totalSaved: parseDouble(json['total_saved']),
      totalTarget: parseDouble(json['total_target']),
      activeGoalsCount: parseInt(json['active_goals_count']),
      goals: rawGoals.map((e) => SavingsGoalModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class ContributionModel {
  final String id;
  final String goalId;
  final String userId;
  final double amount;
  final DateTime date;
  final String? note;
  final DateTime? createdAt;

  const ContributionModel({
    required this.id,
    required this.goalId,
    required this.userId,
    required this.amount,
    required this.date,
    this.note,
    this.createdAt,
  });

  factory ContributionModel.fromJson(Map<String, dynamic> json) {
    return ContributionModel(
      id: json['id'] as String,
      goalId: json['goal_id'] as String,
      userId: json['user_id'] as String,
      amount: parseDouble(json['amount']),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }
}
