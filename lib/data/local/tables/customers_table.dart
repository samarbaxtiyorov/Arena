// ============================================
// Arena — customers jadvali (Drift)
// Nasiya daftaridagi mijozlar
// ============================================

import 'package:drift/drift.dart';

class Customers extends Table {
  TextColumn  get id          => text()();
  TextColumn  get name        => text()();
  TextColumn? get phone       => text().nullable()();
  TextColumn? get notes       => text().nullable()();
  IntColumn   get totalDebt   => integer().withDefault(const Constant(0))(); // so'm
  BoolColumn  get isActive    => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn     get isSynced  => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
