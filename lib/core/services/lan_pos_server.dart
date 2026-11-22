// ============================================
// Arena POS — Lokal Tarmoq Serveri (LAN Master Server)
// dart:io HttpServer orqali ishlaydi (Hech qanday internet shart emas!)
// Arena Boss bilan bitta Wi-Fi tarmog'ida jonli ma'lumot almashadi
// ============================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/database_providers.dart';
import '../auth/providers/business_account_provider.dart';
import '../config/app_mode.dart';
import 'smart_light_service.dart';

class LanServerState {
  final bool isRunning;
  final String? localIp;
  final int port;
  final int activeConnections;
  final DateTime? startedAt;

  const LanServerState({
    this.isRunning = false,
    this.localIp,
    this.port = 8080,
    this.activeConnections = 0,
    this.startedAt,
  });

  LanServerState copyWith({
    bool? isRunning,
    String? localIp,
    int? port,
    int? activeConnections,
    DateTime? startedAt,
  }) {
    return LanServerState(
      isRunning: isRunning ?? this.isRunning,
      localIp: localIp ?? this.localIp,
      port: port ?? this.port,
      activeConnections: activeConnections ?? this.activeConnections,
      startedAt: startedAt ?? this.startedAt,
    );
  }
}

class LanPosServerNotifier extends Notifier<LanServerState> {
  HttpServer? _server;

  @override
  LanServerState build() {
    ref.onDispose(() {
      stopServer();
    });
    return const LanServerState();
  }

  /// Lokal Wi-Fi IP manzilini aniqlash (Masalan: 192.168.1.150)
  Future<String?> getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && !addr.address.startsWith('127.')) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      debugPrint("⚠️ [LanPosServer] IP aniqlashda xatolik: $e");
    }
    return null;
  }

  /// Serverni ishga tushirish (Port 8080)
  Future<void> startServer({int port = 8080}) async {
    if (_server != null) return;

    try {
      final ip = await getLocalIp();
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port, shared: true);

      state = state.copyWith(
        isRunning: true,
        localIp: ip ?? '127.0.0.1',
        port: port,
        startedAt: DateTime.now(),
      );

      debugPrint("🚀 [LanPosServer] Arena POS Server ishga tushdi: http://${state.localIp}:$port");

      _server!.listen((HttpRequest request) async {
        _handleRequest(request);
      });
    } catch (e) {
      debugPrint("❌ [LanPosServer] Serverni yoqishda xatolik: $e");
      state = state.copyWith(isRunning: false);
    }
  }

  /// Serverni to'xtatish
  Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
    state = const LanServerState();
    debugPrint("🛑 [LanPosServer] Arena POS Server to'xtatildi.");
  }

  /// So'rovlarni qayta ishlash
  void _handleRequest(HttpRequest request) async {
    // CORS sarlavhalari (Boss ilovasi istalgan qurilmadan kirishi uchun)
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');
    request.response.headers.contentType = ContentType.json;

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    final path = request.uri.path;

    try {
      if (path == '/api/ping') {
        _respondJson(request, {
          'status': 'ok',
          'app': 'Arena POS',
          'mode': 'pos',
          'ip': state.localIp,
          'timestamp': DateTime.now().toIso8601String(),
        });
        return;
      }

      if (path == '/api/summary') {
        final business = ref.read(businessAccountProvider).activeAccount;
        final db = ref.read(appDatabaseProvider);

        final tables = await (db.select(db.clubTables)..where((t) => t.isActive.equals(true))).get();
        final activeSessions = await (db.select(db.sessions)..where((s) => s.status.equals('active'))).get();
        final todayCashTotal = await db.cashRecordsDao.getTodayTotal();
        final todaySessions = await db.sessionsDao.getTodaySessions();

        int todayGameTotal = 0;
        for (final s in todaySessions) {
          todayGameTotal += s.totalAmount ?? 0;
        }

        _respondJson(request, {
          'venueName': business?.venueName ?? 'Bilyard Arena',
          'businessId': business?.id ?? '',
          'totalTables': tables.length,
          'activeTablesCount': activeSessions.length,
          'todayRevenue': todayCashTotal + todayGameTotal,
          'todayCash': todayCashTotal,
          'todayGamesSum': todayGameTotal,
          'timestamp': DateTime.now().toIso8601String(),
        });
        return;
      }

      if (path == '/api/tables') {
        final db = ref.read(appDatabaseProvider);
        final tables = await (db.select(db.clubTables)..where((t) => t.isActive.equals(true))).get();
        final activeSessions = await (db.select(db.sessions)..where((s) => s.status.equals('active'))).get();

        final sessionMap = {for (final s in activeSessions) s.tableId: s};

        final result = tables.map((t) {
          final s = sessionMap[t.id];
          return {
            'id': t.id,
            'name': t.name,
            'category': t.type,
            'hourlyRate': t.pricePerHour,
            'isActive': s != null,
            'session': s == null
                ? null
                : {
                    'id': s.id,
                    'startedAt': s.startedAt.toIso8601String(),
                    'notes': s.notes,
                    'status': s.status,
                  },
          };
        }).toList();

        _respondJson(request, {'tables': result});
        return;
      }

      if (path == '/api/light/toggle' && request.method == 'POST') {
        final content = await utf8.decoder.bind(request).join();
        final data = jsonDecode(content);
        final channel = data['channel'] as int? ?? 1;
        final lightState = data['state'] as bool? ?? true;

        final smart = ref.read(smartLightServiceProvider);
        final success = await smart.setLightState(channel: channel, state: lightState);

        _respondJson(request, {'success': success, 'channel': channel, 'state': lightState});
        return;
      }

      // Noma'lum marshrut
      request.response.statusCode = HttpStatus.notFound;
      _respondJson(request, {'error': 'Not found: $path'});
    } catch (e) {
      debugPrint("❌ [LanPosServer] So'rov xatosi: $e");
      request.response.statusCode = HttpStatus.internalServerError;
      _respondJson(request, {'error': e.toString()});
    }
  }

  void _respondJson(HttpRequest request, Map<String, dynamic> data) async {
    request.response.write(jsonEncode(data));
    await request.response.close();
  }
}

final lanPosServerProvider =
    NotifierProvider<LanPosServerNotifier, LanServerState>(LanPosServerNotifier.new);
