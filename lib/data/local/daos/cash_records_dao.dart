// ============================================
// Arena — CashRecordsDao
// ============================================

import 'package:drift/drift.dart';
import '../tables/cash_records_table.dart';
import '../app_database.dart';

part 'cash_records_dao.g.dart';

@DriftAccessor(tables: [CashRecords])
class CashRecordsDao extends DatabaseAccessor<AppDatabase>
    with _$CashRecordsDaoMixin {
  CashRecordsDao(super.db);

  // Bugungi kassa
  Stream<List<CashRecord>> watchTodayRecords() {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end   = start.add(const Duration(days: 1));
    return (select(cashRecords)
      ..where((r) => r.recordedAt.isBetweenValues(start, end))
      ..orderBy([(r) => OrderingTerm.desc(r.recordedAt)]))
        .watch();
  }

  // Sana oralig'i uchun
  Future<List<CashRecord>> getByDateRange(DateTime from, DateTime to) =>
      (select(cashRecords)
        ..where((r) => r.recordedAt.isBetweenValues(from, to))
        ..orderBy([(r) => OrderingTerm.desc(r.recordedAt)]))
          .get();

  // Bugungi jami (kirim - chiqim)
  Future<int> getTodayTotal() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end   = start.add(const Duration(days: 1));
    final records = await (select(cashRecords)
      ..where((r) => r.recordedAt.isBetweenValues(start, end)))
        .get();
    int total = 0;
    for (final r in records) {
      total += r.amount;
    }
    return total;
  }

  Future<void> insertRecord(CashRecordsCompanion entry) =>
      into(cashRecords).insertOnConflictUpdate(entry);

  Future<List<CashRecord>> getUnsynced() =>
      (select(cashRecords)..where((r) => r.isSynced.equals(false))).get();

  Future<void> markSynced(String id) =>
      (update(cashRecords)..where((r) => r.id.equals(id)))
          .write(const CashRecordsCompanion(isSynced: Value(true)));
}
