import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/dashboard.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budgets_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/goals_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/currency.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_progress_bar.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final user = ref.watch(authProvider).user;
    final selectedPeriod = ref.watch(dashboardPeriodProvider);
    final budgetsAsync = ref.watch(budgetsProvider);
    final goalsAsync = ref.watch(goalsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(dashboardProvider.notifier).loadSummary(),
          ref.read(budgetsProvider.notifier).loadBudgets(),
          ref.read(goalsProvider.notifier).loadGoals(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.margin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Greeting & AI Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Namaste, ${user?.fullName.split(' ').first ?? 'Rohan'}',
                              style: AppTypography.headlineSmall.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('👋', style: TextStyle(fontSize: 18)),
                        ],
                      ),
                      Text(
                        'Here is your live financial command center',
                        style: AppTypography.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.spaceSm),
                const AppBadge(
                  label: 'Live Telemetry',
                  variant: AppBadgeVariant.positive,
                  showDot: true,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.spaceSm),

            // Date Range Filter Chips (Weekly / Monthly / Yearly / Custom)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Weekly', 'Monthly', 'Yearly', 'Custom'].map((period) {
                  final isSelected = selectedPeriod == period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(period),
                      selected: isSelected,
                      selectedColor: AppColors.primaryContainer,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                      backgroundColor: AppColors.surfaceContainerLowest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.primaryContainer : AppColors.slate200,
                        ),
                      ),
                      onSelected: (val) {
                        if (val) {
                          ref.read(dashboardPeriodProvider.notifier).state = period;
                          ref.read(dashboardProvider.notifier).loadSummary();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: AppSpacing.spaceMd),

            dashboardAsync.when(
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
                      Text('Error loading dashboard: $err', style: AppTypography.bodyMedium),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.read(dashboardProvider.notifier).loadSummary(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (summary) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Total Net Balance Master Card
                    _buildBalanceCard(summary),

                    const SizedBox(height: AppSpacing.spaceMd),

                    // Income / Outflow / Net Savings / Savings Rate 4-Metric Grid
                    _buildMetricCards(summary),

                    const SizedBox(height: AppSpacing.spaceMd),

                    // Visual Charts Section: Income vs Outflow BarChart + Category Donut
                    _buildChartsSection(summary),

                    const SizedBox(height: AppSpacing.spaceMd),

                    // AI Intelligence Pulse Card
                    _buildAiPulseCard(summary),

                    const SizedBox(height: AppSpacing.spaceMd),

                    // Active Budgets Health Section (with 80%/100% warning badges)
                    _buildBudgetsSection(context, budgetsAsync),

                    const SizedBox(height: AppSpacing.spaceMd),

                    // Active Goals Section
                    _buildGoalsSection(context, goalsAsync),

                    const SizedBox(height: AppSpacing.spaceMd),

                    // Recent Transactions Section
                    _buildRecentTransactionsSection(context, summary),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(DashboardSummaryModel summary) {
    return AppNavyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.onPrimaryContainer,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Total Net Balance',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.2),
                  borderRadius: AppRadii.borderFull,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.secondaryFixed, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Verified Ledger',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.secondaryFixed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          Text(
            InrFormatter.format(summary.totalBalance),
            style: AppTypography.metricXl.copyWith(
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          const Divider(color: Color(0x1FFFFFFF)),
          const SizedBox(height: AppSpacing.spaceSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                summary.primaryAccount,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onPrimaryContainer,
                ),
              ),
              Text(
                'Live Sync Active',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primaryFixed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards(DashboardSummaryModel summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;
        final inCard = AppCard(
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Inflow', style: AppTypography.labelMedium),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.emerald50,
                      borderRadius: AppRadii.borderFull,
                    ),
                    child: const Icon(Icons.arrow_upward, color: AppColors.growthEmerald, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spaceSm),
              Text(
                InrFormatter.formatSigned(summary.monthlyIn),
                style: AppTypography.metricMd.copyWith(color: AppColors.growthEmerald),
              ),
              const SizedBox(height: 2),
              Text('Monthly earnings', style: AppTypography.labelSmall),
            ],
          ),
        );

        final outCard = AppCard(
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Outflow', style: AppTypography.labelMedium),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.crimson50,
                      borderRadius: AppRadii.borderFull,
                    ),
                    child: const Icon(Icons.arrow_downward, color: AppColors.debitCrimson, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spaceSm),
              Text(
                InrFormatter.formatSigned(-summary.monthlyOut),
                style: AppTypography.metricMd.copyWith(color: AppColors.debitCrimson),
              ),
              const SizedBox(height: 2),
              Text('Monthly expenses', style: AppTypography.labelSmall),
            ],
          ),
        );

        final savingsCard = AppCard(
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Net Savings', style: AppTypography.labelMedium),
              const SizedBox(height: AppSpacing.spaceSm),
              Text(
                InrFormatter.formatWhole(summary.netSavings),
                style: AppTypography.metricMd.copyWith(
                  color: summary.netSavings >= 0 ? AppColors.growthEmerald : AppColors.debitCrimson,
                ),
              ),
              const SizedBox(height: 2),
              Text('Savings rate: ${summary.savingsRatePct}%', style: AppTypography.labelSmall),
            ],
          ),
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: inCard),
              const SizedBox(width: AppSpacing.spaceSm),
              Expanded(child: outCard),
              const SizedBox(width: AppSpacing.spaceSm),
              Expanded(child: savingsCard),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: inCard),
                const SizedBox(width: AppSpacing.spaceSm),
                Expanded(child: outCard),
              ],
            ),
            const SizedBox(height: AppSpacing.spaceSm),
            savingsCard,
          ],
        );
      },
    );
  }

  Widget _buildChartsSection(DashboardSummaryModel summary) {
    final maxVal = (summary.monthlyIn > summary.monthlyOut ? summary.monthlyIn : summary.monthlyOut);
    final chartMax = maxVal > 0 ? maxVal * 1.2 : 100000.0;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cashflow Velocity', style: AppTypography.titleMedium),
              Row(
                children: [
                  Container(width: 8, height: 8, color: AppColors.growthEmerald),
                  const SizedBox(width: 4),
                  Text('In', style: AppTypography.labelSmall),
                  const SizedBox(width: 8),
                  Container(width: 8, height: 8, color: AppColors.debitCrimson),
                  const SizedBox(width: 4),
                  Text('Out', style: AppTypography.labelSmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: chartMax,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            val.toInt() == 0 ? 'Monthly In' : 'Monthly Out',
                            style: AppTypography.labelSmall,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (val, _) {
                        return Text(InrFormatter.formatCompact(val), style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: summary.monthlyIn,
                        color: AppColors.growthEmerald,
                        width: 32,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: summary.monthlyOut,
                        color: AppColors.debitCrimson,
                        width: 32,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiPulseCard(DashboardSummaryModel summary) {
    final title = summary.aiPulse['title'] as String? ?? 'AI Intelligence Pulse';
    final message = summary.aiPulse['message'] as String? ?? 'Financial telemetry active.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer.withValues(alpha: 0.2),
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.secondaryContainer.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: AppRadii.borderDefault,
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.growthEmerald, size: 20),
          ),
          const SizedBox(width: AppSpacing.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const AppBadge(label: 'Real-time', variant: AppBadgeVariant.neutral),
                  ],
                ),
                const SizedBox(height: 4),
                Text(message, style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetsSection(BuildContext context, AsyncValue<dynamic> budgetsAsync) {
    return budgetsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
      data: (budgetData) {
        final items = budgetData.items;
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Active Budgets', style: AppTypography.titleMedium),
                TextButton(
                  onPressed: () => context.go('/budgets'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...items.take(3).map((b) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
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
                              Text(
                                '${InrFormatter.formatWhole(b.spentAmount)} / ${InrFormatter.formatWhole(b.limitAmount)}',
                                style: AppTypography.labelMedium,
                              ),
                              if (b.isWarning || b.isExceeded) ...[
                                const SizedBox(width: 6),
                                AppBadge(
                                  label: b.isExceeded ? 'Exceeded' : '80% Warning',
                                  variant: b.isExceeded ? AppBadgeVariant.negative : AppBadgeVariant.warning,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.spaceSm),
                      AppProgressBar(
                        progress: (b.percentageUsed / 100).clamp(0.0, 1.0),
                        height: 6,
                        autoThresholdColor: true,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildGoalsSection(BuildContext context, AsyncValue<dynamic> goalsAsync) {
    return goalsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
      data: (goalData) {
        final goals = goalData.goals;
        if (goals.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Savings Goals', style: AppTypography.titleMedium),
                TextButton(
                  onPressed: () => context.go('/goals'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...goals.take(2).map((g) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.spaceMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(g.title, style: AppTypography.titleMedium),
                          Text(
                            '${InrFormatter.formatWhole(g.currentAmount)} / ${InrFormatter.formatWhole(g.targetAmount)}',
                            style: AppTypography.labelMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.spaceSm),
                      AppProgressBar(
                        progress: (g.progressPercentage / 100).clamp(0.0, 1.0),
                        height: 6,
                        color: AppColors.growthEmerald,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildRecentTransactionsSection(BuildContext context, DashboardSummaryModel summary) {
    final txs = summary.recentTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Activity', style: AppTypography.titleMedium),
            TextButton(
              onPressed: () => context.go('/transactions'),
              child: const Text('View All'),
            ),
          ],
        ),
        if (txs.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.spaceLg),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 36, color: AppColors.textSecondary),
                  const SizedBox(height: 8),
                  Text('No transactions recorded yet', style: AppTypography.bodyMedium),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.go('/transactions'),
                    child: const Text('Record Transaction'),
                  ),
                ],
              ),
            ),
          )
        else
          ...txs.map((tx) {
            final isExpense = tx.isExpense;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isExpense ? AppColors.crimson50 : AppColors.emerald50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isExpense ? AppColors.debitCrimson : AppColors.growthEmerald,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tx.title, style: AppTypography.titleMedium),
                          Text(
                            '${tx.category} • ${DateFormat('dd MMM').format(tx.date)}',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      isExpense
                          ? InrFormatter.formatSigned(-tx.amount)
                          : InrFormatter.formatSigned(tx.amount),
                      style: AppTypography.titleMedium.copyWith(
                        color: isExpense ? AppColors.debitCrimson : AppColors.growthEmerald,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
