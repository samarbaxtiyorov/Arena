// ============================================
// Arena — sessions jadvali (Drift)
// Har bir stol sessiyasi (taymer o'ynashi)
// ============================================

import 'package:drift/drift.dart';
import 'club_tables_table.dart';

class Sessions extends Table {
  TextColumn     get id          => text()();
  TextColumn     get tableId     => text().references(ClubTables, #id)();
  DateTimeColumn get startedAt   => dateTime()();
  DateTimeColumn? get endedAt    => dateTime().nullable()();
  IntColumn      get durationMin => integer().withDefault(const Constant(0))(); // daqiqa
  IntColumn      get totalAmount => integer().withDefault(const Constant(0))(); // so'm
  TextColumn     get status      => text().withDefault(const Constant('active'))();
  // active | paused | finished

  // Partiya bo'lish (split): kimga bog'liq (nasiya yoki naqd)
  TextColumn?    get customerId  => text().nullable()();
  TextColumn     get paymentType => text().withDefault(const Constant('cash'))();
  // cash | debt | mixed

  TextColumn?    get notes       => text().nullable()();

  // Sinxronizatsiya
  DateTimeColumn get createdAt   => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt   => dateTime().withDefault(currentDateAndTime)();
  BoolColumn     get isSynced    => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
