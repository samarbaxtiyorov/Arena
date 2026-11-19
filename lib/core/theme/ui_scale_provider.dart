// ============================================
// Arena — UI Scale & Shrift Kattaligi Sozlamasi
// 3 xil ko'rinish darajasi: Kichik, O'rtacha, Katta
// SharedPreferences orqali avtomatik saqlanadi
// ============================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UiScale {
  small(
    name: 'Kichik',
    subtitle: 'Kompakt, zamonaviy va ixcham (Tavsiya etiladi)',
    textScale: 0.86,
    bannerHeight: 125.0,
    cardPadding: 12.0,
    buttonHeight: 40.0,
    headerAvatarSize: 40.0,
  ),
  medium(
    name: "O'rtacha",
    subtitle: "Muvozanatli standart ko'rinish",
    textScale: 1.0,
    bannerHeight: 142.0,
    cardPadding: 14.0,
    buttonHeight: 44.0,
    headerAvatarSize: 44.0,
  ),
  large(
    name: 'Katta',
    subtitle: "Katta shriftlar (Ko'z o'tmaydiganlar uchun)",
    textScale: 1.16,
    bannerHeight: 160.0,
    cardPadding: 16.0,
    buttonHeight: 48.0,
    headerAvatarSize: 48.0,
  );

  final String name;
  final String subtitle;
  final double textScale;
  final double bannerHeight;
  final double cardPadding;
  final double buttonHeight;
  final double headerAvatarSize;

  const UiScale({
    required this.name,
    required this.subtitle,
    required this.textScale,
    required this.bannerHeight,
    required this.cardPadding,
    required this.buttonHeight,
    required this.headerAvatarSize,
  });
}

class UiScaleNotifier extends Notifier<UiScale> {
  static const _prefKey = 'arena_ui_scale';

  @override
  UiScale build() {
    _loadFromPrefs();
    // Standart qilib Kichik (ixcham, zamonaviy) tanlanadi
    return UiScale.small;
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIndex = prefs.getInt(_prefKey);
      if (savedIndex != null && savedIndex >= 0 && savedIndex < UiScale.values.length) {
        state = UiScale.values[savedIndex];
      }
    } catch (_) {}
  }

  Future<void> setScale(UiScale scale) async {
    state = scale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKey, scale.index);
    } catch (_) {}
  }
}

final uiScaleProvider =
    NotifierProvider<UiScaleNotifier, UiScale>(UiScaleNotifier.new);
