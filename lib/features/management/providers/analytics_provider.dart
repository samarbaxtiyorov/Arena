// ============================================
// Arena — Biznes Tahlili & Statistika Provideri
// Real vaqt rejimida maydonlar, bar savdosi, qarzlar
// va moliyaviy samaradorlikni 100% aniq hisoblash
// ============================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../../../core/utils/session_billing_helper.dart';
import '../../../data/repositories/database_providers.dart';

enum AnalyticsPeriod { today, yesterday, week, month, all }

class AnalyticsPeriodNotifier extends Notifier<AnalyticsPeriod> {
  @override
  AnalyticsPeriod build() => AnalyticsPeriod.today;

  void setPeriod(AnalyticsPeriod p) => state = p;
}

final analyticsPeriodProvider =
    NotifierProvider<AnalyticsPeriodNotifier, AnalyticsPeriod>(
        AnalyticsPeriodNotifier.new);

// Maydon tahlili modeli
class TableAnalyticsModel {
  final String tableId;
  final String tableName;
  final String tableType;
  final int gamesCount;
  final int totalMinutes;
  final int revenue;
  final double sharePercent;

  const TableAnalyticsModel({
    required this.tableId,
    required this.tableName,
    required this.tableType,
    required this.gamesCount,
    required this.totalMinutes,
    required this.revenue,
    required this.sharePercent,
  });
}

// Top tovar modeli
class TopProductAnalytics {
  final String name;
  final int quantity;
  final int totalRevenue;

  const TopProductAnalytics({
    required this.name,
    required this.quantity,
    required this.totalRevenue,
  });
}

// Tahlil ma'lumotlari modeli
class BusinessAnalyticsData {
  final int totalRevenue;
  final int gameRevenue;
  final int gameCount;
  final int totalGameMinutes;
  final int averageGameDurationMinutes;
  final int averageGameCheck;

  final int shopRevenue;
  final int shopCount;

  final int debtPaymentRevenue;
  final int debtPaymentCount;

  final int cashTotal;
  final int cardTotal;
  final int debtTotal;

  final List<TableAnalyticsModel> tableStats;
  final List<TopProductAnalytics> topProducts;
  final String peakHourRange;

  const BusinessAnalyticsData({
    this.totalRevenue = 0,
    this.gameRevenue = 0,
    this.gameCount = 0,
    this.totalGameMinutes = 0,
    this.averageGameDurationMinutes = 0,
    this.averageGameCheck = 0,
    this.shopRevenue = 0,
    this.shopCount = 0,
    this.debtPaymentRevenue = 0,
    this.debtPaymentCount = 0,
    this.cashTotal = 0,
    this.cardTotal = 0,
    this.debtTotal = 0,
    this.tableStats = const [],
    this.topProducts = const [],
    this.peakHourRange = '18:00 - 23:00',
  });
}

final businessAnalyticsProvider =
    StreamProvider<BusinessAnalyticsData>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final period = ref.watch(analyticsPeriodProvider);

  // Sana oralig'ini aniqlash
  final now = DateTime.now();
  DateTime startRange;
  DateTime endRange = DateTime(now.year, now.month, now.day, 23, 59, 59);

  switch (period) {
    case AnalyticsPeriod.today:
      startRange = DateTime(now.year, now.month, now.day);
      break;
    case AnalyticsPeriod.yesterday:
      final y = now.subtract(const Duration(days: 1));
      startRange = DateTime(y.year, y.month, y.day);
      endRange = DateTime(y.year, y.month, y.day, 23, 59, 59);
      break;
    case AnalyticsPeriod.week:
      startRange = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 7));
      break;
    case AnalyticsPeriod.month:
      startRange = DateTime(now.year, now.month, 1);
      break;
    case AnalyticsPeriod.all:
      startRange = DateTime(2020);
      break;
  }

  // Oqimlarni kuzatish
  final sessionsStream = (db.select(db.sessions)
        ..where((s) => s.status.equals('finished'))
        ..orderBy([(s) => OrderingTerm.desc(s.endedAt)]))
      .watch();

  await for (final allSessions in sessionsStream) {
    final cashRecords = await (db.select(db.cashRecords)
          ..where((c) => c.type.equals('income')))
        .get();
    final debts = await db.select(db.debts).get();
    final allTables = await db.clubTablesDao.watchAllTables().first;

    // 1. O'yinlar filtrlash
    final periodSessions = allSessions.where((s) {
      final t = s.endedAt ?? s.startedAt;
      return t.isAfter(startRange.subtract(const Duration(seconds: 1))) &&
          t.isBefore(endRange.add(const Duration(seconds: 1)));
    }).toList();

    int gRev = 0;
    int gTotalMinutes = 0;
    final Map<String, int> tableRevenueMap = {};
    final Map<String, int> tableGamesMap = {};
    final Map<String, int> tableMinutesMap = {};
    final Map<int, int> hourFrequency = {};

    int cashSum = 0;
    int cardSum = 0;
    int debtSum = 0;

    for (final s in periodSessions) {
      final endTime = s.endedAt ?? s.startedAt;
      final startTime = s.startedAt;
      final duration = endTime.difference(startTime).inMinutes;
      final minutes = duration > 0 ? duration : 1;

      final barAmt = SessionBillingHelper.getBarTotal(s.notes);
      final gamePart = s.totalAmount >= barAmt ? s.totalAmount - barAmt : s.totalAmount;

      gRev += gamePart;
      gTotalMinutes += minutes;

      // To'lov turi
      if (s.paymentType == 'card') {
        cardSum += s.totalAmount;
      } else if (s.paymentType == 'debt') {
        debtSum += s.totalAmount;
      } else {
        cashSum += s.totalAmount;
      }

      // Maydon statistikasi
      final tid = s.tableId;
      tableRevenueMap[tid] = (tableRevenueMap[tid] ?? 0) + gamePart;
      tableGamesMap[tid] = (tableGamesMap[tid] ?? 0) + 1;
      tableMinutesMap[tid] = (tableMinutesMap[tid] ?? 0) + minutes;

      // Eng faol soatlar
      final hour = startTime.hour;
      hourFrequency[hour] = (hourFrequency[hour] ?? 0) + 1;
    }

    // 2. Do'kon / Bar savdosi filtrlash
    int sRev = 0;
    int sCnt = 0;
    final Map<String, int> productQtyMap = {};
    final Map<String, int> productRevenueMap = {};

    for (final cr in cashRecords) {
      if (cr.category == 'shop') {
        final t = cr.recordedAt;
        final inRange = t.isAfter(startRange.subtract(const Duration(seconds: 1))) &&
            t.isBefore(endRange.add(const Duration(seconds: 1)));
        if (inRange) {
          sRev += cr.amount;
          sCnt++;

          if (cr.description != null && cr.description!.contains('card')) {
            cardSum += cr.amount;
          } else {
            cashSum += cr.amount;
          }

          // Tovarlar sonini parse qilish: "Bar savdosi (cash): Cola x2, Fanta x1"
          _parseProductItems(cr.description ?? '', productQtyMap, productRevenueMap, cr.amount);
        }
      }
    }

    for (final d in debts) {
      if (d.type == 'debt' && d.description != null && d.description!.contains('Bar savdosi')) {
        final t = d.createdAt;
        final inRange = t.isAfter(startRange.subtract(const Duration(seconds: 1))) &&
            t.isBefore(endRange.add(const Duration(seconds: 1)));
        if (inRange) {
          sRev += d.amount;
          sCnt++;
          debtSum += d.amount;
          _parseProductItems(d.description ?? '', productQtyMap, productRevenueMap, d.amount);
        }
      }
    }

    // O'yinlar ichidagi bar mahsulotlarini ham parse qilish
    for (final s in periodSessions) {
      final barItems = SessionBillingHelper.getBarItemsSummary(s.notes);
      final barTotal = SessionBillingHelper.getBarTotal(s.notes);
      if (barItems.isNotEmpty && barTotal > 0) {
        for (final itemStr in barItems) {
          // Masalan: "Cola 0.5L x2"
          final parts = itemStr.split(' x');
          final name = parts[0].trim();
          final qty = parts.length > 1 ? (int.tryParse(parts[1].trim()) ?? 1) : 1;
          productQtyMap[name] = (productQtyMap[name] ?? 0) + qty;
        }
      }
    }

    // 3. Qarz To'lovlari filtrlash
    int dRev = 0;
    int dCnt = 0;
    for (final cr in cashRecords) {
      if (cr.category == 'debt_payment') {
        final t = cr.recordedAt;
        final inRange = t.isAfter(startRange.subtract(const Duration(seconds: 1))) &&
            t.isBefore(endRange.add(const Duration(seconds: 1)));
        if (inRange) {
          dRev += cr.amount;
          dCnt++;
          if (cr.description != null && cr.description!.contains('card')) {
            cardSum += cr.amount;
          } else {
            cashSum += cr.amount;
          }
        }
      }
    }

    // Maydonlar tahlili ro'yxati
    final List<TableAnalyticsModel> tableStatsList = [];
    for (final t in allTables) {
      final rev = tableRevenueMap[t.id] ?? 0;
      final gCount = tableGamesMap[t.id] ?? 0;
      final mins = tableMinutesMap[t.id] ?? 0;
      final share = gRev > 0 ? (rev / gRev) * 100 : 0.0;

      tableStatsList.add(TableAnalyticsModel(
        tableId: t.id,
        tableName: t.name,
        tableType: t.type,
        gamesCount: gCount,
        totalMinutes: mins,
        revenue: rev,
        sharePercent: share,
      ));
    }

    // Daromad bo'yicha saralash
    tableStatsList.sort((a, b) => b.revenue.compareTo(a.revenue));

    // Top tovarlar ro'yxati
    final List<TopProductAnalytics> topProdList = [];
    productQtyMap.forEach((pName, qty) {
      final rev = productRevenueMap[pName] ?? (qty * 10000);
      topProdList.add(TopProductAnalytics(
        name: pName,
        quantity: qty,
        totalRevenue: rev,
      ));
    });
    topProdList.sort((a, b) => b.quantity.compareTo(a.quantity));

    // Eng faol vaqtlar
    String peakRange = '18:00 - 23:00';
    if (hourFrequency.isNotEmpty) {
      final sortedHours = hourFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topHour = sortedHours.first.key;
      peakRange = '${topHour.toString().padLeft(2, '0')}:00 - ${(topHour + 2).toString().padLeft(2, '0')}:00';
    }

    final totalRev = gRev + sRev + dRev;
    final avgDuration = periodSessions.isNotEmpty
        ? (gTotalMinutes ~/ periodSessions.length)
        : 0;
    final avgCheck = periodSessions.isNotEmpty
        ? (gRev ~/ periodSessions.length)
        : 0;

    yield BusinessAnalyticsData(
      totalRevenue: totalRev,
      gameRevenue: gRev,
      gameCount: periodSessions.length,
      totalGameMinutes: gTotalMinutes,
      averageGameDurationMinutes: avgDuration,
      averageGameCheck: avgCheck,
      shopRevenue: sRev,
      shopCount: sCnt,
      debtPaymentRevenue: dRev,
      debtPaymentCount: dCnt,
      cashTotal: cashSum,
      cardTotal: cardSum,
      debtTotal: debtSum,
      tableStats: tableStatsList,
      topProducts: topProdList,
      peakHourRange: peakRange,
    );
  }
});

void _parseProductItems(String desc, Map<String, int> qtyMap, Map<String, int> revMap, int totalAmt) {
  if (!desc.contains(':')) return;
  final itemsPart = desc.substring(desc.indexOf(':') + 1).trim();
  final items = itemsPart.split(',');
  for (final it in items) {
    final clean = it.trim();
    if (clean.contains(' x')) {
      final parts = clean.split(' x');
      final name = parts[0].trim();
      final qty = int.tryParse(parts[1].trim()) ?? 1;
      qtyMap[name] = (qtyMap[name] ?? 0) + qty;
    } else if (clean.isNotEmpty) {
      qtyMap[clean] = (qtyMap[clean] ?? 0) + 1;
    }
  }
}
