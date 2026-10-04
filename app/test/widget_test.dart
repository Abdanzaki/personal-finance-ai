import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_ai/main.dart';
import 'package:personal_finance_ai/providers/auth_provider.dart';
import 'package:personal_finance_ai/services/auth_service.dart';
import 'package:personal_finance_ai/utils/currency.dart';

class MockAuthService extends AuthService {
  @override
  Future<bool> isAuthenticated() async => false;

  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<UserModel?> getCurrentUser() async => null;
}

void main() {
  test('InrFormatter correctly formats Indian numbering system', () {
    expect(InrFormatter.formatWhole(1000), '₹1,00,000' == '₹1,00,000' ? '₹1,000' : '');
    expect(InrFormatter.formatWhole(85000), '₹85,000');
    expect(InrFormatter.formatWhole(124500), '₹1,24,500');
    expect(InrFormatter.formatWhole(10000000), '₹1,00,00,000');

    expect(InrFormatter.formatSigned(85000), '+₹85,000');
    expect(InrFormatter.formatSigned(-52300), '-₹52,300');

    expect(InrFormatter.formatCompact(52300), '₹52.3k');
    expect(InrFormatter.formatCompact(1200000), '₹12 Lakh');
    expect(InrFormatter.formatCompact(34000000000), '₹3,400 Cr');

    expect(InrFormatter.parse('₹1,24,500.00'), 124500.00);
  });

  testWidgets('App loads initial auth screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(MockAuthService()),
        ],
        child: const PersonalFinanceApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify presence of brand title on Login/Sign-up screen
    expect(find.text('Personal Finance AI'), findsWidgets);
    expect(find.text('Sign In'), findsWidgets);
    expect(find.text('Create Account'), findsWidgets);
  });
}
