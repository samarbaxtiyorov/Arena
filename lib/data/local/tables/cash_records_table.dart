// ============================================
// Arena — cash_records jadvali (Drift)
// Kunlik kassa — kirim / chiqim
// ============================================

import 'package:drift/drift.dart';

class CashRecords extends Table {
  TextColumn     get id          => text()();
  IntColumn      get amount      => integer()();     // musbat = kirim, manfiy = chiqim
  TextColumn     get type        => text()();        // income | expense
  TextColumn?    get category    => text().nullable()(); // table | shop | other_income | salary | ...
  TextColumn?    get description => text().nullable()();
  TextColumn?    get sessionId   => text().nullable()();

  DateTimeColumn get recordedAt  => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt   => dateTime().withDefault(currentDateAndTime)();
  BoolColumn     get isSynced    => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
