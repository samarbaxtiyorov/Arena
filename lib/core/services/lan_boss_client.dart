// ============================================
// Arena Boss — Lokal Tarmoq Klienti (LAN Boss Client)
// Uy Wi-Fi yoki klub tarmog'ida Arena POS bilan to'g'ridan-to'g'ri bog'lanadi
// Internetsiz kassa va bilyard stollarini jonli kuzatish
// ============================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class LanBossState {
  final bool isConnected;
  final bool isScanning;
  final String? cashierIp;
  final int port;
  final String? venueName;
  final int activeTablesCount;
  final int totalTablesCount;
  final double todayRevenue;
  final double todayCash;
  final List<Map<String, dynamic>> liveTables;
  final DateTime? lastSyncTime;
  final String? errorMessage;

  const LanBossState({
    this.isConnected = false,
    this.isScanning = false,
    this.cashierIp,
    this.port = 8080,
    this.venueName,
    this.activeTablesCount = 0,
    this.totalTablesCount = 0,
    this.todayRevenue = 0,
    this.todayCash = 0,
    this.liveTables = const [],
    this.lastSyncTime,
    this.errorMessage,
  });

  LanBossState copyWith({
    bool? isConnected,
    bool? isScanning,
    String? cashierIp,
    int? port,
    String? venueName,
    int? activeTablesCount,
    int? totalTablesCount,
    double? todayRevenue,
    double? todayCash,
    List<Map<String, dynamic>>? liveTables,
    DateTime? lastSyncTime,
    String? errorMessage,
  }) {
    return LanBossState(
      isConnected: isConnected ?? this.isConnected,
      isScanning: isScanning ?? this.isScanning,
      cashierIp: cashierIp ?? this.cashierIp,
      port: port ?? this.port,
      venueName: venueName ?? this.venueName,
      activeTablesCount: activeTablesCount ?? this.activeTablesCount,
      totalTablesCount: totalTablesCount ?? this.totalTablesCount,
      todayRevenue: todayRevenue ?? this.todayRevenue,
      todayCash: todayCash ?? this.todayCash,
      liveTables: liveTables ?? this.liveTables,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errorMessage: errorMessage,
    );
  }
}

class LanBossClientNotifier extends Notifier<LanBossState> {
  Timer? _pollTimer;

  @override
  LanBossState build() {
    ref.onDispose(() {
      _pollTimer?.cancel();
    });
    return const LanBossState();
  }

  /// Kassa kompyuteriga to'g'ridan-to'g'ri ulanish
  Future<bool> connectToCashier(String ip, {int port = 8080}) async {
    final cleanIp = ip.trim().replaceAll('http://', '').replaceAll('/', '');
    if (cleanIp.isEmpty) return false;

    try {
      final pingUrl = Uri.parse('http://$cleanIp:$port/api/ping');
      final res = await http.get(pingUrl).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['app'] == 'Arena POS') {
          state = state.copyWith(
            isConnected: true,
            cashierIp: cleanIp,
            port: port,
            errorMessage: null,
          );

          // Birinchi ma'lumotlarni tortish
          await refreshLiveStatus();

          // Har 3 soniyada avtomatik jonli yangilanish
          _startPolling();
          return true;
        }
      }
    } catch (e) {
      debugPrint("❌ [LanBossClient] Ulanish xatosi: $e");
    }

    state = state.copyWith(
      isConnected: false,
      errorMessage: "Kassa ($cleanIp:$port) bilan bog'lanib bo'lmadi. Wi-Fi va IP ni tekshiring.",
    );
    return false;
  }

  /// Jonli kassa ma'lumotlarini yangilash
  Future<void> refreshLiveStatus() async {
    final ip = state.cashierIp;
    if (ip == null || !state.isConnected) return;

    try {
      final summaryUrl = Uri.parse('http://$ip:${state.port}/api/summary');
      final tablesUrl = Uri.parse('http://$ip:${state.port}/api/tables');

      final summaryRes = await http.get(summaryUrl).timeout(const Duration(seconds: 3));
      final tablesRes = await http.get(tablesUrl).timeout(const Duration(seconds: 3));

      if (summaryRes.statusCode == 200 && tablesRes.statusCode == 200) {
        final summary = jsonDecode(summaryRes.body);
        final tablesData = jsonDecode(tablesRes.body);

        final rawTables = tablesData['tables'] as List<dynamic>? ?? [];
        final parsedTables = rawTables.cast<Map<String, dynamic>>();

        state = state.copyWith(
          isConnected: true,
          venueName: summary['venueName'] as String?,
          activeTablesCount: summary['activeTablesCount'] as int? ?? 0,
          totalTablesCount: summary['totalTables'] as int? ?? 0,
          todayRevenue: (summary['todayRevenue'] as num?)?.toDouble() ?? 0,
          todayCash: (summary['todayCash'] as num?)?.toDouble() ?? 0,
          liveTables: parsedTables,
          lastSyncTime: DateTime.now(),
          errorMessage: null,
        );
      }
    } catch (e) {
      debugPrint("⚠️ [LanBossClient] Yangilashda xatolik: $e");
    }
  }

  /// Wi-Fi tarmog'idagi Arena POS ni avtomatik qidirish (Auto-Discovery)
  Future<String?> autoDiscoverCashier({int port = 8080}) async {
    state = state.copyWith(isScanning: true, errorMessage: null);

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      String? mySubnet;
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && !addr.address.startsWith('127.')) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              mySubnet = '${parts[0]}.${parts[1]}.${parts[2]}';
              break;
            }
          }
        }
        if (mySubnet != null) break;
      }

      if (mySubnet != null) {
        // Mahalliy subnetdagi asosiy IP larni tezkor tekshirish
        for (int i = 1; i <= 254; i++) {
          final targetIp = '$mySubnet.$i';
          try {
            final testUrl = Uri.parse('http://$targetIp:$port/api/ping');
            final res = await http.get(testUrl).timeout(const Duration(milliseconds: 150));
            if (res.statusCode == 200) {
              final data = jsonDecode(res.body);
              if (data['app'] == 'Arena POS') {
                state = state.copyWith(isScanning: false);
                await connectToCashier(targetIp, port: port);
                return targetIp;
              }
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint("⚠️ [LanBossClient] Skanerlashda xatolik: $e");
    }

    state = state.copyWith(isScanning: false);
    return null;
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      refreshLiveStatus();
    });
  }

  void disconnect() {
    _pollTimer?.cancel();
    _pollTimer = null;
    state = const LanBossState();
  }
}

final lanBossClientProvider =
    NotifierProvider<LanBossClientNotifier, LanBossState>(LanBossClientNotifier.new);
