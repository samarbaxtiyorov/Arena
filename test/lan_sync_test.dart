// ============================================
// Arena — LAN Sync (POS Server va Boss Client) Testlari
// ============================================

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arena/core/services/lan_pos_server.dart';
import 'package:arena/core/services/lan_boss_client.dart';

void main() {
  group('LAN Sync Models and States Tests', () {
    test('LanServerState defaults and copyWith work accurately', () {
      const state = LanServerState();
      expect(state.isRunning, isFalse);
      expect(state.port, equals(8080));
      expect(state.localIp, isNull);

      final updated = state.copyWith(
        isRunning: true,
        localIp: '192.168.1.150',
        port: 8080,
      );

      expect(updated.isRunning, isTrue);
      expect(updated.localIp, equals('192.168.1.150'));
      expect(updated.port, equals(8080));
    });

    test('LanBossState defaults and copyWith work accurately', () {
      const state = LanBossState();
      expect(state.isConnected, isFalse);
      expect(state.isScanning, isFalse);
      expect(state.todayRevenue, equals(0));
      expect(state.liveTables, isEmpty);

      final updated = state.copyWith(
        isConnected: true,
        cashierIp: '192.168.1.150',
        venueName: 'Test Arena',
        todayRevenue: 250000,
        activeTablesCount: 3,
        totalTablesCount: 5,
        liveTables: [
          {'id': '1', 'name': 'Stol 1', 'isActive': true},
          {'id': '2', 'name': 'Stol 2', 'isActive': false},
        ],
      );

      expect(updated.isConnected, isTrue);
      expect(updated.cashierIp, equals('192.168.1.150'));
      expect(updated.venueName, equals('Test Arena'));
      expect(updated.todayRevenue, equals(250000));
      expect(updated.activeTablesCount, equals(3));
      expect(updated.liveTables.length, equals(2));
    });

    test('LanBossClientNotifier disconnect resets state cleanly', () {
      final container = ProviderContainer();
      final notifier = container.read(lanBossClientProvider.notifier);

      notifier.disconnect();
      final state = container.read(lanBossClientProvider);
      expect(state.isConnected, isFalse);
      expect(state.cashierIp, isNull);
    });
  });
}
