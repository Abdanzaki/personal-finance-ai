import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/budget.dart';
import '../../providers/budgets_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/currency.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_progress_bar.dart';

const List<String> kBudgetCategories = [
  'Food & Dining',
  'Housing & Rent',
  'Groceries',
  'Transport',
  'Shopping',
  'Utilities',
  'Entertainment',
  'Healthcare',
  'Education',
  'Personal Care',
  'Travel',
  'General',
];

class BudgetsView extends ConsumerStatefulWidget {
  const BudgetsView({super.key});

  @override
  ConsumerState<BudgetsView> createState() => _BudgetsViewState();
}

class _BudgetsViewState extends ConsumerState<BudgetsView> {
  void _changeMonth(int deltaMonths) {
    final currentStr = ref.read(selectedBudgetMonthProvider);
    final parts = currentStr.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final date = DateTime(year, month + deltaMonths, 1);
    final newStr = DateFormat('yyyy-MM').format(date);
    ref.read(selectedBudgetMonthProvider.notifier).state = newStr;
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const _CreateBudgetDialog(),
    );
  }

  void _showEditDialog(BudgetModel budget) {
    showDialog(
      context: context,
      builder: (ctx) => _EditBudgetDialog(budget: budget),
    );
  }

  void _confirmDelete(BudgetModel budget) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text('Are you sure you want to delete the "${budget.category}" budget for ${budget.periodMonth}?'),
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
                await ref.read(budgetsProvider.notifier).deleteBudget(budget.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Budget deleted successfully')),
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
    final budgetsAsync = ref.watch(budgetsProvider);
    final selectedMonth = ref.watch(selectedBudgetMonthProvider);

    DateTime parsedDate;
    try {
      final parts = selectedMonth.split('-');
      parsedDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
    } catch (_) {
      parsedDate = DateTime.now();
    }
    final formattedMonthHeader = DateFormat('MMMM yyyy').format(parsedDate);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.growthEmerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Set Budget'),
        onPressed: _showCreateDialog,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(budgetsProvider.notifier).loadBudgets(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Month Selector Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Previous Month',
                    onPressed: () => _changeMonth(-1),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: AppColors.growthEmerald),
                      const SizedBox(width: 8),
                      Text(
                        formattedMonthHeader,
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'Next Month',
                    onPressed: () => _changeMonth(1),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.spaceSm),

              budgetsAsync.when(
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
                        Text('Failed to load budgets: $err', style: AppTypography.bodyMedium),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => ref.read(budgetsProvider.notifier).loadBudgets(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (budgetList) {
                  final items = budgetList.items;
                  final totalBudget = budgetList.totalBudget;
                  final totalSpent = budgetList.totalSpent;
                  final totalRemaining = budgetList.totalRemaining;
                  final overallPct = budgetList.overallPercentageUsed;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Executive Master Card
                      AppNavyCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$formattedMonthHeader Budget Health',
                                  style: AppTypography.titleMedium.copyWith(color: AppColors.onPrimary),
                                ),
                                AppBadge(
                                  label: overallPct >= 100
                                      ? 'Exceeded'
                                      : overallPct >= 80
                                          ? 'Warning'
                                          : 'On Track',
                                  variant: overallPct >= 100
                                      ? AppBadgeVariant.negative
                                      : overallPct >= 80
                                          ? AppBadgeVariant.warning
                                          : AppBadgeVariant.positive,
                                  showDot: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.spaceSm),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  InrFormatter.formatWhole(totalSpent),
                                  style: AppTypography.metricXl.copyWith(color: AppColors.onPrimary),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'spent of ${InrFormatter.formatWhole(totalBudget)} limit',
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.onPrimaryContainer),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.spaceMd),
                            AppProgressBar(
                              progress: totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0,
                              height: 10,
                              autoThresholdColor: true,
                            ),
                            const SizedBox(height: AppSpacing.spaceSm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${overallPct.toStringAsFixed(1)}% utilized',
                                  style: AppTypography.labelSmall.copyWith(color: AppColors.secondaryFixed),
                                ),
                                Text(
                                  '${InrFormatter.formatWhole(totalRemaining)} remaining',
                                  style: AppTypography.labelSmall.copyWith(color: AppColors.onPrimaryContainer),
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
                            'Category Allocations',
                            style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${items.length} Categories',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.spaceMd),

                      if (items.isEmpty)
                        AppCard(
                          padding: const EdgeInsets.all(AppSpacing.spaceLg),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.pie_chart_outline, size: 48, color: AppColors.textSecondary),
                                const SizedBox(height: 12),
                                Text('No category budgets defined for $formattedMonthHeader', style: AppTypography.titleMedium),
                                const SizedBox(height: 4),
                                Text(
                                  'Set spending thresholds for food, shopping, utilities, and more to prevent overspending.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodySmall,
                                ),
                                const SizedBox(height: 16),
                                AppButton(
                                  label: 'Create First Budget',
                                  variant: AppButtonVariant.primary,
                                  onPressed: _showCreateDialog,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...items.map((b) {
                          final isNear = b.isWarning;
                          final isExceeded = b.isExceeded;

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
                                      Text(b.category, style: AppTypography.titleMedium),
                                      Row(
                                        children: [
                                          if (isExceeded)
                                            const AppBadge(
                                              label: 'Exceeded',
                                              variant: AppBadgeVariant.negative,
                                            )
                                          else if (isNear)
                                            const AppBadge(
                                              label: '80% Warning',
                                              variant: AppBadgeVariant.warning,
                                            )
                                          else
                                            const AppBadge(
                                              label: 'Healthy',
                                              variant: AppBadgeVariant.positive,
                                            ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 18),
                                            tooltip: 'Edit Limit',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _showEditDialog(b),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.debitCrimson),
                                            tooltip: 'Delete Budget',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _confirmDelete(b),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Spent: ${InrFormatter.formatWhole(b.spentAmount)}',
                                        style: AppTypography.metricMd.copyWith(
                                          color: isExceeded
                                              ? AppColors.debitCrimson
                                              : isNear
                                                  ? AppColors.amberAlert
                                                  : AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Limit: ${InrFormatter.formatWhole(b.limitAmount)}',
                                        style: AppTypography.bodySmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  AppProgressBar(
                                    progress: (b.percentageUsed / 100).clamp(0.0, 1.0),
                                    height: 8,
                                    autoThresholdColor: true,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${b.percentageUsed.toStringAsFixed(1)}% utilized',
                                        style: AppTypography.labelSmall,
                                      ),
                                      Text(
                                        '${InrFormatter.formatWhole(b.remainingAmount)} remaining',
                                        style: AppTypography.labelSmall.copyWith(
                                          color: b.remainingAmount == 0 ? AppColors.debitCrimson : AppColors.growthEmerald,
                                          fontWeight: FontWeight.w600,
                                        ),
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

class _CreateBudgetDialog extends ConsumerStatefulWidget {
  const _CreateBudgetDialog();

  @override
  ConsumerState<_CreateBudgetDialog> createState() => _CreateBudgetDialogState();
}

class _CreateBudgetDialogState extends ConsumerState<_CreateBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  String _category = 'Food & Dining';
  final TextEditingController _limitController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final limit = double.tryParse(_limitController.text.trim()) ?? 0.0;
    if (limit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget limit must be greater than zero')),
      );
      return;
    }

    final month = ref.read(selectedBudgetMonthProvider);

    setState(() => _isLoading = true);
    try {
      await ref.read(budgetsProvider.notifier).createBudget(
            category: _category,
            limitAmount: limit,
            periodMonth: month,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget created successfully')),
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
    final month = ref.watch(selectedBudgetMonthProvider);

    return AlertDialog(
      title: const Text('Set Category Budget'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Period: $month', style: AppTypography.bodySmall),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(),
              ),
              items: kBudgetCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _category = val);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _limitController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monthly Limit (₹) *',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Limit amount is required';
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
              : const Text('Save Budget', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _EditBudgetDialog extends ConsumerStatefulWidget {
  final BudgetModel budget;

  const _EditBudgetDialog({required this.budget});

  @override
  ConsumerState<_EditBudgetDialog> createState() => _EditBudgetDialogState();
}

class _EditBudgetDialogState extends ConsumerState<_EditBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _limitController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(text: widget.budget.limitAmount.toString());
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final limit = double.tryParse(_limitController.text.trim()) ?? 0.0;
    if (limit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget limit must be greater than zero')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(budgetsProvider.notifier).updateBudgetLimit(widget.budget.id, limit);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget limit updated successfully')),
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
      title: Text('Edit ${widget.budget.category} Budget'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Current spent: ${InrFormatter.formatWhole(widget.budget.spentAmount)}', style: AppTypography.bodySmall),
            const SizedBox(height: 12),
            TextFormField(
              controller: _limitController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'New Monthly Limit (₹) *',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Limit amount is required';
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
