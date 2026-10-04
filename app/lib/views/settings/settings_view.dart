import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/currency.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  void _showEditProfileDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => _EditProfileDialog(user: user),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to end your session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.debitCrimson),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authProvider.notifier).logout();
              if (mounted) {
                context.go('/login');
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDarkMode = ref.watch(isDarkModeProvider);
    final notifications = ref.watch(notificationsEnabledProvider);
    final biometrics = ref.watch(biometricsEnabledProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.margin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            'Account & Settings',
            style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            'Manage profile identity, targets, and security preferences',
            style: AppTypography.bodySmall,
          ),

          const SizedBox(height: AppSpacing.spaceMd),

          // Profile Hero Card
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.spaceLg),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.slate200, width: 2),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: const Icon(
                            Icons.person,
                            color: AppColors.obsidianNavy,
                            size: 36,
                          ),
                        ),
                        Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: AppColors.growthEmerald,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, size: 12, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.spaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Rohan Sharma',
                            style: AppTypography.titleLarge,
                          ),
                          Text(
                            user?.email ?? 'rohan.sharma@gmail.com',
                            style: AppTypography.bodySmall,
                          ),
                          if (user?.phone != null && user!.phone!.isNotEmpty)
                            Text(
                              user.phone!,
                              style: AppTypography.labelSmall,
                            ),
                          const SizedBox(height: 4),
                          const AppBadge(
                            label: 'KYC Verified',
                            variant: AppBadgeVariant.positive,
                            icon: Icons.verified,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.spaceMd),
                AppButton(
                  label: 'Edit Profile',
                  variant: AppButtonVariant.secondary,
                  icon: Icons.edit_outlined,
                  onPressed: user != null ? () => _showEditProfileDialog(user) : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.spaceMd),

          // Monthly Financial Targets Card
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Financial Targets (INR ₹)', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.spaceMd),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Base Currency', style: AppTypography.bodyMedium),
                    const AppBadge(
                      label: 'INR (₹) Indian Rupee',
                      variant: AppBadgeVariant.neutral,
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Monthly Income Target', style: AppTypography.bodyMedium),
                        Text('Target recurring inflow', style: AppTypography.labelSmall),
                      ],
                    ),
                    Text(
                      InrFormatter.formatWhole(user?.monthlyIncomeTarget ?? 85000),
                      style: AppTypography.metricMd.copyWith(color: AppColors.growthEmerald),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Monthly Savings Target', style: AppTypography.bodyMedium),
                        Text('Target capital preservation', style: AppTypography.labelSmall),
                      ],
                    ),
                    Text(
                      InrFormatter.formatWhole(user?.monthlySavingsTarget ?? 32000),
                      style: AppTypography.metricMd.copyWith(color: AppColors.obsidianNavy),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.spaceMd),

          // Preferences & Security
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Preferences & Security', style: AppTypography.titleMedium),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Enable dark navy appearance theme'),
                  value: isDarkMode,
                  onChanged: (val) {
                    ref.read(isDarkModeProvider.notifier).state = val;
                  },
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Budget Alerts & Notifications'),
                  subtitle: const Text('Notify when spending approaches 80% limit'),
                  value: notifications,
                  onChanged: (val) {
                    ref.read(notificationsEnabledProvider.notifier).state = val;
                  },
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.fingerprint),
                  title: const Text('Biometric Authentication'),
                  subtitle: const Text('Require fingerprint or Face Unlock on app resume'),
                  value: biometrics,
                  onChanged: (val) {
                    ref.read(biometricsEnabledProvider.notifier).state = val;
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.spaceMd),

          // Logout Action
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.spaceMd),
            child: AppButton(
              label: 'Sign Out',
              icon: Icons.logout,
              variant: AppButtonVariant.destructive,
              onPressed: _confirmLogout,
            ),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _EditProfileDialog extends ConsumerStatefulWidget {
  final UserModel user;

  const _EditProfileDialog({required this.user});

  @override
  ConsumerState<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _incomeTargetController;
  late TextEditingController _savingsTargetController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _incomeTargetController = TextEditingController(
      text: widget.user.monthlyIncomeTarget != null ? widget.user.monthlyIncomeTarget.toString() : '',
    );
    _savingsTargetController = TextEditingController(
      text: widget.user.monthlySavingsTarget != null ? widget.user.monthlySavingsTarget.toString() : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _incomeTargetController.dispose();
    _savingsTargetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final income = double.tryParse(_incomeTargetController.text.trim());
    final savings = double.tryParse(_savingsTargetController.text.trim());

    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).updateProfile(
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            monthlyIncomeTarget: income,
            monthlySavingsTarget: savings,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile & Targets'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Full name is required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _incomeTargetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monthly Income Target (₹)',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _savingsTargetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monthly Savings Target (₹)',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
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
              : const Text('Save Changes', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
