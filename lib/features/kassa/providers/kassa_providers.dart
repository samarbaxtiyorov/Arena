// ============================================
// Arena — Kassa Riverpod Providers
// ============================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/app_database.dart';
import '../../../data/repositories/database_providers.dart';

// Kassa davr filtri
enum KassaPeriod { today, yesterday, week, month }

class KassaPeriodNotifier extends Notifier<KassaPeriod> {
  @override
  KassaPeriod build() => KassaPeriod.today;

  void select(KassaPeriod period) => state = period;
}

final kassaPeriodProvider =
    NotifierProvider<KassaPeriodNotifier, KassaPeriod>(KassaPeriodNotifier.new);

// Barcha kassa yozuvlari oqimi
final allCashRecordsProvider = StreamProvider<List<CashRecord>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.cashRecordsDao.watchAllRecords();
});

// Davr bo'yicha filtrlangan kassa yozuvlari
final filteredCashRecordsProvider = Provider<List<CashRecord>>((ref) {
  final recordsAsync = ref.watch(allCashRecordsProvider);
  final period = ref.watch(kassaPeriodProvider);

  return recordsAsync.maybeWhen(
    data: (records) {
      final now = DateTime.now();

      DateTime start;
      DateTime end;

      switch (period) {
        case KassaPeriod.today:
          start = DateTime(now.year, now.month, now.day);
          end = start.add(const Duration(days: 1));
          break;
        case KassaPeriod.yesterday:
          final y = now.subtract(const Duration(days: 1));
          start = DateTime(y.year, y.month, y.day);
          end = start.add(const Duration(days: 1));
          break;
        case KassaPeriod.week:
          // Hafta boshi (Dushanba)
          final weekday = now.weekday;
          start = DateTime(now.year, now.month, now.day - (weekday - 1));
          end = now.add(const Duration(days: 1));
          break;
        case KassaPeriod.month:
          start = DateTime(now.year, now.month, 1);
          end = now.add(const Duration(days: 1));
          break;
      }

      return records.where((r) {
        return r.recordedAt.isAfter(start) && r.recordedAt.isBefore(end);
      }).toList();
    },
    orElse: () => [],
  );
});

// Kassa umumiy balansi va statistikasi
class KassaSummary {
  final int totalIncome;
  final int totalExpense;
  final int netBalance; // Kirim - Chiqim
  final int tableIncome;
  final int shopIncome;
  final int debtIncome;

  const KassaSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    required this.tableIncome,
    required this.shopIncome,
    required this.debtIncome,
  });
}

final kassaSummaryProvider = Provider<KassaSummary>((ref) {
  final records = ref.watch(filteredCashRecordsProvider);

  int income = 0;
  int expense = 0;
  int table = 0;
  int shop = 0;
  int debt = 0;

  for (final r in records) {
    if (r.type == 'income') {
      income += r.amount.abs();
      if (r.category == 'table') table += r.amount.abs();
      if (r.category == 'shop') shop += r.amount.abs();
      if (r.category == 'debt_payment') debt += r.amount.abs();
    } else if (r.type == 'expense') {
      expense += r.amount.abs();
    }
  }

  return KassaSummary(
    totalIncome: income,
    totalExpense: expense,
    netBalance: income - expense,
    tableIncome: table,
    shopIncome: shop,
    debtIncome: debt,
  );
});

// Kassa boshqaruv xizmati
class KassaController {
  final AppDatabase _db;
  final Ref _ref;
  static const _uuid = Uuid();

  KassaController(this._db, this._ref);

  // Chiqim yozish
  Future<void> addExpense({
    required int amount,
    required String category,
    required String description,
  }) async {
    final now = DateTime.now();
    await _db.cashRecordsDao.insertRecord(CashRecordsCompanion.insert(
      id: _uuid.v4(),
      amount: -amount.abs(), // Chiqim manfiy
      type: 'expense',
      category: Value(category),
      description: Value(description),
      recordedAt: Value(now),
      createdAt: Value(now),
      isSynced: const Value(false),
    ));

    _triggerSync();
  }

  // Kirim yozish (qo'lda kiritish)
  Future<void> addIncome({
    required int amount,
    required String category,
    required String description,
  }) async {
    final now = DateTime.now();
    await _db.cashRecordsDao.insertRecord(CashRecordsCompanion.insert(
      id: _uuid.v4(),
      amount: amount.abs(),
      type: 'income',
      category: Value(category),
      description: Value(description),
      recordedAt: Value(now),
      createdAt: Value(now),
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

final kassaControllerProvider = Provider<KassaController>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return KassaController(db, ref);
});
