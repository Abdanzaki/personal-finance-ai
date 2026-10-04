import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_ai/models/dashboard.dart';
import 'package:personal_finance_ai/utils/json.dart';

void main() {
  group('parseDouble', () {
    test('parses numeric strings from the backend', () {
      expect(parseDouble('0.0'), 0.0);
      expect(parseDouble('1234.56'), 1234.56);
    });

    test('parses real JSON numbers', () {
      expect(parseDouble(42), 42.0);
      expect(parseDouble(3.14), 3.14);
    });

    test('falls back on null or garbage', () {
      expect(parseDouble(null), 0.0);
      expect(parseDouble('n/a', 7.5), 7.5);
    });
  });

  group('DashboardSummaryModel.fromJson', () {
    test('handles string decimals like the live backend sends', () {
      final model = DashboardSummaryModel.fromJson({
        'total_balance': '0.0',
        'primary_account': 'HDFC Bank •• 4912',
        'monthly_in': '0.0',
        'monthly_out': '0.0',
        'net_savings': '0.0',
        'savings_rate_pct': 0.0,
        'recent_transactions': [],
      });
      expect(model.totalBalance, 0.0);
      expect(model.primaryAccount, 'HDFC Bank •• 4912');
      expect(model.monthlyIn, 0.0);
    });

    test('handles real numbers too', () {
      final model = DashboardSummaryModel.fromJson({
        'total_balance': 1500.25,
        'monthly_in': 50000,
        'monthly_out': '12000.5',
        'net_savings': 37999.5,
        'savings_rate_pct': '75.9',
        'recent_transactions': [
          {
            'id': '1',
            'title': 'Salary',
            'amount': '50000.0',
            'type': 'income',
            'category': 'Salary',
            'date': '2026-10-04T10:00:00',
          },
        ],
      });
      expect(model.totalBalance, 1500.25);
      expect(model.monthlyOut, 12000.5);
      expect(model.savingsRatePct, 75.9);
      expect(model.recentTransactions.single.amount, 50000.0);
    });
  });
}
