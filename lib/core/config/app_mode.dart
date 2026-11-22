// ============================================
// Arena — Dastur Rejimi (POS vs BOSS)
// Arena POS: Kassir / Marker ish o'rni (Toza Kassa Dasturi)
// Arena Boss: Klub egasi uchun Boshqaruv Markazi & Jonli Radar
// Qurilma xotirasida (SharedPreferences) doimiy saqlanadi
// ============================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppMode {
  /// Arena POS — Kassir va bar xodimi uchun maxsus kassa dasturi
  /// (Faqat Stollar, Bar/Magazin, Kassa/Cheklar va Nasiya)
  /// Boshqaruv markazi va sozlamalar butunlay olib tashlangan.
  pos,

  /// Arena Boss — Klub rahbari / Admin uchun Boshqaruv Markazi
  /// (Jonli Radar, Analitika, Xodimlar, Sozlamalar, Aqlli Chiroqlar, Tariflar)
  /// Kassir ishiga va cheklarga aralashmaydi.
  boss,
}

class AppModeNotifier extends Notifier<AppMode> {
  static const String prefKey = 'arena_device_mode';
  static SharedPreferences? initialPrefs;
  final AppMode? _initialMode;

  AppModeNotifier({AppMode? initialMode}) : _initialMode = initialMode;

  @override
  AppMode build() {
    if (_initialMode != null) {
      return _initialMode!;
    }
    final saved = initialPrefs?.getString(prefKey);
    if (saved == 'boss') return AppMode.boss;
    if (saved == 'pos') return AppMode.pos;
    return AppMode.pos;
  }

  void setMode(AppMode mode) {
    state = mode;
    initialPrefs?.setString(prefKey, mode == AppMode.boss ? 'boss' : 'pos');
  }

  void toggleMode() {
    final next = state == AppMode.pos ? AppMode.boss : AppMode.pos;
    setMode(next);
  }

  bool get isPos => state == AppMode.pos;
  bool get isBoss => state == AppMode.boss;
}

class BossModeNotifier extends AppModeNotifier {
  BossModeNotifier() : super(initialMode: AppMode.boss);

  @override
  AppMode build() => AppMode.boss;
}

final appModeProvider = NotifierProvider<AppModeNotifier, AppMode>(AppModeNotifier.new);
