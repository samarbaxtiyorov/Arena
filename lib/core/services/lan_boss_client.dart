// ============================================
// Arena Boss — Lokal Tarmoq Klienti (LAN Boss Client)
// Uy Wi-Fi yoki klub tarmog'ida Arena POS bilan to'g'ridan-to'g'ri bog'lanadi
// Internetsiz kassa va bilyard stollarini jonli kuzatish
// UDP Discovery va Tezkor Parallel Subnet Scanner
// ============================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _prefCashierIpKey = 'lan_last_cashier_ip';
  Timer? _pollTimer;

  @override
  LanBossState build() {
    ref.onDispose(() {
      _pollTimer?.cancel();
    });
    return const LanBossState();
  }

  /// Avval saqlangan kassa IP manzilini olish
  Future<String?> getSavedCashierIp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefCashierIpKey);
    } catch (_) {
      return null;
    }
  }

  /// Kassa kompyuteriga to'g'ridan-to'g'ri ulanish
  Future<bool> connectToCashier(String ip, {int port = 8080}) async {
    final cleanIp = ip.trim().replaceAll('http://', '').replaceAll('/', '');
    if (cleanIp.isEmpty) return false;

    try {
      final pingUrl = Uri.parse('http://$cleanIp:$port/api/ping');
      final res = await http.get(pingUrl).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['app'] == 'Arena POS') {
          // IP manzilni saqlab qo'yish
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_prefCashierIpKey, cleanIp);
          } catch (_) {}

          state = state.copyWith(
            isConnected: true,
            cashierIp: cleanIp,
            port: port,
            venueName: data['venueName'] as String?,
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

  /// Wi-Fi tarmog'idagi Arena POS ni avtomatik qidirish (UDP Beacon + Parallel Subnet Scan)
  Future<String?> autoDiscoverCashier({int port = 8080}) async {
    state = state.copyWith(isScanning: true, errorMessage: null);

    // 1-QADAM: Avval saqlangan oxirgi IP ni sinab ko'rish (0 soniya)
    final savedIp = await getSavedCashierIp();
    if (savedIp != null && savedIp.isNotEmpty) {
      try {
        final testUrl = Uri.parse('http://$savedIp:$port/api/ping');
        final res = await http.get(testUrl).timeout(const Duration(milliseconds: 600));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['app'] == 'Arena POS') {
            state = state.copyWith(isScanning: false);
            await connectToCashier(savedIp, port: port);
            return savedIp;
          }
        }
      } catch (_) {}
    }

    // 2-QADAM: UDP Discovery orqali qidirish (Port 8888) — 1 soniya
    try {
      final udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      udpSocket.broadcastEnabled = true;

      final completer = Completer<String?>();

      udpSocket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final dg = udpSocket.receive();
          if (dg != null) {
            try {
              final text = utf8.decode(dg.data).trim();
              final data = jsonDecode(text);
              if (data['app'] == 'Arena POS' && data['ip'] != null) {
                if (!completer.isCompleted) {
                  completer.complete(data['ip'] as String);
                }
              }
            } catch (_) {}
          }
        }
      });

      // Broadcast xabari yuborish
      final pingBytes = utf8.encode('ARENA_DISCOVER');
      udpSocket.send(pingBytes, InternetAddress('255.255.255.255'), 8888);

      // 1.2 soniya kutish
      final discoveredIp = await completer.future.timeout(
        const Duration(milliseconds: 1200),
        onTimeout: () => null,
      );
      udpSocket.close();

      if (discoveredIp != null) {
        state = state.copyWith(isScanning: false);
        await connectToCashier(discoveredIp, port: port);
        return discoveredIp;
      }
    } catch (e) {
      debugPrint("⚠️ [LanBossClient] UDP qidiruv xatosi: $e");
    }

    // 3-QADAM: Parallel tezkor Subnet Scan (Guruhma-guruh 30 tadan parallel)
    try {
      final subnet = await _detectLocalSubnet();
      if (subnet != null) {
        // 1..254 IP manzillarini 30 tadan guruhlarga bo'lib parallel tekshirish
        final allIps = List.generate(254, (i) => '$subnet.${i + 1}');
        const batchSize = 30;

        for (int i = 0; i < allIps.length; i += batchSize) {
          final chunk = allIps.sublist(i, (i + batchSize > allIps.length) ? allIps.length : i + batchSize);

          final results = await Future.wait(
            chunk.map((ip) => _pingCandidate(ip, port)),
          );

          for (final found in results) {
            if (found != null) {
              state = state.copyWith(isScanning: false);
              await connectToCashier(found, port: port);
              return found;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("⚠️ [LanBossClient] Subnet skanerlash xatosi: $e");
    }

    state = state.copyWith(
      isScanning: false,
      errorMessage: "Wi-Fi tarmog'ida Arena POS topilmadi. Notebookdagi IP manzilni qo'lda kiriting.",
    );
    return null;
  }

  Future<String?> _pingCandidate(String ip, int port) async {
    try {
      final uri = Uri.parse('http://$ip:$port/api/ping');
      final res = await http.get(uri).timeout(const Duration(milliseconds: 350));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['app'] == 'Arena POS') {
          return ip;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _detectLocalSubnet() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        final name = iface.name.toLowerCase();
        if (name.contains('docker') || name.contains('veth') || name.contains('tun')) continue;

        for (final addr in iface.addresses) {
          if (!addr.isLoopback && (addr.address.startsWith('192.168.') || addr.address.startsWith('10.'))) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              return '${parts[0]}.${parts[1]}.${parts[2]}';
            }
          }
        }
      }
    } catch (_) {}
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
