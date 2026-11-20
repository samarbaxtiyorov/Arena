// ============================================
// Arena — SessionsDao
// ============================================

import 'package:drift/drift.dart';
import '../tables/sessions_table.dart';
import '../tables/club_tables_table.dart';
import '../app_database.dart';

part 'sessions_dao.g.dart';

@DriftAccessor(tables: [Sessions, ClubTables])
class SessionsDao extends DatabaseAccessor<AppDatabase>
    with _$SessionsDaoMixin {
  SessionsDao(super.db);

  // Stol uchun faol sessiya
  Stream<Session?> watchActiveSession(String tableId) =>
      (select(sessions)
        ..where((s) =>
            s.tableId.equals(tableId) & s.status.equals('active'))
        ..limit(1))
          .watchSingleOrNull();

  Future<Session?> getActiveSessionForTable(String tableId) =>
      (select(sessions)
        ..where((s) =>
            s.tableId.equals(tableId) & s.status.equals('active'))
        ..limit(1))
          .getSingleOrNull();

  // Stol uchun barcha sessiyalar (oxirgi 50 ta)
  Future<List<Session>> getSessionsForTable(String tableId) =>
      (select(sessions)
        ..where((s) => s.tableId.equals(tableId))
        ..orderBy([(s) => OrderingTerm.desc(s.startedAt)])
        ..limit(50))
          .get();

  // Bugungi barcha tugatilgan sessiyalar
  Future<List<Session>> getTodaySessions() {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end   = start.add(const Duration(days: 1));
    return (select(sessions)
      ..where((s) =>
          s.startedAt.isBetweenValues(start, end) &
          s.status.equals('finished'))
      ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
        .get();
  }

  // Faol sessiyalar (barcha stollar uchun)
  Stream<List<Session>> watchActiveSessions() =>
      (select(sessions)
        ..where((s) => s.status.equals('active') | s.status.equals('paused')))
          .watch();

  // Sessiya qo'shish
  Future<void> insertSession(SessionsCompanion entry) =>
      into(sessions).insertOnConflictUpdate(entry);

  // Sessiya yangilash
  Future<void> updateSession(SessionsCompanion entry) =>
      (update(sessions)..where((s) => s.id.equals(entry.id.value)))
          .write(entry);

  // Sessiyani tugatish
  Future<void> finishSession(String id, int totalAmount) =>
      (update(sessions)..where((s) => s.id.equals(id)))
          .write(SessionsCompanion(
            status:      const Value('finished'),
            endedAt:     Value(DateTime.now()),
            totalAmount: Value(totalAmount),
            updatedAt:   Value(DateTime.now()),
            isSynced:    const Value(false),
          ));

  // Pauza
  Future<void> pauseSession(String id) =>
      (update(sessions)..where((s) => s.id.equals(id)))
          .write(SessionsCompanion(
            status:    const Value('paused'),
            updatedAt: Value(DateTime.now()),
            isSynced:  const Value(false),
          ));

  // Davom ettirish
  Future<void> resumeSession(String id) =>
      (update(sessions)..where((s) => s.id.equals(id)))
          .write(SessionsCompanion(
            status:    const Value('active'),
            updatedAt: Value(DateTime.now()),
            isSynced:  const Value(false),
          ));

  // Sinxronlanmagan
  Future<List<Session>> getUnsynced() =>
      (select(sessions)..where((s) => s.isSynced.equals(false))).get();

  Future<void> markSynced(String id) =>
      (update(sessions)..where((s) => s.id.equals(id)))
          .write(const SessionsCompanion(isSynced: Value(true)));
}
