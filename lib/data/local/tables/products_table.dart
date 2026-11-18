// ============================================
// Arena — products jadvali (Drift)
// Do'kon / bar tovarlari
// ============================================

import 'package:drift/drift.dart';

class Products extends Table {
  TextColumn  get id          => text()();
  TextColumn  get name        => text()();
  TextColumn? get barcode     => text().nullable()();
  IntColumn   get price       => integer()();              // so'm
  IntColumn   get stock       => integer().withDefault(const Constant(0))();
  TextColumn? get category    => text().nullable()();      // drink | snack | other
  TextColumn? get imageUrl    => text().nullable()();
  BoolColumn  get isActive    => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn     get isSynced  => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
