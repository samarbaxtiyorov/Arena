import 'package:flutter_test/flutter_test.dart';
import 'package:arena/data/local/app_database.dart';
import 'package:drift/native.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Multi-Tenant Database Isolation Tests', () {
    test('Different accounts have completely isolated databases and data', () async {
      // 1. Venue A (Samar Arena) in-memory DB
      final dbA = AppDatabase(NativeDatabase.memory(), 'samar-arena');
      await dbA.seedInitialData(includeDemoSession: true);

      // 2. Venue B (Alisher Billiards) in-memory DB
      final dbB = AppDatabase(NativeDatabase.memory(), 'alisher-billiards');
      await dbB.seedInitialData(includeDemoSession: false); // Yangi hisobda demo session bo'lmaydi

      // Venue A da sessiya bor
      final sessionsA = await dbA.select(dbA.sessions).get();
      expect(sessionsA.length, equals(1));
      expect(sessionsA.first.id, equals('demo_session_1'));

      // Venue B da esa sessiya 0 ta, toza va yangi!
      final sessionsB = await dbB.select(dbB.sessions).get();
      expect(sessionsB.isEmpty, isTrue);

      // Venue B da qarzlar 0 ta
      final debtsB = await dbB.select(dbB.debts).get();
      expect(debtsB.isEmpty, isTrue);

      // Venue B da kassa arxivi 0 ta
      final cashB = await dbB.select(dbB.cashRecords).get();
      expect(cashB.isEmpty, isTrue);

      await dbA.close();
      await dbB.close();
    });
  });
}
