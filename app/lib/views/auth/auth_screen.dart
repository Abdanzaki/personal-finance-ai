import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final bool initialIsSignUp;

  const AuthScreen({super.key, this.initialIsSignUp = false});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late bool _isSignUp;

  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  // Sign In Controllers
  final _signInEmailController = TextEditingController(text: 'rohan.sharma@gmail.com');
  final _signInPasswordController = TextEditingController(text: 'Password123!');

  // Sign Up Controllers
  final _signUpNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
  }

  @override
  void dispose() {
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpPhoneController.dispose();
    super.dispose();
  }

  void _submitSignIn() async {
    if (_signInFormKey.currentState?.validate() ?? false) {
      final success = await ref.read(authProvider.notifier).login(
            _signInEmailController.text.trim(),
            _signInPasswordController.text,
          );
      if (success && mounted) {
        context.go('/dashboard');
      }
    }
  }

  void _submitSignUp() async {
    if (_signUpFormKey.currentState?.validate() ?? false) {
      final success = await ref.read(authProvider.notifier).signup(
            email: _signUpEmailController.text.trim(),
            password: _signUpPasswordController.text,
            fullName: _signUpNameController.text.trim(),
            phone: _signUpPhoneController.text.trim(),
          );
      if (success && mounted) {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Brand Authority Header (Navy Framing)
            _buildBrandHeader(),

            // Main Interaction Card Container
            Transform.translate(
              offset: const Offset(0, -16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: AppRadii.borderLg,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x140A1628),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(AppSpacing.spaceLg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Tab Switch Toggle
                          _buildTabSwitch(),

                          const SizedBox(height: AppSpacing.spaceLg),

                          // Error notification banner if any
                          if (authState.errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.spaceSm),
                              decoration: BoxDecoration(
                                color: AppColors.crimson50,
                                borderRadius: AppRadii.borderDefault,
                                border: Border.all(color: AppColors.crimsonBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppColors.debitCrimson,
                                    size: 18,
                                  ),
                                  const SizedBox(width: AppSpacing.spaceSm),
                                  Expanded(
                                    child: Text(
                                      authState.errorMessage!,
                                      style: AppTypography.bodySm.copyWith(
                                        color: AppColors.debitCrimson,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.spaceMd),
                          ],

                          // Form
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 250),
                            crossFadeState: _isSignUp
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            firstChild: _buildSignInForm(authState.isLoading),
                            secondChild: _buildSignUpForm(authState.isLoading),
                          ),

                          const SizedBox(height: AppSpacing.spaceLg),

                          // Editorial Divider
                          _buildSocialDivider(),

                          const SizedBox(height: AppSpacing.spaceMd),

                          // Federated Social Sign-in Array
                          _buildSocialButtons(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spaceXl),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.primaryContainer,
      padding: const EdgeInsets.only(
        top: 60,
        bottom: 48,
        left: AppSpacing.margin,
        right: AppSpacing.margin,
      ),
      child: Column(
        children: [
          // Brand Emblem Container
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: AppRadii.borderMd,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x20000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppSpacing.spaceSm),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.account_balance_wallet,
                color: AppColors.obsidianNavy,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.spaceSm),

          // Typography Branding
          Text(
            'Personal Finance AI',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceXs),
          Text(
            'SMART MONEY MANAGEMENT FOR INDIA',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.onPrimaryContainer,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceSm),

          // Micro Metric Pulse
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest.withValues(alpha: 0.1),
              borderRadius: AppRadii.borderFull,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryFixed,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.spaceSm),
                Text(
                  '₹3,400+ Cr Intelligent Portfolios Monitored',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.borderDefault,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isSignUp) setState(() => _isSignUp = false);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isSignUp ? AppColors.surfaceContainerLowest : Colors.transparent,
                  borderRadius: AppRadii.borderDefault,
                  boxShadow: !_isSignUp
                      ? const [
                          BoxShadow(
                            color: Color(0x10000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Sign In',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleMedium.copyWith(
                    color: !_isSignUp ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_isSignUp) setState(() => _isSignUp = true);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isSignUp ? AppColors.surfaceContainerLowest : Colors.transparent,
                  borderRadius: AppRadii.borderDefault,
                  boxShadow: _isSignUp
                      ? const [
                          BoxShadow(
                            color: Color(0x10000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleMedium.copyWith(
                    color: _isSignUp ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInForm(bool isLoading) {
    return Form(
      key: _signInFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email
          AppTextField(
            label: 'Email Address',
            hintText: 'name@domain.com',
            controller: _signInEmailController,
            prefixIcon: Icons.alternate_email,
            keyboardType: TextInputType.emailAddress,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Email is required';
              if (!val.contains('@') || !val.contains('.')) return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.spaceMd),

          // Password with Forgot Password link
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Password',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/forgot-password'),
                    child: Text(
                      'Forgot Password?',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spaceXs),
              AppTextField(
                hintText: '••••••••••••',
                controller: _signInPasswordController,
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Password is required';
                  if (val.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceLg),

          // Emerald Conversion Action
          AppButton(
            label: 'Sign In to Account',
            variant: AppButtonVariant.emerald,
            trailingIcon: const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
            isLoading: isLoading,
            onPressed: _submitSignIn,
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpForm(bool isLoading) {
    return Form(
      key: _signUpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Full Name
          AppTextField(
            label: 'Full Legal Name',
            hintText: 'As per PAN card',
            controller: _signUpNameController,
            prefixIcon: Icons.badge_outlined,
            textInputAction: TextInputAction.next,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Full legal name is required';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.spaceMd),

          // Email
          AppTextField(
            label: 'Email Address',
            hintText: 'name@domain.com',
            controller: _signUpEmailController,
            prefixIcon: Icons.alternate_email,
            keyboardType: TextInputType.emailAddress,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Email is required';
              if (!val.contains('@') || !val.contains('.')) return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.spaceMd),

          // Password
          AppTextField(
            label: 'Password',
            hintText: '••••••••••••',
            controller: _signUpPasswordController,
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            validator: (val) {
              if (val == null || val.isEmpty) return 'Password is required';
              if (val.length < 8) return 'Password must be at least 8 characters';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.spaceMd),

          // Phone
          AppTextField(
            label: 'Mobile Number (for instant OTP verification)',
            hintText: '98765 43210',
            controller: _signUpPhoneController,
            keyboardType: TextInputType.phone,
            prefix: Padding(
              padding: const EdgeInsets.only(left: 14, right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+91',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('|', style: TextStyle(color: AppColors.outlineVariant)),
                ],
              ),
            ),
            validator: (val) {
              if (val != null && val.isNotEmpty && val.replaceAll(RegExp(r'\s+'), '').length < 10) {
                return 'Enter a valid 10-digit mobile number';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.spaceLg),

          // Emerald Conversion Action
          AppButton(
            label: 'Create Free Account',
            variant: AppButtonVariant.emerald,
            trailingIcon: const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
            isLoading: isLoading,
            onPressed: _submitSignUp,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.slate200)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd),
          child: Text(
            'OR CONTINUE WITH',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.outline,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.slate200)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildSocialCard(
            label: 'Google',
            icon: Icons.g_mobiledata,
          ),
        ),
        const SizedBox(width: AppSpacing.spaceSm),
        Expanded(
          child: _buildSocialCard(
            label: 'Apple',
            icon: Icons.apple,
          ),
        ),
        const SizedBox(width: AppSpacing.spaceSm),
        Expanded(
          child: _buildSocialCard(
            label: 'NetBanking',
            icon: Icons.account_balance,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialCard({required String label, required IconData icon}) {
    return Material(
      color: AppColors.surfaceContainerLow,
      borderRadius: AppRadii.borderDefault,
      child: InkWell(
        borderRadius: AppRadii.borderDefault,
        onTap: () {
          // Placeholder federated login feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label sign-in is coming soon! Use email for instant demo access.'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: AppColors.textPrimary),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
