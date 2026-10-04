import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, emerald, destructive, ghost }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final Widget? trailingIcon;
  final bool isLoading;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.width,
    this.height = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = AppColors.obsidianNavy;
        foregroundColor = AppColors.onPrimary;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = AppColors.surfaceContainerLowest;
        foregroundColor = AppColors.obsidianNavy;
        borderSide = const BorderSide(color: AppColors.slate200, width: 1);
        break;
      case AppButtonVariant.emerald:
        backgroundColor = AppColors.growthEmerald;
        foregroundColor = AppColors.onSecondary;
        break;
      case AppButtonVariant.destructive:
        backgroundColor = AppColors.crimsonSubtleBg;
        foregroundColor = AppColors.debitCrimson;
        borderSide = const BorderSide(color: AppColors.crimsonBorder, width: 1);
        break;
      case AppButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = AppColors.textPrimary;
        break;
    }

    final effectiveOnPressed = isLoading ? null : onPressed;

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: effectiveOnPressed != null ? backgroundColor : backgroundColor.withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.borderMd,
          side: borderSide,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: effectiveOnPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 20, color: foregroundColor),
                          const SizedBox(width: AppSpacing.spaceSm),
                        ],
                        Text(
                          label,
                          style: AppTypography.labelLg.copyWith(
                            color: foregroundColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (trailingIcon != null) ...[
                          const SizedBox(width: AppSpacing.spaceSm),
                          trailingIcon!,
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
