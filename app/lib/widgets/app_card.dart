import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Base elevated financial card from Stitch DESIGN.md (Elevation 1)
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.spaceMd),
    this.onTap,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceContainerLowest,
        borderRadius: AppRadii.borderLg,
        border: border ?? Border.all(color: AppColors.slate200, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0A1628),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
          BoxShadow(
            color: Color(0x050A1628),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: AppRadii.borderLg,
        child: InkWell(
          borderRadius: AppRadii.borderLg,
          onTap: onTap,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

/// Navy Master / Net Worth Card (Deep Navy #0A1628 framing)
class AppNavyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AppNavyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.obsidianNavy,
        borderRadius: AppRadii.borderLg,
        boxShadow: const [
          BoxShadow(
            color: Color(0x200A1628),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Budget Alert Card with 4px left-border accent in Amber
class AppBudgetAlertCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color accentColor;

  const AppBudgetAlertCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.spaceMd),
    this.accentColor = AppColors.amberAlert,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppRadii.borderLg,
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
          top: const BorderSide(color: AppColors.slate200, width: 1),
          right: const BorderSide(color: AppColors.slate200, width: 1),
          bottom: const BorderSide(color: AppColors.slate200, width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0A1628),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}
