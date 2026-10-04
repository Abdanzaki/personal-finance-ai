import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/goal.dart';
import '../../providers/goals_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/currency.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_progress_bar.dart';

const List<String> kGoalCategories = [
  'Safety Net',
  'Vehicle',
  'Home',
  'Travel',
  'Electronics',
  'Education',
  'Retirement',
  'General',
];

class GoalsView extends ConsumerStatefulWidget {
  const GoalsView({super.key});

  @override
  ConsumerState<GoalsView> createState() => _GoalsViewState();
}

class _GoalsViewState extends ConsumerState<GoalsView> {
  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const _CreateGoalDialog(),
    );
  }

  void _showEditDialog(SavingsGoalModel goal) {
    showDialog(
      context: context,
      builder: (ctx) => _EditGoalDialog(goal: goal),
    );
  }

  void _showContributionDialog(SavingsGoalModel goal) {
    showDialog(
      context: context,
      builder: (ctx) => _ContributionDialog(goal: goal),
    );
  }

  void _confirmDelete(SavingsGoalModel goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${goal.title}"? All progress records will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.debitCrimson),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(goalsProvider.notifier).deleteGoal(goal.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Goal deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.growthEmerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
        onPressed: _showCreateDialog,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(goalsProvider.notifier).loadGoals(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Savings Goals',
                        style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Track milestones and disciplined wealth accumulation',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => ref.read(goalsProvider.notifier).loadGoals(),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.spaceMd),

              goalsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => AppCard(
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.debitCrimson, size: 36),
                        const SizedBox(height: 8),
                        Text('Failed to load goals: $err', style: AppTypography.bodyMedium),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => ref.read(goalsProvider.notifier).loadGoals(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (goalList) {
                  final goals = goalList.goals;
                  final totalSaved = goalList.totalSaved;
                  final totalTarget = goalList.totalTarget;
                  final activeCount = goalList.activeGoalsCount;
                  final overallPct = goalList.overallProgressPercentage;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Overview Portfolio Master Card
                      AppNavyCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.stars, color: AppColors.secondaryFixed, size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      'PORTFOLIO MILESTONES',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.onPrimaryContainer,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                                AppBadge(
                                  label: '$activeCount Active Goals',
                                  variant: AppBadgeVariant.positive,
                                  showDot: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.spaceMd),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Saved Across Goals',
                                      style: AppTypography.labelMedium.copyWith(
                                        color: AppColors.onPrimaryContainer,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      InrFormatter.formatWhole(totalSaved),
                                      style: AppTypography.displayLarge.copyWith(
                                        color: AppColors.onPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Target: ${InrFormatter.formatWhole(totalTarget)} portfolio',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.onPrimaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 68,
                                  height: 68,
                                  padding: const EdgeInsets.all(4),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        value: (overallPct / 100).clamp(0.0, 1.0),
                                        strokeWidth: 6,
                                        backgroundColor: const Color(0x3379849B),
                                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryFixed),
                                      ),
                                      Text(
                                        '${overallPct.toStringAsFixed(0)}%',
                                        style: AppTypography.labelLarge.copyWith(
                                          color: AppColors.onPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.spaceLg),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Active Targets',
                            style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${goals.length} Goals',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.spaceMd),

                      if (goals.isEmpty)
                        AppCard(
                          padding: const EdgeInsets.all(AppSpacing.spaceLg),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.savings_outlined, size: 48, color: AppColors.textSecondary),
                                const SizedBox(height: 12),
                                Text('No savings goals created yet', style: AppTypography.titleMedium),
                                const SizedBox(height: 4),
                                Text(
                                  'Create a target for an emergency fund, travel, vehicle, or dream purchase.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodySmall,
                                ),
                                const SizedBox(height: 16),
                                AppButton(
                                  label: 'Create First Goal',
                                  variant: AppButtonVariant.primary,
                                  onPressed: _showCreateDialog,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...goals.map((g) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: AppCard(
                              padding: const EdgeInsets.all(AppSpacing.spaceMd),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: AppColors.growthEmerald.withValues(alpha: 0.15),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.savings, color: AppColors.growthEmerald, size: 18),
                                          ),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(g.title, style: AppTypography.titleMedium),
                                              Text('${g.category} • Target: ${g.targetDate}', style: AppTypography.bodySmall),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          if (g.isCompleted)
                                            const AppBadge(label: 'Completed', variant: AppBadgeVariant.positive)
                                          else
                                            AppBadge(label: '${g.progressPercentage.toStringAsFixed(0)}%', variant: AppBadgeVariant.neutral),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 18),
                                            tooltip: 'Edit Goal',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _showEditDialog(g),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.debitCrimson),
                                            tooltip: 'Delete Goal',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _confirmDelete(g),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Saved: ${InrFormatter.formatWhole(g.currentAmount)}',
                                        style: AppTypography.metricMd.copyWith(color: AppColors.growthEmerald),
                                      ),
                                      Text(
                                        'Target: ${InrFormatter.formatWhole(g.targetAmount)}',
                                        style: AppTypography.bodySmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  AppProgressBar(
                                    progress: (g.progressPercentage / 100).clamp(0.0, 1.0),
                                    height: 8,
                                    color: AppColors.growthEmerald,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${InrFormatter.formatWhole(g.remainingAmount)} remaining',
                                        style: AppTypography.labelSmall,
                                      ),
                                      TextButton.icon(
                                        icon: const Icon(Icons.add_circle_outline, size: 16),
                                        label: const Text('Add Contribution'),
                                        onPressed: () => _showContributionDialog(g),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 64),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateGoalDialog extends ConsumerStatefulWidget {
  const _CreateGoalDialog();

  @override
  ConsumerState<_CreateGoalDialog> createState() => _CreateGoalDialogState();
}

class _CreateGoalDialogState extends ConsumerState<_CreateGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _targetAmountController = TextEditingController();
  final TextEditingController _initialDepositController = TextEditingController();
  String _category = 'Safety Net';
  DateTime _targetDate = DateTime.now().add(const Duration(days: 365));
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    _initialDepositController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final target = double.tryParse(_targetAmountController.text.trim()) ?? 0.0;
    if (target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target amount must be greater than zero')),
      );
      return;
    }
    final initial = double.tryParse(_initialDepositController.text.trim()) ?? 0.0;

    setState(() => _isLoading = true);
    try {
      await ref.read(goalsProvider.notifier).createGoal(
            title: _titleController.text.trim(),
            category: _category,
            targetAmount: target,
            initialDeposit: initial,
            targetDate: DateFormat('yyyy-MM-dd').format(_targetDate),
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Savings goal created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Savings Goal'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Goal Title *',
                  hintText: 'e.g. Emergency Fund, EV Car, Goa Trip',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Title is required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                ),
                items: kGoalCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Target Amount (₹) *',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Target amount is required';
                  final n = double.tryParse(val.trim());
                  if (n == null || n <= 0) return 'Enter a positive amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _initialDepositController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Initial Deposit (₹, optional)',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text('Target Date: ${DateFormat('dd MMM yyyy').format(_targetDate)}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _targetDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2040),
                  );
                  if (picked != null) {
                    setState(() => _targetDate = picked);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.growthEmerald),
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Create Goal', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _EditGoalDialog extends ConsumerStatefulWidget {
  final SavingsGoalModel goal;

  const _EditGoalDialog({required this.goal});

  @override
  ConsumerState<_EditGoalDialog> createState() => _EditGoalDialogState();
}

class _EditGoalDialogState extends ConsumerState<_EditGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _targetAmountController;
  late String _category;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal.title);
    _targetAmountController = TextEditingController(text: widget.goal.targetAmount.toString());
    _category = kGoalCategories.contains(widget.goal.category) ? widget.goal.category : 'General';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final target = double.tryParse(_targetAmountController.text.trim()) ?? 0.0;
    if (target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target amount must be greater than zero')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(goalsProvider.notifier).updateGoal(
            widget.goal.id,
            title: _titleController.text.trim(),
            category: _category,
            targetAmount: target,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.goal.title}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Title is required';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(),
              ),
              items: kGoalCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _category = val);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _targetAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Target Amount (₹) *',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Target is required';
                final n = double.tryParse(val.trim());
                if (n == null || n <= 0) return 'Enter a positive amount';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.growthEmerald),
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Update', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _ContributionDialog extends ConsumerStatefulWidget {
  final SavingsGoalModel goal;

  const _ContributionDialog({required this.goal});

  @override
  ConsumerState<_ContributionDialog> createState() => _ContributionDialogState();
}

class _ContributionDialogState extends ConsumerState<_ContributionDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contribution amount must be greater than zero')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(goalsProvider.notifier).addContribution(
            widget.goal.id,
            amount: amount,
            date: DateTime.now(),
            note: _noteController.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Allocated ${InrFormatter.format(amount)} to "${widget.goal.title}"'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Contribute to ${widget.goal.title}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Current Progress: ${InrFormatter.formatWhole(widget.goal.currentAmount)} / ${InrFormatter.formatWhole(widget.goal.targetAmount)}',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Contribution Amount (₹) *',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Amount is required';
                final n = double.tryParse(val.trim());
                if (n == null || n <= 0) return 'Enter a positive amount';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. March salary bonus, Freelance payout',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.growthEmerald),
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Add Contribution', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
