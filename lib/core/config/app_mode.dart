// ============================================
// Arena — Dastur Rejimi (POS vs BOSS)
// Arena POS: Kassir / Marker ish o'rni (Toza Kassa Dasturi)
// Arena Boss: Klub egasi uchun Boshqaruv Markazi & Analitika
// ============================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppMode {
  /// Arena POS — Kassir va bar xodimi uchun maxsus kassa dasturi
  /// (Faqat Stollar, Bar/Magazin, Kassa/Cheklar va Nasiya)
  /// Boshqaruv markazi va sozlamalar butunlay olib tashlangan.
  pos,

  /// Arena Boss — Klub rahbari / Admin uchun Boshqaruv Markazi
  /// (Analitika, Xodimlar, Sozlamalar, Aqlli Chiroqlar, Tariflar)
  boss,
}

class AppModeNotifier extends Notifier<AppMode> {
  @override
  AppMode build() => AppMode.pos;

  void setMode(AppMode mode) {
    state = mode;
  }

  bool get isPos => state == AppMode.pos;
  bool get isBoss => state == AppMode.boss;
}

final appModeProvider = NotifierProvider<AppModeNotifier, AppMode>(AppModeNotifier.new);

