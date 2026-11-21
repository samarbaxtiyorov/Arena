// ============================================
// Arena — Sync Snapshot Unit Tests
// Tests exportSnapshot and importSnapshot for full phone <-> PC sync
// ============================================

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:arena/data/local/app_database.dart';
import 'package:arena/data/remote/supabase_remote.dart';
import 'package:arena/data/sync/sync_service.dart';

void main() {
  group('Sync Snapshot Tests', () {
    late AppDatabase db;
    late SupabaseRemote remote;
    late SyncService syncService;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory(), 'test_sync_venue');
      remote = SupabaseRemote(businessId: 'test_sync_venue', accountLogin: 'test_login');
      syncService = SyncService(db, remote);
    });

    tearDown(() async {
      await db.close();
    });

    test('importSnapshot accurately restores tables, products, customers, and debts', () async {
      final snapshot = {
        'version': 1,
        'business_id': 'test_sync_venue',
        'tables': [
          {
            'id': 'table-101',
            'name': 'Maydon VIP',
            'type': 'football',
            'price_per_hour': 120000,
            'is_active': true,
            'sort_order': 1,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }
        ],
        'products': [
          {
            'id': 'prod-101',
            'name': 'Coca-Cola 1.5L',
            'price': 15000,
            'stock': 45,
            'category': 'drink',
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }
        ],
        'customers': [
          {
            'id': 'cust-101',
            'name': 'Hanishir',
            'phone': '+998 91 900 90 90',
            'total_debt': 50000,
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }
        ],
        'debts': [
          {
            'id': 'debt-101',
            'customer_id': 'cust-101',
            'amount': 50000,
            'type': 'debt',
            'description': '1 soat futbol va bar',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }
        ],
      };

      final count = await syncService.importSnapshot(snapshot);
      expect(count, 4);

      // Verify tables
      final tables = await db.clubTablesDao.select(db.clubTables).get();
      expect(tables.length, 1);
      expect(tables.first.id, 'table-101');
      expect(tables.first.name, 'Maydon VIP');
      expect(tables.first.pricePerHour, 120000);

      // Verify products
      final prods = await db.productsDao.select(db.products).get();
      expect(prods.length, 1);
      expect(prods.first.name, 'Coca-Cola 1.5L');
      expect(prods.first.stock, 45);

      // Verify customers and debts
      final customers = await db.customersDao.select(db.customers).get();
      expect(customers.length, 1);
      expect(customers.first.name, 'Hanishir');

      final debts = await db.debtsDao.select(db.debts).get();
      expect(debts.length, 1);
      expect(debts.first.amount, 50000);
      expect(debts.first.customerId, 'cust-101');

      // Now verify exportSnapshot produces identical data
      final exported = await syncService.exportSnapshot();
      expect(exported['tables'], isNotEmpty);
      expect(exported['products'], isNotEmpty);
      expect(exported['customers'], isNotEmpty);
      expect(exported['debts'], isNotEmpty);
    });
  });
}
