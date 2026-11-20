import 'package:flutter_test/flutter_test.dart';
import 'package:arena/data/local/app_database.dart';
import 'package:arena/data/remote/supabase_remote.dart';
import 'package:arena/data/sync/sync_service.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';

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

    test('SupabaseRemote strictly scopes to specific businessId', () {
      final remoteDefault = SupabaseRemote();
      expect(remoteDefault.businessId, equals('biz_arena_sport'));

      final remoteJasmina = SupabaseRemote(businessId: 'venue_jasmina_123');
      expect(remoteJasmina.businessId, equals('venue_jasmina_123'));
    });

    test('SyncService cleans foreign leaked debts for new venue account', () async {
      final db = AppDatabase(NativeDatabase.memory(), 'venue_jasmina_123');
      final remote = SupabaseRemote(businessId: 'venue_jasmina_123');
      final sync = SyncService(db, remote);

      // Sun'iy ravishda begona mijoz va qarz kiritamiz (leaked foreign debt)
      await db.customersDao.insertCustomer(CustomersCompanion.insert(
        id: 'customer-3f049772-6e85-4949-962d-013f837a410f',
        name: 'RUSLAN',
        totalDebt: const Value(6040000),
      ));
      await db.debtsDao.insertDebt(DebtsCompanion.insert(
        id: 'leaked_debt_1',
        customerId: 'customer-3f049772-6e85-4949-962d-013f837a410f',
        amount: 6040000,
        type: 'debt',
      ));

      // Shuningdek yangi klubning o'zining qonuniy mijozi va qarzi
      await db.customersDao.insertCustomer(CustomersCompanion.insert(
        id: 'my_own_customer_1',
        name: 'Jasmina Mijoz',
        totalDebt: const Value(50000),
      ));
      await db.debtsDao.insertDebt(DebtsCompanion.insert(
        id: 'my_own_debt_1',
        customerId: 'my_own_customer_1',
        amount: 50000,
        type: 'debt',
      ));

      // Tozalash metodini tekshiramiz
      await sync.cleanForeignDataIfNeeded();

      final customers = await db.select(db.customers).get();
      final debts = await db.select(db.debts).get();

      // RUSLAN begona mijozi va qarzi butunlay o'chirilgan bo'lishi shart!
      expect(customers.any((c) => c.name == 'RUSLAN'), isFalse);
      expect(debts.any((d) => d.id == 'leaked_debt_1'), isFalse);

      // Jasmina Mijoz va uning qarzi esa saqlanib qolgan bo'lishi shart!
      expect(customers.any((c) => c.id == 'my_own_customer_1'), isTrue);
      expect(debts.any((d) => d.id == 'my_own_debt_1'), isTrue);

      await db.close();
    });
  });
}
