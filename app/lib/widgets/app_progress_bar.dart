import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Color? color;
  final Color? backgroundColor;
  final bool autoThresholdColor;

  const AppProgressBar({
    super.key,
    required this.progress,
    this.height = 8.0,
    this.color,
    this.backgroundColor,
    this.autoThresholdColor = false,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    Color indicatorColor = color ?? AppColors.growthEmerald;
    if (autoThresholdColor) {
      if (clamped >= 1.0) {
        indicatorColor = AppColors.debitCrimson;
      } else if (clamped >= 0.8) {
        indicatorColor = AppColors.amberAlert;
      } else {
        indicatorColor = AppColors.growthEmerald;
      }
    }

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceContainerHighest,
        borderRadius: AppRadii.borderFull,
      ),
      clipBehavior: Clip.antiAlias,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: clamped,
        child: Container(
          decoration: BoxDecoration(
            color: indicatorColor,
            borderRadius: AppRadii.borderFull,
          ),
        ),
      ),
    );
  }
}
