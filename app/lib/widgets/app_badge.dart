import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppBadgeVariant { positive, negative, warning, navy, neutral }

class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeVariant variant;
  final IconData? icon;
  final bool showDot;

  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.neutral,
    this.icon,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (variant) {
      case AppBadgeVariant.positive:
        bg = AppColors.emerald50;
        fg = AppColors.growthEmerald;
        break;
      case AppBadgeVariant.negative:
        bg = AppColors.crimson50;
        fg = AppColors.debitCrimson;
        break;
      case AppBadgeVariant.warning:
        bg = AppColors.amber50;
        fg = AppColors.amberDark;
        break;
      case AppBadgeVariant.navy:
        bg = AppColors.primaryContainer;
        fg = AppColors.primaryFixed;
        break;
      case AppBadgeVariant.neutral:
        bg = AppColors.surfaceContainer;
        fg = AppColors.onSurfaceVariant;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.borderFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: fg,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.spaceXs),
          ],
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: AppSpacing.spaceXs),
          ],
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
