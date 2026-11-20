import 'package:flutter_test/flutter_test.dart';
import 'package:arena/features/management/models/subscription_model.dart';
import 'package:arena/features/management/providers/subscription_provider.dart';

void main() {
  group('Subscription Calculation & Model Tests', () {
    test('Formula: 1 table = 100 000 som/month, 5 tables = 500 000 som/month', () {
      // 1 ta stol, 1 oy
      final cost1 = SubscriptionNotifier.calculateAmount(tablesCount: 1, months: 1);
      expect(cost1, 100000);

      // 5 ta bilyard stoli, 1 oy = 500 000 so'm
      final cost5 = SubscriptionNotifier.calculateAmount(tablesCount: 5, months: 1);
      expect(cost5, 500000);

      // 4 ta stol, 1 oy = 400 000 so'm
      final cost4 = SubscriptionNotifier.calculateAmount(tablesCount: 4, months: 1);
      expect(cost4, 400000);
    });

    test('Discounts work accurately (5% for 3m, 10% for 6m, 20% for 12m)', () {
      // 5 ta stol:
      // 3 oy (5% chegirma): 5 * 100 000 * 3 * 0.95 = 1 425 000 so'm
      final cost3m = SubscriptionNotifier.calculateAmount(tablesCount: 5, months: 3);
      expect(cost3m, 1425000);

      // 6 oy (10% chegirma): 5 * 100 000 * 6 * 0.90 = 2 700 000 so'm
      final cost6m = SubscriptionNotifier.calculateAmount(tablesCount: 5, months: 6);
      expect(cost6m, 2700000);

      // 12 oy (20% chegirma): 5 * 100 000 * 12 * 0.80 = 4 800 000 so'm (1 200 000 so'm tejash)
      final cost12m = SubscriptionNotifier.calculateAmount(tablesCount: 5, months: 12);
      expect(cost12m, 4800000);
    });

    test('SubscriptionModel trial and expiry logic', () {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 3));
      final trialSub = SubscriptionModel(
        venueId: 'trial-venue',
        expiryDate: futureDate,
        isTrial: true,
        licensedTablesCount: 10,
      );

      expect(trialSub.isTrial, isTrue);
      expect(trialSub.isTrialActive, isTrue);
      expect(trialSub.isExpired, isFalse);
      expect(trialSub.statusBadge, 'SINOV DAVRI');

      // Muddati o'tgan holat
      final pastDate = now.subtract(const Duration(days: 1));
      final expiredSub = trialSub.copyWith(expiryDate: pastDate);
      expect(expiredSub.isExpired, isTrue);
      expect(expiredSub.isTrialActive, isFalse);
      expect(expiredSub.statusBadge, "MUDDATI O'TGAN");

      // Serialization
      final jsonStr = trialSub.toJson();
      final restored = SubscriptionModel.fromJson(jsonStr);
      expect(restored.isTrial, isTrue);
      expect(restored.licensedTablesCount, 10);
    });
  });
}
