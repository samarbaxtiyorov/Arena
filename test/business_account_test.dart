import 'package:flutter_test/flutter_test.dart';
import 'package:arena/core/auth/models/business_account.dart';
import 'package:arena/core/auth/providers/business_account_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BusinessAccount Tests', () {
    test('BusinessAccount serialization & fields are accurate', () {
      final account = BusinessAccount(
        id: 'acc-1',
        venueName: 'Arena Jeyda Sport Majmuasi',
        ownerName: 'Samar Baxtiyorov',
        phone: '+998 90 123 45 67',
        password: 'password123',
        ownerPin: '7777',
        licenseType: 'PREMIUM VIP',
        createdAt: DateTime(2026, 11, 20),
      );

      final json = account.toJson();
      expect(json['venueName'], equals('Arena Jeyda Sport Majmuasi'));
      expect(json['ownerName'], equals('Samar Baxtiyorov'));
      expect(json['phone'], equals('+998 90 123 45 67'));
      expect(json['ownerPin'], equals('7777'));

      final fromJson = BusinessAccount.fromJson(json);
      expect(fromJson.id, equals('acc-1'));
      expect(fromJson.venueName, equals('Arena Jeyda Sport Majmuasi'));
      expect(fromJson.password, equals('password123'));
    });

    test('BusinessAccount copyWith updates venue info correctly', () {
      final account = BusinessAccount(
        id: 'acc-2',
        venueName: 'Eski Poliya',
        ownerName: 'Ali',
        phone: '+998 91 111 22 33',
        password: '123',
        ownerPin: '1234',
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = account.copyWith(
        venueName: 'Chempion Arena',
        ownerName: 'Alisher Baxtiyorov',
      );

      expect(updated.venueName, equals('Chempion Arena'));
      expect(updated.ownerName, equals('Alisher Baxtiyorov'));
      expect(updated.phone, equals('+998 91 111 22 33'));
    });

    test('Login validation strictly enforces: >= 6 chars, no spaces, no dots/commas', () {
      // Xato holatlar
      expect(BusinessAccountNotifier.validateLogin(''), isNotNull);
      expect(BusinessAccountNotifier.validateLogin('jas'), isNotNull); // < 6
      expect(BusinessAccountNotifier.validateLogin('jas mina'), isNotNull); // bo'sh joy
      expect(BusinessAccountNotifier.validateLogin('jasmina.01'), isNotNull); // nuqta
      expect(BusinessAccountNotifier.validateLogin('jasmina,01'), isNotNull); // vergul
      expect(BusinessAccountNotifier.validateLogin('jasmina!@#'), isNotNull); // maxsus belgi

      // To'g'ri holatlar
      expect(BusinessAccountNotifier.validateLogin('jasmina'), isNull);
      expect(BusinessAccountNotifier.validateLogin('arena01'), isNull);
      expect(BusinessAccountNotifier.validateLogin('boss_2026'), isNull);
      expect(BusinessAccountNotifier.validateLogin('samar_baxtiyorov'), isNull);
    });

    test('Password validation strictly enforces: >= 8 chars', () {
      expect(BusinessAccountNotifier.validatePassword(''), isNotNull);
      expect(BusinessAccountNotifier.validatePassword('1234567'), isNotNull); // 7 ta belgi
      expect(BusinessAccountNotifier.validatePassword('pass123'), isNotNull); // 7 ta belgi

      expect(BusinessAccountNotifier.validatePassword('12345678'), isNull); // 8 ta belgi
      expect(BusinessAccountNotifier.validatePassword('arena_secure_2026'), isNull);
    });
  });
}
