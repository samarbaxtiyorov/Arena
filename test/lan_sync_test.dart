// ============================================
// Arena — LAN Server Testlari
// ============================================

import 'package:flutter_test/flutter_test.dart';
import 'package:arena/core/services/lan_pos_server.dart';

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
    });
  });
}
