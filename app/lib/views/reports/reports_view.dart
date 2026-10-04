import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/reports_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/currency.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_progress_bar.dart';

class ReportsView extends ConsumerStatefulWidget {
  const ReportsView({super.key});

  @override
  ConsumerState<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends ConsumerState<ReportsView> {
  bool _isExporting = false;

  Future<void> _handleCsvExport() async {
    setState(() => _isExporting = true);
    try {
      await ref.read(reportsProvider.notifier).downloadCsv();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV statement successfully exported and downloaded')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export statement: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(reportsProvider);
    final timeframe = ref.watch(reportsTimeframeProvider);
    final dashboardSummary = ref.watch(dashboardProvider).valueOrNull;

    final currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(reportsProvider.notifier).loadSummary(),
            ref.read(dashboardProvider.notifier).loadSummary(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header & Timeframe Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tax & Financial Reports',
                        style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Compliance statements and audit-ready analytics',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                  Row(
                    children: ['monthly', 'yearly'].map((tf) {
                      final isSelected = timeframe == tf;
                      return Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: ChoiceChip(
                          label: Text(tf == 'monthly' ? 'Monthly' : 'Yearly'),
                          selected: isSelected,
                          selectedColor: AppColors.primaryContainer,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 12,
                          ),
                          backgroundColor: AppColors.surfaceContainerLowest,
                          onSelected: (val) {
                            if (val) {
                              ref.read(reportsTimeframeProvider.notifier).state = tf;
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.spaceMd),

              // Status Header & Audit Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: AppRadii.borderFull,
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, color: AppColors.growthEmerald, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          timeframe == 'monthly' ? currentMonth : 'FY ${DateTime.now().year}-${DateTime.now().year + 1}',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const AppBadge(
                    label: 'Audit Ready',
                    variant: AppBadgeVariant.positive,
                    showDot: true,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.spaceMd),

              // Executive Flow Summary (Income / Outflow / Net)
              if (dashboardSummary != null)
                Row(
                  children: [
                    Expanded(
                      child: AppCard(
                        padding: const EdgeInsets.all(AppSpacing.spaceMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Inflow', style: AppTypography.labelMedium),
                            const SizedBox(height: 4),
                            Text(
                              InrFormatter.formatWhole(dashboardSummary.monthlyIn),
                              style: AppTypography.metricMd.copyWith(color: AppColors.growthEmerald),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spaceSm),
                    Expanded(
                      child: AppCard(
                        padding: const EdgeInsets.all(AppSpacing.spaceMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Outflow', style: AppTypography.labelMedium),
                            const SizedBox(height: 4),
                            Text(
                              InrFormatter.formatWhole(dashboardSummary.monthlyOut),
                              style: AppTypography.metricMd.copyWith(color: AppColors.debitCrimson),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spaceSm),
                    Expanded(
                      child: AppCard(
                        padding: const EdgeInsets.all(AppSpacing.spaceMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Net Preserved', style: AppTypography.labelMedium),
                            const SizedBox(height: 4),
                            Text(
                              InrFormatter.formatWhole(dashboardSummary.netSavings),
                              style: AppTypography.metricMd,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: AppSpacing.spaceMd),

              // Section 80C Tax Tracker Card
              reportsAsync.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                error: (err, _) => AppCard(child: Text('Reports error: $err')),
                data: (report) {
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
                                const Icon(Icons.account_balance, color: AppColors.obsidianNavy, size: 20),
                                const SizedBox(width: 8),
                                Text('Section 80C Tax Tracker', style: AppTypography.titleMedium),
                              ],
                            ),
                            AppBadge(
                              label: report.taxProgressPercentage >= 100 ? 'Maximized' : 'In Progress',
                              variant: report.taxProgressPercentage >= 100
                                  ? AppBadgeVariant.positive
                                  : AppBadgeVariant.warning,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Utilized: ${InrFormatter.formatWhole(report.tax80cUtilized)}',
                              style: AppTypography.metricMd.copyWith(color: AppColors.growthEmerald),
                            ),
                            Text(
                              'Cap: ${InrFormatter.formatWhole(report.tax80cLimit)}',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AppProgressBar(
                          progress: (report.taxProgressPercentage / 100).clamp(0.0, 1.0),
                          height: 8,
                          color: AppColors.growthEmerald,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${report.taxProgressPercentage.toStringAsFixed(1)}% threshold reached',
                              style: AppTypography.labelSmall,
                            ),
                            Text(
                              '${InrFormatter.formatWhole(report.taxRemainingGap)} deduction room remaining',
                              style: AppTypography.labelSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.spaceMd),

              // Visual Breakdown Chart (Income vs Outflow Velocity)
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cashflow Velocity & Savings', style: AppTypography.titleMedium),
                    const SizedBox(height: AppSpacing.spaceMd),
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          maxY: 100000,
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 56,
                                getTitlesWidget: (v, _) => Text(InrFormatter.formatCompact(v), style: const TextStyle(fontSize: 10)),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) {
                                  switch (v.toInt()) {
                                    case 0:
                                      return const Text('Income', style: TextStyle(fontSize: 11));
                                    case 1:
                                      return const Text('Outflow', style: TextStyle(fontSize: 11));
                                    case 2:
                                      return const Text('Savings', style: TextStyle(fontSize: 11));
                                    default:
                                      return const SizedBox.shrink();
                                  }
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
                                  toY: dashboardSummary?.monthlyIn ?? 85000,
                                  color: AppColors.growthEmerald,
                                  width: 28,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 1,
                              barRods: [
                                BarChartRodData(
                                  toY: dashboardSummary?.monthlyOut ?? 52300,
                                  color: AppColors.debitCrimson,
                                  width: 28,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 2,
                              barRods: [
                                BarChartRodData(
                                  toY: dashboardSummary?.netSavings ?? 32700,
                                  color: AppColors.obsidianNavy,
                                  width: 28,
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
              ),

              const SizedBox(height: AppSpacing.spaceLg),

              // CSV Export Download Action Card
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.spaceLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.file_download_outlined, color: AppColors.obsidianNavy, size: 22),
                        const SizedBox(width: 8),
                        Text('Export Ledger Statement', style: AppTypography.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Download a complete CSV audit trail containing date, description, category, amount (INR), and payment mode.',
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: _isExporting ? 'Generating Statement...' : 'Download CSV Statement',
                      icon: Icons.download,
                      variant: AppButtonVariant.primary,
                      onPressed: _isExporting ? null : _handleCsvExport,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
