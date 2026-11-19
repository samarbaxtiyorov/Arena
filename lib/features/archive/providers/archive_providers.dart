// ============================================
// Arena — Arxiv Riverpod Providers & Modeli
// O'yinlar, Do'kon savdolari va Qarz to'lovlarini to'liq hisoblash
// ============================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/repositories/database_providers.dart';
import '../../../core/utils/session_billing_helper.dart';

enum ArchiveDateFilter { today, yesterday, week, month, all }
enum ArchiveTypeFilter { all, game, shop, debtPayment }

class ArchiveFilterState {
  final ArchiveDateFilter dateFilter;
  final ArchiveTypeFilter typeFilter;
  final String searchQuery;
  final DateTime? customDate;

  const ArchiveFilterState({
    this.dateFilter = ArchiveDateFilter.today,
    this.typeFilter = ArchiveTypeFilter.all,
    this.searchQuery = '',
    this.customDate,
  });

  ArchiveFilterState copyWith({
    ArchiveDateFilter? dateFilter,
    ArchiveTypeFilter? typeFilter,
    String? searchQuery,
    DateTime? customDate,
  }) {
    return ArchiveFilterState(
      dateFilter: dateFilter ?? this.dateFilter,
      typeFilter: typeFilter ?? this.typeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      customDate: customDate ?? this.customDate,
    );
  }
}

class ArchiveFilterNotifier extends Notifier<ArchiveFilterState> {
  @override
  ArchiveFilterState build() => const ArchiveFilterState();

  void setDateFilter(ArchiveDateFilter filter) {
    state = state.copyWith(dateFilter: filter, customDate: null);
  }

  void setTypeFilter(ArchiveTypeFilter filter) {
    state = state.copyWith(typeFilter: filter);
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

// Arxiv elementi turi
enum ArchiveItemType { game, shop, debtPayment }

// Universal arxiv elementi modeli
class ArchiveItem {
  final String id;
  final ArchiveItemType type;
  final String title;
  final String subtitle;
  final String details;
  final int amount;
  final String paymentType; // 'cash', 'card', 'debt'
  final DateTime timestamp;
  final String? customerName;
  final String? rawReceipt;
  final dynamic originalObject; // Session yoki CashRecord yoki Debt

  const ArchiveItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.amount,
    required this.paymentType,
    required this.timestamp,
    this.customerName,
    this.rawReceipt,
    this.originalObject,
  });
}

// Barcha arxiv elementlari oqimi
final archiveItemsProvider = StreamProvider<List<ArchiveItem>>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final filter = ref.watch(archiveFilterProvider);

  // 1. Sessions (O'yinlar)
  final sessionsStream = (db.select(db.sessions)
        ..where((s) => s.status.equals('finished'))
        ..orderBy([(s) => OrderingTerm.desc(s.endedAt)]))
      .watch();

  // 2. CashRecords (Kassa yozuvlari — Do'kon va Qarz to'lovlari)
  final cashRecordsStream = (db.select(db.cashRecords)
        ..where((c) => c.type.equals('income'))
        ..orderBy([(c) => OrderingTerm.desc(c.recordedAt)]))
      .watch();

  // 3. Debts (Nasiya orqali qilingan bar savdolari)
  final debtsStream = (db.select(db.debts)
        ..orderBy([(d) => OrderingTerm.desc(d.createdAt)]))
      .watch();

  // Oqimlarni birlashtiramiz
  await for (final allSessions in sessionsStream) {
    final cashRecords = await cashRecordsStream.first;
    final debts = await debtsStream.first;
    final tables = await db.clubTablesDao.watchAllTables().first;
    final customers = await db.customersDao.watchAllCustomers().first;

    final tableMap = {for (final t in tables) t.id: t};
    final customerMap = {for (final c in customers) c.id: c};

    final List<ArchiveItem> items = [];

    // --- A. O'YINLAR (Sessions) ---
    for (final s in allSessions) {
      final tbl = tableMap[s.tableId];
      final cust = customerMap[s.customerId];
      final endTime = s.endedAt ?? s.startedAt;
      final startTime = s.startedAt;

      final diff = endTime.difference(startTime);
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      final durationStr = h > 0 ? '$h s $m m' : '$m daqiqa';

      final barAmt = SessionBillingHelper.getBarTotal(s.notes);
      final barItems = SessionBillingHelper.getBarItemsSummary(s.notes);
      final splits = SessionBillingHelper.getSplits(s.notes);

      final List<String> detailsList = [];
      if (barItems.isNotEmpty) {
        detailsList.add("Bar: ${barItems.join(', ')} (${formatSum(barAmt)})");
      }
      if (splits.isNotEmpty) {
        final splitStr = splits.map((sp) => "${sp.name}: ${formatSum(sp.amount)}").join(" | ");
        detailsList.add("Bo'lingan: $splitStr");
      }

      final timeFmt = DateFormat('HH:mm').format(startTime);
      final endFmt = DateFormat('HH:mm').format(endTime);

      items.add(ArchiveItem(
        id: 'session_${s.id}',
        type: ArchiveItemType.game,
        title: tbl?.name ?? "Noma'lum maydon",
        subtitle: "$timeFmt - $endFmt ($durationStr)",
        details: detailsList.join('\n'),
        amount: s.totalAmount,
        paymentType: s.paymentType,
        timestamp: endTime,
        customerName: cust?.name,
        originalObject: s,
      ));
    }

    // --- B. DO'KON / BAR SAVDOLARI (CashRecords shop bo'limi) ---
    for (final cr in cashRecords) {
      if (cr.category == 'shop') {
        // Tavsif: "Bar savdosi (cash): Cola x2, Fanta x1"
        final desc = cr.description ?? 'Do\'kon savdosi';
        String itemsDetails = desc;
        String payType = 'cash';
        if (desc.contains('(') && desc.contains(')')) {
          final start = desc.indexOf('(') + 1;
          final end = desc.indexOf(')');
          payType = desc.substring(start, end);
          if (desc.contains(':')) {
            itemsDetails = desc.substring(desc.indexOf(':') + 1).trim();
          }
        }

        items.add(ArchiveItem(
          id: 'cash_${cr.id}',
          type: ArchiveItemType.shop,
          title: "Do'kon & Bar Savdosi",
          subtitle: DateFormat('HH:mm').format(cr.recordedAt),
          details: itemsDetails,
          amount: cr.amount,
          paymentType: payType,
          timestamp: cr.recordedAt,
          originalObject: cr,
        ));
      } else if (cr.category == 'debt_payment') {
        // --- C. QARZ TO'LOVLARI (CashRecords debt_payment) ---
        final desc = cr.description ?? "Qarz to'lovi";
        items.add(ArchiveItem(
          id: 'debtpay_${cr.id}',
          type: ArchiveItemType.debtPayment,
          title: "Qarz To'lovi",
          subtitle: DateFormat('HH:mm').format(cr.recordedAt),
          details: desc,
          amount: cr.amount,
          paymentType: desc.contains('card') ? 'card' : 'cash',
          timestamp: cr.recordedAt,
          originalObject: cr,
        ));
      }
    }

    // --- D. NASIYA DO'KON SAVDOLARI (Debts jadvali) ---
    for (final d in debts) {
      if (d.type == 'debt' && d.description != null && d.description!.contains('Bar savdosi')) {
        final cust = customerMap[d.customerId];
        String itemsDetails = d.description!;
        if (itemsDetails.contains(':')) {
          itemsDetails = itemsDetails.substring(itemsDetails.indexOf(':') + 1).trim();
        }

        items.add(ArchiveItem(
          id: 'debt_shop_${d.id}',
          type: ArchiveItemType.shop,
          title: "Do'kon Savdosi (Nasiya)",
          subtitle: DateFormat('HH:mm').format(d.createdAt),
          details: itemsDetails,
          amount: d.amount,
          paymentType: 'debt',
          timestamp: d.createdAt,
          customerName: cust?.name,
          originalObject: d,
        ));
      }
    }

    // Sana va filtrlash
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

    // Filtrlash va saralash
    final filtered = items.where((item) {
      // 1. Sana bo'yicha
      final inDate = item.timestamp.isAfter(startRange.subtract(const Duration(seconds: 1))) &&
          item.timestamp.isBefore(endRange.add(const Duration(seconds: 1)));
      if (!inDate) return false;

      // 2. Toifa bo'yicha
      if (filter.typeFilter != ArchiveTypeFilter.all) {
        if (filter.typeFilter == ArchiveTypeFilter.game &&
            item.type != ArchiveItemType.game) {
          return false;
        }
        if (filter.typeFilter == ArchiveTypeFilter.shop &&
            item.type != ArchiveItemType.shop) {
          return false;
        }
        if (filter.typeFilter == ArchiveTypeFilter.debtPayment &&
            item.type != ArchiveItemType.debtPayment) {
          return false;
        }
      }

      // 3. Qidiruv bo'yicha
      if (filter.searchQuery.isNotEmpty) {
        final q = filter.searchQuery.toLowerCase();
        final matchTitle = item.title.toLowerCase().contains(q);
        final matchDetails = item.details.toLowerCase().contains(q);
        final matchCust = item.customerName?.toLowerCase().contains(q) ?? false;
        if (!matchTitle && !matchDetails && !matchCust) return false;
      }

      return true;
    }).toList();

    // Vaqt bo'yicha kamayish tartibida saralash (eng oxirgisi tepada)
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    yield filtered;
  }
});

// Arxiv umumiy hisobot statistikasi
class ArchiveOverallStats {
  final int totalCount;
  final int totalRevenue;
  final int gameRevenue;
  final int gameCount;
  final int shopRevenue;
  final int shopCount;
  final int debtPaymentRevenue;
  final int debtPaymentCount;

  const ArchiveOverallStats({
    this.totalCount = 0,
    this.totalRevenue = 0,
    this.gameRevenue = 0,
    this.gameCount = 0,
    this.shopRevenue = 0,
    this.shopCount = 0,
    this.debtPaymentRevenue = 0,
    this.debtPaymentCount = 0,
  });
}

final archiveOverallStatsProvider = Provider<ArchiveOverallStats>((ref) {
  final itemsAsync = ref.watch(archiveItemsProvider);
  return itemsAsync.maybeWhen(
    data: (items) {
      int totalRev = 0;
      int gameRev = 0;
      int gameCnt = 0;
      int shopRev = 0;
      int shopCnt = 0;
      int debtRev = 0;
      int debtCnt = 0;

      for (final item in items) {
        totalRev += item.amount;
        switch (item.type) {
          case ArchiveItemType.game:
            gameRev += item.amount;
            gameCnt++;
            break;
          case ArchiveItemType.shop:
            shopRev += item.amount;
            shopCnt++;
            break;
          case ArchiveItemType.debtPayment:
            debtRev += item.amount;
            debtCnt++;
            break;
        }
      }

      return ArchiveOverallStats(
        totalCount: items.length,
        totalRevenue: totalRev,
        gameRevenue: gameRev,
        gameCount: gameCnt,
        shopRevenue: shopRev,
        shopCount: shopCnt,
        debtPaymentRevenue: debtRev,
        debtPaymentCount: debtCnt,
      );
    },
    orElse: () => const ArchiveOverallStats(),
  );
});
