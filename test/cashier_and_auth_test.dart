import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arena/core/auth/providers/business_account_provider.dart';
import 'package:arena/features/management/models/staff_member.dart';
import 'package:arena/features/management/providers/staff_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

    test('StaffListNotifier.findCashierByCredentials dynamically finds cashier across accounts', () async {
      SharedPreferences.setMockInitialValues({
        'arena_staff_members_venue_999': jsonEncode([
          {
            'id': 'c-venue-999',
            'accountId': 'venue_999',
            'name': 'Ali Kassir',
            'login': 'ali_arena',
            'password': 'password123',
            'phone': '+998901112233',
            'role': 'cashier',
            'pin': '7788',
            'isActive': true,
            'createdAt': DateTime.now().toIso8601String(),
          }
        ]),
      });

      final found = await StaffListNotifier.findCashierByCredentials(
        login: 'ali_arena',
        password: 'password123',
      );

      expect(found, isNotNull);
      expect(found!.name, equals('Ali Kassir'));
      expect(found.accountId, equals('venue_999'));
      expect(found.pin, equals('7788'));
      expect(found.hasCustomPin, isTrue);

      final notFound = await StaffListNotifier.findCashierByCredentials(
        login: 'ali_arena',
        password: 'wrong_password',
      );
      expect(notFound, isNull);
    });
  });
}
