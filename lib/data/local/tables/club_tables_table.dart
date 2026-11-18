// ============================================
// Arena — club_tables jadvali (Drift)
// Stol/zona ma'lumotlari
// ============================================

import 'package:drift/drift.dart';

class ClubTables extends Table {
  // Birlamchi kalit — UUID
  TextColumn get id      => text()();
  TextColumn get name    => text()();              // "Bilyard 1", "PS 3"
  TextColumn get type    => text()();              // billiard | football | ps | tennis | other
  IntColumn  get pricePerHour => integer()();     // so'mda
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn  get sortOrder => integer().withDefault(const Constant(0))();

  // Sinxronizatsiya uchun
  DateTimeColumn get createdAt  => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt  => dateTime().withDefault(currentDateAndTime)();
  BoolColumn     get isSynced   => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
