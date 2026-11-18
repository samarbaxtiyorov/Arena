// ============================================
// Arena — Arxiv Riverpod Providers & Modeli
// Yakunlangan o'yinlar, hisob-kitoblar, statistika
// ============================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/database_providers.dart';

enum ArchiveDateFilter { today, yesterday, week, month, all }

class ArchiveFilterState {
  final ArchiveDateFilter dateFilter;
  final String searchQuery;
  final DateTime? customDate;

  const ArchiveFilterState({
    this.dateFilter = ArchiveDateFilter.today,
    this.searchQuery = '',
    this.customDate,
  });

  ArchiveFilterState copyWith({
    ArchiveDateFilter? dateFilter,
    String? searchQuery,
    DateTime? customDate,
  }) {
    return ArchiveFilterState(
      dateFilter: dateFilter ?? this.dateFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      customDate: customDate ?? this.customDate,
    );
  }
}

class ArchiveFilterNotifier extends Notifier<ArchiveFilterState> {
  @override
  ArchiveFilterState build() => const ArchiveFilterState();

  void setFilter(ArchiveDateFilter filter) {
    state = state.copyWith(dateFilter: filter, customDate: null);
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCustomDate(DateTime date) {
    state = state.copyWith(customDate: date);
  }
}

final archiveFilterProvider =
    NotifierProvider<ArchiveFilterNotifier, ArchiveFilterState>(
        ArchiveFilterNotifier.new);

// Arxivdagi to'liq o'yin kartasi modeli
class ArchivedGameSession {
  final Session session;
  final ClubTable? table;
  final Customer? customer;
  final int gameAmount;
  final int barAmount;
  final int totalAmount;
  final String barItemsSummary;

  const ArchivedGameSession({
    required this.session,
    this.table,
    this.customer,
    required this.gameAmount,
    required this.barAmount,
    required this.totalAmount,
    this.barItemsSummary = '',
  });
}

// Barcha yakunlangan o'yinlar va hisob-kitoblar provideri
final archiveGamesProvider = StreamProvider<List<ArchivedGameSession>>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final filter = ref.watch(archiveFilterProvider);

  // Sessions oqimi
  await for (final allSessions in (db.select(db.sessions)
        ..where((s) => s.status.equals('finished'))
        ..orderBy([(s) => OrderingTerm.desc(s.endedAt)]))
      .watch()) {
    final tables = await db.clubTablesDao.watchAllTables().first;
    final customers = await db.customersDao.watchAllCustomers().first;

    final now = DateTime.now();
    DateTime startRange;
    DateTime endRange = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (filter.dateFilter) {
      case ArchiveDateFilter.today:
        startRange = DateTime(now.year, now.month, now.day);
        break;
      case ArchiveDateFilter.yesterday:
        final y = now.subtract(const Duration(days: 1));
        startRange = DateTime(y.year, y.month, y.day);
        endRange = DateTime(y.year, y.month, y.day, 23, 59, 59);
        break;
      case ArchiveDateFilter.week:
        startRange = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 7));
        break;
      case ArchiveDateFilter.month:
        startRange = DateTime(now.year, now.month, 1);
        break;
      case ArchiveDateFilter.all:
        startRange = DateTime(2020);
        break;
    }

    if (filter.customDate != null) {
      final cd = filter.customDate!;
      startRange = DateTime(cd.year, cd.month, cd.day);
      endRange = DateTime(cd.year, cd.month, cd.day, 23, 59, 59);
    }

    final tableMap = {for (final t in tables) t.id: t};
    final customerMap = {for (final c in customers) c.id: c};

    final filtered = allSessions.where((s) {
      final sessionTime = s.endedAt ?? s.startedAt;
      final inDate = sessionTime.isAfter(startRange) &&
          sessionTime.isBefore(endRange.add(const Duration(seconds: 1)));
      if (!inDate) return false;

      if (filter.searchQuery.isNotEmpty) {
        final q = filter.searchQuery.toLowerCase();
        final tableName = tableMap[s.tableId]?.name.toLowerCase() ?? '';
        final custName = customerMap[s.customerId]?.name.toLowerCase() ?? '';
        final notes = s.notes?.toLowerCase() ?? '';
        if (!tableName.contains(q) && !custName.contains(q) && !notes.contains(q)) {
          return false;
        }
      }
      return true;
    }).map((s) {
      final tbl = tableMap[s.tableId];
      final cust = customerMap[s.customerId];

      // Bar va O'yin summasini hisoblash
      int gameAmt = s.totalAmount;
      int barAmt = 0;
      String barNote = '';

      if (s.notes != null && s.notes!.contains('Bar:')) {
        // Notes format: "Bar: Cola x2 (20000 so'm), Choy x1 (8000 so'm) | O'yin: 30000 so'm"
        final parts = s.notes!.split('|');
        for (final p in parts) {
          if (p.trim().startsWith('Bar:')) {
            barNote = p.replaceAll('Bar:', '').trim();
          }
        }
      }

      // Agar duration bo'lsa stol narxidan kelib chiqib o'yin narxini topamiz
      if (tbl != null && s.durationMin > 0) {
        final calculatedGame = ((s.durationMin / 60.0) * tbl.pricePerHour).round();
        if (calculatedGame <= s.totalAmount) {
          gameAmt = calculatedGame;
          barAmt = s.totalAmount - calculatedGame;
        }
      }

      return ArchivedGameSession(
        session: s,
        table: tbl,
        customer: cust,
        gameAmount: gameAmt,
        barAmount: barAmt,
        totalAmount: s.totalAmount,
        barItemsSummary: barNote,
      );
    }).toList();

    yield filtered;
  }
});

// 4 Stat metrikasi
class ArchiveStats {
  final int gamesCount;
  final int totalRevenue;
  final int gameRevenue;
  final int barRevenue;

  const ArchiveStats({
    this.gamesCount = 0,
    this.totalRevenue = 0,
    this.gameRevenue = 0,
    this.barRevenue = 0,
  });
}

final archiveStatsProvider = Provider<ArchiveStats>((ref) {
  final gamesAsync = ref.watch(archiveGamesProvider);
  return gamesAsync.maybeWhen(
    data: (games) {
      int total = 0;
      int gameRev = 0;
      int barRev = 0;

      for (final g in games) {
        total += g.totalAmount;
        gameRev += g.gameAmount;
        barRev += g.barAmount;
      }

      return ArchiveStats(
        gamesCount: games.length,
        totalRevenue: total,
        gameRevenue: gameRev,
        barRevenue: barRev,
      );
    },
    orElse: () => const ArchiveStats(),
  );
});
