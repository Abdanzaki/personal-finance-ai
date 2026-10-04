import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Exact Inter typography scale from Stitch DESIGN.md
class AppTypography {
  AppTypography._();

  // Stitch token names
  static TextStyle get displayLg => GoogleFonts.inter(
        fontSize: 36,
        height: 44 / 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 36,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineLg => GoogleFonts.inter(
        fontSize: 30,
        height: 38 / 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 30,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineMd => GoogleFonts.inter(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.015 * 24,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineSm => GoogleFonts.inter(
        fontSize: 20,
        height: 28 / 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01 * 20,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleLg => GoogleFonts.inter(
        fontSize: 18,
        height: 26 / 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.005 * 18,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleMd => GoogleFonts.inter(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySm => GoogleFonts.inter(
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelLg => GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelMd => GoogleFonts.inter(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.02 * 12,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelSm => GoogleFonts.inter(
        fontSize: 11,
        height: 14 / 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.04 * 11,
        color: AppColors.textSecondary,
      );

  // Full name aliases for Material 3 standard naming
  static TextStyle get displayLarge => displayLg;
  static TextStyle get headlineLarge => headlineLg;
  static TextStyle get headlineMedium => headlineMd;
  static TextStyle get headlineSmall => headlineSm;
  static TextStyle get titleLarge => titleLg;
  static TextStyle get titleMedium => titleMd;
  static TextStyle get bodyLarge => bodyLg;
  static TextStyle get bodyMedium => bodyMd;
  static TextStyle get bodySmall => bodySm;
  static TextStyle get labelLarge => labelLg;
  static TextStyle get labelMedium => labelMd;
  static TextStyle get labelSmall => labelSm;

  // Financial Metrics with Tabular Numbers (tnum)
  static TextStyle get metricXl => GoogleFonts.inter(
        fontSize: 32,
        height: 38 / 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 32,
        color: AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get metricLg => GoogleFonts.inter(
        fontSize: 24,
        height: 30 / 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.01 * 24,
        color: AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get metricMd => GoogleFonts.inter(
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
