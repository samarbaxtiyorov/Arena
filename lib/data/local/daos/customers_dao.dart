// ============================================
// Arena — CustomersDao
// ============================================

import 'package:drift/drift.dart';
import '../tables/customers_table.dart';
import '../app_database.dart';

part 'customers_dao.g.dart';

@DriftAccessor(tables: [Customers])
class CustomersDao extends DatabaseAccessor<AppDatabase>
    with _$CustomersDaoMixin {
  CustomersDao(super.db);

  // Barcha aktiv mijozlar (qarz bo'yicha saralangan)
  Stream<List<Customer>> watchAllCustomers() =>
      (select(customers)
        ..where((c) => c.isActive.equals(true))
        ..orderBy([(c) => OrderingTerm.desc(c.totalDebt)]))
          .watch();

  // Qidiruv
  Future<List<Customer>> searchCustomers(String query) =>
      (select(customers)
        ..where((c) =>
            c.isActive.equals(true) &
            (c.name.like('%$query%') | c.phone.like('%$query%'))))
          .get();

  Future<Customer?> getCustomerById(String id) =>
      (select(customers)..where((c) => c.id.equals(id)))
          .getSingleOrNull();

  Future<void> insertCustomer(CustomersCompanion entry) =>
      into(customers).insertOnConflictUpdate(entry);

  Future<void> updateCustomer(CustomersCompanion entry) =>
      (update(customers)..where((c) => c.id.equals(entry.id.value)))
          .write(entry);

  // Umumiy qarzni yangilash
  Future<void> updateTotalDebt(String id, int newTotal) =>
      (update(customers)..where((c) => c.id.equals(id)))
          .write(CustomersCompanion(
            totalDebt: Value(newTotal),
            updatedAt: Value(DateTime.now()),
            isSynced:  const Value(false),
          ));

  Future<List<Customer>> getUnsynced() =>
      (select(customers)..where((c) => c.isSynced.equals(false))).get();

  Future<void> markSynced(String id) =>
      (update(customers)..where((c) => c.id.equals(id)))
          .write(const CustomersCompanion(isSynced: Value(true)));
}
