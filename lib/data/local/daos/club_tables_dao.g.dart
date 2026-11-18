// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'club_tables_dao.dart';

// ignore_for_file: type=lint
mixin _$ClubTablesDaoMixin on DatabaseAccessor<AppDatabase> {
  $ClubTablesTable get clubTables => attachedDatabase.clubTables;
  ClubTablesDaoManager get managers => ClubTablesDaoManager(this);
}

class ClubTablesDaoManager {
  final _$ClubTablesDaoMixin _db;
  ClubTablesDaoManager(this._db);
  $$ClubTablesTableTableManager get clubTables =>
      $$ClubTablesTableTableManager(_db.attachedDatabase, _db.clubTables);
}
