// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_records_dao.dart';

// ignore_for_file: type=lint
mixin _$CashRecordsDaoMixin on DatabaseAccessor<AppDatabase> {
  $CashRecordsTable get cashRecords => attachedDatabase.cashRecords;
  CashRecordsDaoManager get managers => CashRecordsDaoManager(this);
}

class CashRecordsDaoManager {
  final _$CashRecordsDaoMixin _db;
  CashRecordsDaoManager(this._db);
  $$CashRecordsTableTableManager get cashRecords =>
      $$CashRecordsTableTableManager(_db.attachedDatabase, _db.cashRecords);
}
