import 'package:flutter_test/flutter_test.dart';
import 'package:arena/core/auth/providers/business_account_provider.dart';
import 'package:arena/features/management/models/staff_member.dart';

void main() {
  group('Phone matching and Normalization Tests', () {
    test('matchPhone correctly matches formatted and unformatted phones', () {
      // To'qqizta nol testlari
      expect(
        BusinessAccountNotifier.matchPhone('+998 00 000 00 00', '000000000'),
        isTrue,
      );
      expect(
        BusinessAccountNotifier.matchPhone('+998 000000000', '000000000'),
        isTrue,
      );
      expect(
        BusinessAccountNotifier.matchPhone('+998 90 000 00 01', '900000001'),
        isTrue,
      );
      expect(
        BusinessAccountNotifier.matchPhone('+998 (90) 000-00-01', '+998900000001'),
        isTrue,
      );
    });
  });

  group('StaffMember Cashier & PIN Tests', () {
    test('Cashier hasCustomPin works accurately', () {
      final newCashier = StaffMember(
        id: 'c1',
        name: 'Jasur',
        login: 'jasur_kassir',
        password: '123',
        phone: '+998901234567',
        role: StaffRole.cashier,
        pin: '',
        createdAt: DateTime.now(),
      );

      expect(newCashier.isCashier, isTrue);
      expect(newCashier.hasCustomPin, isFalse);

      final withPin = newCashier.copyWith(pin: '2580');
      expect(withPin.hasCustomPin, isTrue);
      expect(withPin.pin, equals('2580'));
    });
  });
}
