// ============================================
// Arena — Zallar & Stollar Riverpod Providers
// ============================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/app_database.dart';
import '../../../data/repositories/database_providers.dart';

// Barcha faol stollar oqimi
final tablesStreamProvider = StreamProvider<List<ClubTable>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.clubTablesDao.watchAllTables();
});

// Barcha faol/pauzadagi sessiyalar oqimi
final activeSessionsStreamProvider = StreamProvider<List<Session>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.sessionsDao.watchActiveSessions();
});

// Stol toifasi filtri: 'all', 'billiard', 'ps', 'football', 'tennis'
class TableCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void select(String category) => state = category;
}

final tableCategoryProvider =
    NotifierProvider<TableCategoryNotifier, String>(TableCategoryNotifier.new);

// Filtrlangan stollar
final filteredTablesProvider = Provider<List<ClubTable>>((ref) {
  final tablesAsync = ref.watch(tablesStreamProvider);
  final category = ref.watch(tableCategoryProvider);

  return tablesAsync.maybeWhen(
    data: (tables) {
      if (category == 'all') return tables;
      return tables.where((t) => t.type == category).toList();
    },
    orElse: () => [],
  );
});

// Stollar boshqaruv xizmati / Controller
class TablesController {
  final AppDatabase _db;
  final Ref _ref;
  static const _uuid = Uuid();

  TablesController(this._db, this._ref);

  // Sessiyani boshlash
  Future<void> startSession(String tableId, {String? customerId}) async {
    final now = DateTime.now();
    final newSession = SessionsCompanion.insert(
      id: _uuid.v4(),
      tableId: tableId,
      startedAt: now,
      customerId: Value(customerId),
      status: const Value('active'),
      paymentType: const Value('cash'),
      createdAt: Value(now),
      updatedAt: Value(now),
      isSynced: const Value(false),
    );

    await _db.sessionsDao.insertSession(newSession);
    _triggerSync();
  }

  // Sessiyani pauza qilish
  Future<void> pauseSession(String sessionId) async {
    await _db.sessionsDao.pauseSession(sessionId);
    _triggerSync();
  }

  // Sessiyani davom ettirish
  Future<void> resumeSession(String sessionId) async {
    await _db.sessionsDao.resumeSession(sessionId);
    _triggerSync();
  }

  // Sessiyani tugatish va to'lovni qayd qilish
  Future<void> finishSession({
    required Session session,
    required ClubTable table,
    required int finalAmount,
    required String paymentType, // 'cash', 'card', 'debt'
    String? customerId,
    String? notes,
  }) async {
    final now = DateTime.now();
    final elapsedMinutes = now.difference(session.startedAt).inMinutes;

    // 1. Sessiyani yakunlash
    await (_db.update(_db.sessions)..where((s) => s.id.equals(session.id)))
        .write(SessionsCompanion(
      status: const Value('finished'),
      endedAt: Value(now),
      durationMin: Value(elapsedMinutes),
      totalAmount: Value(finalAmount),
      paymentType: Value(paymentType),
      customerId: Value(customerId),
      notes: Value(notes),
      updatedAt: Value(now),
      isSynced: const Value(false),
    ));

    // 2. To'lov turiga qarab kassa yoki qarzga yozish
    if (paymentType == 'cash' || paymentType == 'card') {
      // Kassaga kirim
      await _db.cashRecordsDao.insertRecord(CashRecordsCompanion.insert(
        id: _uuid.v4(),
        amount: finalAmount,
        type: 'income',
        category: const Value('table'),
        description: Value('${table.name} sessiya to\'lovi ($paymentType)'),
        sessionId: Value(session.id),
        recordedAt: Value(now),
        createdAt: Value(now),
        isSynced: const Value(false),
      ));
    } else if (paymentType == 'debt' && customerId != null) {
      // Nasiya daftariga qarz qo'shish
      await _db.debtsDao.insertDebt(DebtsCompanion.insert(
        id: _uuid.v4(),
        customerId: customerId,
        amount: finalAmount,
        type: 'debt',
        description: Value('${table.name} o\'yin to\'lovi'),
        sessionId: Value(session.id),
        createdAt: Value(now),
        updatedAt: Value(now),
        isSynced: const Value(false),
      ));

      // Mijozning umumiy qarzini yangilash
      final newTotal = await _db.debtsDao.calculateTotalDebt(customerId);
      await _db.customersDao.updateTotalDebt(customerId, newTotal);
    }

    _triggerSync();
  }

  // Yangi stol / zona qo'shish
  Future<void> addTable({
    required String name,
    required String type,
    required int pricePerHour,
  }) async {
    final now = DateTime.now();
    final allTables = await _db.clubTablesDao.watchAllTables().first;
    final nextOrder = allTables.length + 1;

    await _db.clubTablesDao.insertTable(ClubTablesCompanion.insert(
      id: _uuid.v4(),
      name: name,
      type: type,
      pricePerHour: pricePerHour,
      sortOrder: Value(nextOrder),
      createdAt: Value(now),
      updatedAt: Value(now),
      isSynced: const Value(false),
    ));

    _triggerSync();
  }

  void _triggerSync() {
    try {
      final sync = _ref.read(syncServiceProvider);
      sync.syncAll();
    } catch (_) {}
  }
}

final tablesControllerProvider = Provider<TablesController>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TablesController(db, ref);
});
