// ============================================
// Arena — ClubTablesDao
// ============================================

import 'package:drift/drift.dart';
import '../tables/club_tables_table.dart';
import '../app_database.dart';

part 'club_tables_dao.g.dart';

@DriftAccessor(tables: [ClubTables])
class ClubTablesDao extends DatabaseAccessor<AppDatabase>
    with _$ClubTablesDaoMixin {
  ClubTablesDao(super.db);

  // Barcha aktiv stollar
  Stream<List<ClubTable>> watchAllTables() =>
      (select(clubTables)
        ..where((t) => t.isActive.equals(true))
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  // Bir stol
  Future<ClubTable?> getTableById(String id) =>
      (select(clubTables)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  // Qo'shish
  Future<void> insertTable(ClubTablesCompanion entry) =>
      into(clubTables).insertOnConflictUpdate(entry);

  // Yangilash
  Future<void> updateTable(ClubTablesCompanion entry) =>
      (update(clubTables)..where((t) => t.id.equals(entry.id.value)))
          .write(entry);

  // O'chirish (soft delete)
  Future<void> deactivateTable(String id) =>
      (update(clubTables)..where((t) => t.id.equals(id)))
          .write(ClubTablesCompanion(
            isActive:  const Value(false),
            updatedAt: Value(DateTime.now()),
          ));

  // Sinxronlanmagan yozuvlar
  Future<List<ClubTable>> getUnsynced() =>
      (select(clubTables)..where((t) => t.isSynced.equals(false)))
          .get();

  // Sinxron deb belgilash
  Future<void> markSynced(String id) =>
      (update(clubTables)..where((t) => t.id.equals(id)))
          .write(const ClubTablesCompanion(isSynced: Value(true)));
}
