// ============================================
// Arena — debts jadvali (Drift)
// Qarz yozuvlari — har bir tranzaksiya
// ============================================

import 'package:drift/drift.dart';
import 'customers_table.dart';

class Debts extends Table {
  TextColumn     get id          => text()();
  TextColumn     get customerId  => text().references(Customers, #id)();
  IntColumn      get amount      => integer()();         // musbat = qarz, manfiy = to'liq
  TextColumn     get type        => text()();            // debt | payment
  TextColumn?    get description => text().nullable()(); // "Bilyard 2 soat" kabi
  TextColumn?    get sessionId   => text().nullable()(); // sessiyaga bog'liq bo'lsa

  DateTimeColumn get createdAt   => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt   => dateTime().withDefault(currentDateAndTime)();
  BoolColumn     get isSynced    => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
