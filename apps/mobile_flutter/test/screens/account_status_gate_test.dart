import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/screens/account_status_gate.dart';

void main() {
  group('AccountStatusGate onboarding gating', () {
    test('setupCompletedAt in profile skips onboarding', () {
      final shouldSkip = AccountStatusGate.shouldSkipOnboarding(
        setupCompletedAt: DateTime(2026, 2, 20, 9, 0),
        localSetupCompleted: false,
      );

      expect(shouldSkip, isTrue);
    });

    test('local setupCompleted fallback skips onboarding', () {
      final shouldSkip = AccountStatusGate.shouldSkipOnboarding(
        setupCompletedAt: null,
        localSetupCompleted: true,
      );

      expect(shouldSkip, isTrue);
    });

    test('without profile/local completion onboarding is shown', () {
      final shouldSkip = AccountStatusGate.shouldSkipOnboarding(
        setupCompletedAt: null,
        localSetupCompleted: false,
      );

      expect(shouldSkip, isFalse);
    });
  });
}
