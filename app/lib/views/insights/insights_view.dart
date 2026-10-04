import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/budgets_provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/insights_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/currency.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_card.dart';

class InsightsView extends ConsumerWidget {
  const InsightsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(insightsProvider);
    final budgetsAsync = ref.watch(budgetsProvider);
    final goalsAsync = ref.watch(goalsProvider);

    return SingleChildScrollView(
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
                    'Smart Insights & Advisory',
                    style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Deterministic ledger calculations combined with AI advisory',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Insights',
                onPressed: () {
                  ref.read(insightsProvider.notifier).loadInsights();
                  ref.read(budgetsProvider.notifier).loadBudgets();
                  ref.read(goalsProvider.notifier).loadGoals();
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.spaceMd),

          insightsAsync.when(
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
                    Text('Failed to load insights: $err', style: AppTypography.bodyMedium),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.read(insightsProvider.notifier).loadInsights(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (insight) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Largest Category Card (Fact)
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.spaceLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.pie_chart, color: AppColors.obsidianNavy, size: 20),
                                const SizedBox(width: 8),
                                Text('Top Expenditure Driver', style: AppTypography.titleMedium),
                              ],
                            ),
                            const AppBadge(
                              label: 'FACT',
                              variant: AppBadgeVariant.neutral,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.spaceSm),
                        Text(
                          insight.largestExpenseCategory,
                          style: AppTypography.metricLg.copyWith(color: AppColors.obsidianNavy),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This category accounts for the highest single portion of your outflows this billing cycle.',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.spaceMd),

                  // 2. MoM Velocity Card (Fact)
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.spaceLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.trending_down, color: AppColors.growthEmerald, size: 20),
                                const SizedBox(width: 8),
                                Text('Month-over-Month Velocity', style: AppTypography.titleMedium),
                              ],
                            ),
                            const AppBadge(
                              label: 'FACT',
                              variant: AppBadgeVariant.neutral,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.spaceSm),
                        Text(
                          '${insight.momSpendingChangePct >= 0 ? '+' : ''}${insight.momSpendingChangePct}% spending change',
                          style: AppTypography.metricLg.copyWith(
                            color: insight.momSpendingChangePct <= 0
                                ? AppColors.growthEmerald
                                : AppColors.debitCrimson,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          insight.momSpendingChangePct <= 0
                              ? 'Your spending velocity decreased compared to previous month, preserving capital.'
                              : 'Your spending pace has accelerated compared to last month.',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.spaceMd),

                  // 3. AI Savings Recommendation (Estimate / Advisory)
                  AppNavyCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome, color: AppColors.secondaryFixed, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'AI Financial Advisory',
                                  style: AppTypography.titleMedium.copyWith(color: AppColors.onPrimary),
                                ),
                              ],
                            ),
                            const AppBadge(
                              label: 'ESTIMATE & ADVISORY',
                              variant: AppBadgeVariant.positive,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.spaceMd),
                        Text(
                          insight.recommendation,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.onPrimary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.spaceSm),
                        Text(
                          'Derived deterministically from recent payment trends and category limits.',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.onPrimaryContainer),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.spaceMd),

                  // 4. Near-Limit Budgets (Fact)
                  budgetsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (err, stack) => const SizedBox.shrink(),
                    data: (budgetData) {
                      final nearLimit = budgetData.items.where((b) => b.isWarning || b.isExceeded).toList();
                      if (nearLimit.isEmpty) {
                        return AppCard(
                          padding: const EdgeInsets.all(AppSpacing.spaceMd),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: AppColors.growthEmerald, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'All category budgets are currently under safe spending limits (<80%).',
                                  style: AppTypography.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Budgets Nearing Limits', style: AppTypography.titleMedium),
                          const SizedBox(height: 8),
                          ...nearLimit.map(
                            (b) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: AppCard(
                                padding: const EdgeInsets.all(AppSpacing.spaceMd),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(b.category, style: AppTypography.titleMedium),
                                        Text(
                                          '${InrFormatter.formatWhole(b.spentAmount)} of ${InrFormatter.formatWhole(b.limitAmount)} (${b.percentageUsed.toStringAsFixed(1)}%)',
                                          style: AppTypography.bodySmall,
                                        ),
                                      ],
                                    ),
                                    AppBadge(
                                      label: b.isExceeded ? 'Exceeded' : 'Near Limit (>=80%)',
                                      variant: b.isExceeded ? AppBadgeVariant.negative : AppBadgeVariant.warning,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.spaceMd),

                  // 5. Portfolio Goals Progress (Fact)
                  goalsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (err, stack) => const SizedBox.shrink(),
                    data: (goalData) {
                      return AppCard(
                        padding: const EdgeInsets.all(AppSpacing.spaceLg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.savings_outlined, color: AppColors.obsidianNavy, size: 20),
                                    const SizedBox(width: 8),
                                    Text('Savings Portfolio Status', style: AppTypography.titleMedium),
                                  ],
                                ),
                                const AppBadge(label: 'FACT', variant: AppBadgeVariant.neutral),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.spaceSm),
                            Text(
                              '${InrFormatter.formatWhole(goalData.totalSaved)} saved of ${InrFormatter.formatWhole(goalData.totalTarget)} total targets (${goalData.overallProgressPercentage.toStringAsFixed(1)}%)',
                              style: AppTypography.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${goalData.activeGoalsCount} milestone targets currently in progress.',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
