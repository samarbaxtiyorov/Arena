// ============================================
// Arena — AppDatabase (Drift)
// Barcha jadvallar va DAO lar shu yerda
// ============================================

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Jadvallar
import 'tables/club_tables_table.dart';
import 'tables/sessions_table.dart';
import 'tables/customers_table.dart';
import 'tables/debts_table.dart';
import 'tables/products_table.dart';
import 'tables/cash_records_table.dart';

// DAOlar
import 'daos/club_tables_dao.dart';
import 'daos/sessions_dao.dart';
import 'daos/customers_dao.dart';
import 'daos/debts_dao.dart';
import 'daos/products_dao.dart';
import 'daos/cash_records_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    ClubTables,
    Sessions,
    Customers,
    Debts,
    Products,
    CashRecords,
  ],
  daos: [
    ClubTablesDao,
    SessionsDao,
    CustomersDao,
    DebtsDao,
    ProductsDao,
    CashRecordsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await seedInitialData();
    },
    onUpgrade: (m, from, to) async {
      // Keyingi versiyalar uchun
    },
  );

  // Boshlang'ich ma'lumotlar (Skrinshotlar bilan 1:1)
  Future<void> seedInitialData() async {
    final now = DateTime.now();

    // 1. Maydonlar va Stollar (Skrinshot 6: Maydon 1, 100 000 so'm/soat)
    final initialTables = [
      ClubTablesCompanion.insert(
        id: '1', name: 'Maydon 1', type: 'football',
        pricePerHour: 100000, sortOrder: const Value(1),
        createdAt: Value(now), updatedAt: Value(now),
      ),
      ClubTablesCompanion.insert(
        id: '2', name: 'Maydon 2', type: 'football',
        pricePerHour: 100000, sortOrder: const Value(2),
        createdAt: Value(now), updatedAt: Value(now),
      ),
      ClubTablesCompanion.insert(
        id: '3', name: 'Bilyard 1', type: 'billiard',
        pricePerHour: 25000, sortOrder: const Value(3),
        createdAt: Value(now), updatedAt: Value(now),
      ),
      ClubTablesCompanion.insert(
        id: '4', name: 'Bilyard 2', type: 'billiard',
        pricePerHour: 25000, sortOrder: const Value(4),
        createdAt: Value(now), updatedAt: Value(now),
      ),
      ClubTablesCompanion.insert(
        id: '5', name: 'PlayStation VIP', type: 'ps',
        pricePerHour: 30000, sortOrder: const Value(5),
        createdAt: Value(now), updatedAt: Value(now),
      ),
      ClubTablesCompanion.insert(
        id: '6', name: 'Tennis Kort', type: 'tennis',
        pricePerHour: 50000, sortOrder: const Value(6),
        createdAt: Value(now), updatedAt: Value(now),
      ),
    ];

    for (final table in initialTables) {
      await into(clubTables).insertOnConflictUpdate(table);
    }

    // 2. Mahsulotlar (Skrinshot 7: Cola, Fanta, Suv, Chips, Choy)
    final initialProducts = [
      ProductsCompanion.insert(
        id: 'p1', name: 'Cola', category: const Value('drink'),
        price: 10000, stock: const Value(50),
        createdAt: Value(now), updatedAt: Value(now),
      ),
      ProductsCompanion.insert(
        id: 'p2', name: 'Fanta', category: const Value('drink'),
        price: 10000, stock: const Value(50),
        createdAt: Value(now), updatedAt: Value(now),
      ),
      ProductsCompanion.insert(
        id: 'p3', name: 'Suv', category: const Value('drink'),
        price: 5000, stock: const Value(100),
        createdAt: Value(now), updatedAt: Value(now),
      ),
      ProductsCompanion.insert(
        id: 'p4', name: 'Chips', category: const Value('drink'),
        price: 12000, stock: const Value(40),
        createdAt: Value(now), updatedAt: Value(now),
      ),
      ProductsCompanion.insert(
        id: 'p5', name: 'Choy', category: const Value('drink'),
        price: 8000, stock: const Value(60),
        createdAt: Value(now), updatedAt: Value(now),
      ),
    ];

    for (final prod in initialProducts) {
      await into(products).insertOnConflictUpdate(prod);
    }

    // 3. Maydon 1 uchun jonli sessiya (Skrinshot 6 bilan 1:1)
    final existingSession = await (select(sessions)
          ..where((s) => s.tableId.equals('1') & s.status.equals('active')))
        .get();
    if (existingSession.isEmpty) {
      await into(sessions).insertOnConflictUpdate(
        SessionsCompanion.insert(
          id: 'demo_session_1',
          tableId: '1',
          startedAt: now.subtract(const Duration(seconds: 8)),
          status: const Value('active'),
          totalAmount: const Value(1000),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    }
  }
}

// Baza faylini ochish
QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'arena',
    native: DriftNativeOptions(
      databasePath: () async {
        final dir = await getApplicationDocumentsDirectory();
        return p.join(dir.path, 'arena.db');
      },
    ),
  );
}
