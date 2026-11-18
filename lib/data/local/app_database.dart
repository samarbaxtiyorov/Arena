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
      // Boshlang'ich stollarni qo'shamiz
      await _seedInitialData();
    },
    onUpgrade: (m, from, to) async {
      // Keyingi versiyalar uchun
    },
  );

  // Boshlang'ich ma'lumotlar (demo stollar)
  Future<void> _seedInitialData() async {
    final now = DateTime.now();
    final initialTables = [
      ClubTablesCompanion.insert(
        id: '1', name: 'Bilyard 1', type: 'billiard',
        pricePerHour: 15000, sortOrder: const Value(1),
        createdAt: Value(now), updatedAt: Value(now),
      ),
      ClubTablesCompanion.insert(
        id: '2', name: 'Bilyard 2', type: 'billiard',
        pricePerHour: 15000, sortOrder: const Value(2),
        createdAt: Value(now), updatedAt: Value(now),
      ),
      ClubTablesCompanion.insert(
        id: '3', name: 'Futbol 1', type: 'football',
        pricePerHour: 30000, sortOrder: const Value(3),
        createdAt: Value(now), updatedAt: Value(now),
      ),
      ClubTablesCompanion.insert(
        id: '4', name: 'PlayStation 1', type: 'ps',
        pricePerHour: 20000, sortOrder: const Value(4),
        createdAt: Value(now), updatedAt: Value(now),
      ),
      ClubTablesCompanion.insert(
        id: '5', name: 'PlayStation 2', type: 'ps',
        pricePerHour: 20000, sortOrder: const Value(5),
        createdAt: Value(now), updatedAt: Value(now),
      ),
      ClubTablesCompanion.insert(
        id: '6', name: 'Tennis 1', type: 'tennis',
        pricePerHour: 25000, sortOrder: const Value(6),
        createdAt: Value(now), updatedAt: Value(now),
      ),
    ];

    for (final table in initialTables) {
      await into(clubTables).insertOnConflictUpdate(table);
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
