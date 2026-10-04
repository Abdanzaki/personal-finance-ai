import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../providers/transactions_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/currency.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

const List<String> kCategories = [
  'All',
  'Food & Dining',
  'Housing & Rent',
  'Groceries',
  'Transport',
  'Shopping',
  'Utilities',
  'Entertainment',
  'Healthcare',
  'Salary',
  'Investment',
  'General',
];

const List<String> kPaymentMethods = [
  'UPI',
  'Debit Card',
  'Credit Card',
  'Net Banking',
  'Cash',
];

class TransactionsView extends ConsumerStatefulWidget {
  const TransactionsView({super.key});

  @override
  ConsumerState<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends ConsumerState<TransactionsView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showTransactionDialog({TransactionModel? existing}) {
    showDialog(
      context: context,
      builder: (context) => _TransactionFormDialog(existing: existing),
    );
  }

  void _confirmDelete(TransactionModel tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Are you sure you want to delete "${tx.description}" (${InrFormatter.format(tx.amount)})? This cannot be undone.'),
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
                await ref.read(transactionsProvider.notifier).deleteTransaction(tx.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaction deleted successfully')),
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
    final transactionsAsync = ref.watch(transactionsProvider);
    final filter = ref.watch(transactionFilterProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.growthEmerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
        onPressed: () => _showTransactionDialog(),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(transactionsProvider.notifier).loadTransactions(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header & Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transactions Ledger',
                        style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'General cashbook and verified transactions',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => ref.read(transactionsProvider.notifier).loadTransactions(),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.spaceMd),

              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search description, category, or payment method...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(transactionFilterProvider.notifier).state =
                                filter.copyWith(search: '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: AppRadii.borderDefault,
                    borderSide: const BorderSide(color: AppColors.slate200),
                  ),
                ),
                onSubmitted: (val) {
                  ref.read(transactionFilterProvider.notifier).state = filter.copyWith(search: val);
                },
              ),

              const SizedBox(height: AppSpacing.spaceSm),

              // Filter Chips: Type (All, Expense, Income) & Sort dropdown
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Expense', 'Income'].map((t) {
                          final isSelected = filter.type.toLowerCase() == t.toLowerCase();
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: ChoiceChip(
                              label: Text(t),
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
                                  ref.read(transactionFilterProvider.notifier).state =
                                      filter.copyWith(type: t);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: filter.sort,
                    underline: const SizedBox.shrink(),
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary),
                    items: const [
                      DropdownMenuItem(value: 'date_desc', child: Text('Date: Newest')),
                      DropdownMenuItem(value: 'date_asc', child: Text('Date: Oldest')),
                      DropdownMenuItem(value: 'amount_desc', child: Text('Amount: High-Low')),
                      DropdownMenuItem(value: 'amount_asc', child: Text('Amount: Low-High')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(transactionFilterProvider.notifier).state =
                            filter.copyWith(sort: val);
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.spaceMd),

              // Transaction List Content
              transactionsAsync.when(
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
                        Text('Failed to load transactions: $err', style: AppTypography.bodyMedium),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => ref.read(transactionsProvider.notifier).loadTransactions(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (response) {
                  final items = response.items;
                  if (items.isEmpty) {
                    return AppCard(
                      padding: const EdgeInsets.all(AppSpacing.spaceLg),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textSecondary),
                            const SizedBox(height: 12),
                            Text('No transactions found', style: AppTypography.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              filter.search.isNotEmpty
                                  ? 'No records matching "${filter.search}"'
                                  : 'Record your first income or expense transaction.',
                              style: AppTypography.bodySmall,
                            ),
                            const SizedBox(height: 16),
                            AppButton(
                              label: 'Add Transaction',
                              variant: AppButtonVariant.primary,
                              onPressed: () => _showTransactionDialog(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: items.map((tx) {
                      final isExpense = tx.isExpense;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          padding: const EdgeInsets.all(AppSpacing.spaceMd),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isExpense ? AppColors.crimson50 : AppColors.emerald50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                                  color: isExpense ? AppColors.debitCrimson : AppColors.growthEmerald,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(tx.description, style: AppTypography.titleMedium),
                                    Text(
                                      '${tx.category} • ${tx.paymentMethod} • ${DateFormat('dd MMM yyyy, hh:mm a').format(tx.date)}',
                                      style: AppTypography.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    isExpense
                                        ? InrFormatter.formatSigned(-tx.amount)
                                        : InrFormatter.formatSigned(tx.amount),
                                    style: AppTypography.metricMd.copyWith(
                                      color: isExpense ? AppColors.debitCrimson : AppColors.growthEmerald,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 18),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Edit',
                                        onPressed: () => _showTransactionDialog(existing: tx),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.debitCrimson),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Delete',
                                        onPressed: () => _confirmDelete(tx),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionFormDialog extends ConsumerStatefulWidget {
  final TransactionModel? existing;

  const _TransactionFormDialog({this.existing});

  @override
  ConsumerState<_TransactionFormDialog> createState() => _TransactionFormDialogState();
}

class _TransactionFormDialogState extends ConsumerState<_TransactionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _type;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late String _category;
  late String _paymentMethod;
  late DateTime _date;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _type = ex?.type ?? 'expense';
    _amountController = TextEditingController(text: ex != null ? ex.amount.toString() : '');
    _descriptionController = TextEditingController(text: ex?.description ?? '');
    _category = ex?.category ?? 'Food & Dining';
    _paymentMethod = ex?.paymentMethod ?? 'UPI';
    _date = ex?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be greater than zero')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (widget.existing != null) {
        await ref.read(transactionsProvider.notifier).updateTransaction(
              widget.existing!.id,
              type: _type,
              amount: amount,
              description: _descriptionController.text.trim(),
              category: _category,
              paymentMethod: _paymentMethod,
              date: _date,
            );
      } else {
        await ref.read(transactionsProvider.notifier).createTransaction(
              type: _type,
              amount: amount,
              description: _descriptionController.text.trim(),
              category: _category,
              paymentMethod: _paymentMethod,
              date: _date,
            );
      }
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existing != null ? 'Transaction updated' : 'Transaction created'),
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
      title: Text(widget.existing != null ? 'Edit Transaction' : 'Record Transaction'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type Segment (Expense vs Income)
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Expense'), icon: Icon(Icons.arrow_downward)),
                  ButtonSegment(value: 'income', label: Text('Income'), icon: Icon(Icons.arrow_upward)),
                ],
                selected: {_type},
                onSelectionChanged: (set) {
                  setState(() => _type = set.first);
                },
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (₹) *',
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

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Description is required';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Category
              DropdownButtonFormField<String>(
                initialValue: kCategories.contains(_category) && _category != 'All' ? _category : 'Food & Dining',
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                ),
                items: kCategories
                    .where((c) => c != 'All')
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const SizedBox(height: 12),

              // Payment Method
              DropdownButtonFormField<String>(
                initialValue: kPaymentMethods.contains(_paymentMethod) ? _paymentMethod : 'UPI',
                decoration: const InputDecoration(
                  labelText: 'Payment Method *',
                  border: OutlineInputBorder(),
                ),
                items: kPaymentMethods
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _paymentMethod = val);
                },
              ),
              const SizedBox(height: 12),

              // Date Picker Tile
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text('Date: ${DateFormat('dd MMM yyyy').format(_date)}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _date = picked);
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
              : Text(widget.existing != null ? 'Update' : 'Save', style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
