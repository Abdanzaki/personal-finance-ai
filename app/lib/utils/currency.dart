import 'package:intl/intl.dart';

/// INR currency and Indian numbering format (Lakh/Crore) utilities
class InrFormatter {
  InrFormatter._();

  static const String symbol = '₹';

  /// Standard Indian Rupee format with ₹ prefix and Indian grouping (lakhs & crores)
  /// e.g. 124500.00 -> ₹1,24,500.00, 10000000 -> ₹1,00,00,000.00
  static String format(num amount, {bool includeDecimals = true, bool withSymbol = true}) {
    final NumberFormat formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: withSymbol ? symbol : '',
      decimalDigits: includeDecimals ? 2 : 0,
    );
    return formatter.format(amount).trim();
  }

  /// Whole rupee format without decimal places: e.g. 85000 -> ₹85,000
  static String formatWhole(num amount, {bool withSymbol = true}) {
    return format(amount, includeDecimals: false, withSymbol: withSymbol);
  }

  /// Explicitly signed currency: e.g. 85000 -> +₹85,000, -52300 -> -₹52,300
  static String formatSigned(num amount, {bool includeDecimals = false}) {
    final absAmount = format(amount.abs(), includeDecimals: includeDecimals);
    if (amount > 0) {
      return '+$absAmount';
    } else if (amount < 0) {
      return '-$absAmount';
    }
    return absAmount;
  }

  /// Compact representation for badges & charts
  /// e.g. 52300 -> ₹52.3k, 1200000 -> ₹12 Lakh, 34000000000 -> ₹3,400 Cr
  static String formatCompact(num amount, {bool withSymbol = true}) {
    final prefix = withSymbol ? symbol : '';
    final abs = amount.abs().toDouble();
    final sign = amount < 0 ? '-' : '';

    String formatNum(double n) {
      if (n == n.roundToDouble()) {
        final whole = n.toInt();
        if (whole >= 1000) {
          return NumberFormat('#,##,###', 'en_IN').format(whole);
        }
        return whole.toString();
      }
      return n >= 100 ? n.toStringAsFixed(0) : n.toStringAsFixed(1);
    }

    if (abs >= 10000000) {
      // Crores
      final cr = abs / 10000000;
      return '$sign$prefix${formatNum(cr)} Cr';
    } else if (abs >= 100000) {
      // Lakhs
      final l = abs / 100000;
      return '$sign$prefix${formatNum(l)} Lakh';
    } else if (abs >= 1000) {
      // Thousands
      final k = abs / 1000;
      return '$sign$prefix${formatNum(k)}k';
    }
    return formatWhole(amount, withSymbol: withSymbol);
  }

  /// Safe parse string containing commas or ₹ symbol into double
  static double parse(String value) {
    final clean = value.replaceAll(symbol, '').replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }
}
