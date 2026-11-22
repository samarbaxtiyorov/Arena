// ============================================
// Arena — Dastur Rejimi (POS vs Boss) Testlari
// Arena POS: Kassir ish o'rni (Managementdan to'liq ajratilgan)
// ============================================

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arena/core/config/app_mode.dart';

void main() {
  group('AppMode and Dual App Architecture Tests', () {
    test('Default mode is AppMode.pos (Arena POS Kassa rejimi)', () {
      final container = ProviderContainer();
      final mode = container.read(appModeProvider);
      expect(mode, equals(AppMode.pos));
      expect(container.read(appModeProvider.notifier).isPos, isTrue);
      expect(container.read(appModeProvider.notifier).isBoss, isFalse);
    });

    test('Mode can be switched cleanly between POS and Boss', () {
      final container = ProviderContainer();
      final notifier = container.read(appModeProvider.notifier);

      expect(notifier.isPos, isTrue);

      notifier.setMode(AppMode.boss);
      expect(container.read(appModeProvider), equals(AppMode.boss));
      expect(notifier.isBoss, isTrue);
      expect(notifier.isPos, isFalse);

      notifier.setMode(AppMode.pos);
      expect(container.read(appModeProvider), equals(AppMode.pos));
      expect(notifier.isPos, isTrue);
    });
  });
}
