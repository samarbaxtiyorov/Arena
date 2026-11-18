// ============================================
// Arena — DebtsDao
// ============================================

import 'package:drift/drift.dart';
import '../tables/debts_table.dart';
import '../tables/customers_table.dart';
import '../app_database.dart';

part 'debts_dao.g.dart';

@DriftAccessor(tables: [Debts, Customers])
class DebtsDao extends DatabaseAccessor<AppDatabase>
    with _$DebtsDaoMixin {
  DebtsDao(super.db);

  // Mijoz bo'yicha qarz tarixi
  Stream<List<Debt>> watchDebtsForCustomer(String customerId) =>
      (select(debts)
        ..where((d) => d.customerId.equals(customerId))
        ..orderBy([(d) => OrderingTerm.desc(d.createdAt)]))
          .watch();

  // Oxirgi N ta tranzaksiya (kassa uchun)
  Future<List<Debt>> getRecentDebts({int limit = 50}) =>
      (select(debts)
        ..orderBy([(d) => OrderingTerm.desc(d.createdAt)])
        ..limit(limit))
          .get();

  Future<void> insertDebt(DebtsCompanion entry) =>
      into(debts).insertOnConflictUpdate(entry);

  // Mijozning umumiy qarzini qayta hisoblash
  Future<int> calculateTotalDebt(String customerId) async {
    final rows = await (select(debts)
      ..where((d) => d.customerId.equals(customerId)))
        .get();
    int total = 0;
    for (final d in rows) {
      total += d.amount;
    }
    return total;
  }

  Future<List<Debt>> getUnsynced() =>
      (select(debts)..where((d) => d.isSynced.equals(false))).get();

  Future<void> markSynced(String id) =>
      (update(debts)..where((d) => d.id.equals(id)))
          .write(const DebtsCompanion(isSynced: Value(true)));
}
