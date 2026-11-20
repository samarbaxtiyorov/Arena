import 'package:flutter_test/flutter_test.dart';
import 'package:arena/features/management/models/staff_member.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StaffMember Tests', () {
    test('StaffMember serialization & role properties work correctly', () {
      final staff = StaffMember(
        id: 'test-1',
        name: 'Kassir Jasur',
        phone: '+998 90 123 45 67',
        role: StaffRole.cashier,
        pin: '2468',
        isActive: true,
        createdAt: DateTime(2026, 11, 20),
      );

      expect(staff.isCashier, isTrue);
      expect(staff.isOwner, isFalse);
      expect(staff.role.badgeLabel, equals('KASSIR'));

      final json = staff.toJson();
      expect(json['pin'], equals('2468'));
      expect(json['name'], equals('Kassir Jasur'));

      final fromJson = StaffMember.fromJson(json);
      expect(fromJson.id, equals('test-1'));
      expect(fromJson.name, equals('Kassir Jasur'));
      expect(fromJson.pin, equals('2468'));
      expect(fromJson.role, equals(StaffRole.cashier));
    });

    test('StaffMember copyWith updates PIN and other fields cleanly', () {
      final owner = StaffMember(
        id: 'owner-1',
        name: 'Biznes Egasi',
        phone: '+998 90 000 00 01',
        role: StaffRole.owner,
        pin: '7777',
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = owner.copyWith(pin: '9999', name: 'Samar (Boshliq)');
      expect(updated.pin, equals('9999'));
      expect(updated.name, equals('Samar (Boshliq)'));
      expect(updated.isOwner, isTrue);
    });
  });
}
