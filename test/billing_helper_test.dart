import 'package:flutter_test/flutter_test.dart';
import 'package:arena/core/utils/session_billing_helper.dart';

void main() {
  group('SessionBillingHelper Tests', () {
    test('calculateGameAmount handles small and large durations accurately', () {
      final now = DateTime.now();
      
      // 5 seconds -> minimum 1000 so'm
      final amountShort = SessionBillingHelper.calculateGameAmount(
        startedAt: now.subtract(const Duration(seconds: 5)),
        endedAt: now,
        pricePerHour: 60000,
      );
      expect(amountShort, 1000);

      // 30 minutes at 60,000/hr -> 30,000 so'm
      final amountHalfHour = SessionBillingHelper.calculateGameAmount(
        startedAt: now.subtract(const Duration(minutes: 30)),
        endedAt: now,
        pricePerHour: 60000,
      );
      expect(amountHalfHour, 30000);

      // 1 hour at 100,000/hr -> 100,000 so'm
      final amountOneHour = SessionBillingHelper.calculateGameAmount(
        startedAt: now.subtract(const Duration(hours: 1)),
        endedAt: now,
        pricePerHour: 100000,
      );
      expect(amountOneHour, 100000);
    });

    test('getBarTotal parses BAR_SUM and legacy formats', () {
      expect(SessionBillingHelper.getBarTotal(null), 0);
      expect(SessionBillingHelper.getBarTotal(''), 0);
      expect(SessionBillingHelper.getBarTotal('Just random note'), 0);

      // BAR_SUM format
      expect(
        SessionBillingHelper.getBarTotal('BAR_SUM:18000 | Bar: Cola x1 (10 000 so\'m), Choy x1 (8 000 so\'m)'),
        18000,
      );

      // Legacy format
      expect(
        SessionBillingHelper.getBarTotal('Bar: Cola x1 (10 000 so\'m), Fanta x2 (20 000 so\'m)'),
        30000,
      );
    });

    test('composeNotesWithBar and finalizeNotes preserves bar orders and notes', () {
      // 1. Initial bar add
      final note1 = SessionBillingHelper.composeNotesWithBar(
        currentNotes: null,
        newItemsSummary: ['Cola x1 (10 000 so\'m)', 'Choy x1 (8 000 so\'m)'],
        addedBarSum: 18000,
      );
      expect(SessionBillingHelper.getBarTotal(note1), 18000);
      expect(SessionBillingHelper.getBarItemsSummary(note1).length, 2);

      // 2. Second bar add
      final note2 = SessionBillingHelper.composeNotesWithBar(
        currentNotes: note1,
        newItemsSummary: ['Suv x1 (5 000 so\'m)'],
        addedBarSum: 5000,
      );
      expect(SessionBillingHelper.getBarTotal(note2), 23000);
      expect(SessionBillingHelper.getBarItemsSummary(note2).length, 3);

      // 3. Finalize notes with extra user notes
      final finalNotes = SessionBillingHelper.finalizeNotes(
        originalNotes: note2,
        extraUserNote: 'Doimiy mijoz, VIP xizmat',
      );
      expect(SessionBillingHelper.getBarTotal(finalNotes), 23000);
      expect(finalNotes.contains('Doimiy mijoz, VIP xizmat'), isTrue);
      expect(finalNotes.contains('Cola x1'), isTrue);
    });
  });
}
