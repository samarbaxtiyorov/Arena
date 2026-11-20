import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/auth/providers/business_account_provider.dart';
import '../models/subscription_model.dart';

class SubscriptionNotifier extends Notifier<SubscriptionModel> {
  String get _storageKey {
    final activeVenue = ref.read(businessAccountProvider).activeAccount;
    final id = activeVenue?.id ?? 'default';
    return 'arena_subscription_$id';
  }

  @override
  SubscriptionModel build() {
    _loadFromPrefs();
    final activeVenue = ref.read(businessAccountProvider).activeAccount;
    // Standart: 2026-yil 31-dekabrgacha yoki 30 kunlik faol obuna
    return SubscriptionModel(
      venueId: activeVenue?.id ?? 'default',
      expiryDate: DateTime(2026, 12, 31, 23, 59, 59),
    );
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        state = SubscriptionModel.fromJson(jsonStr);
      }
    } catch (_) {}
  }

  Future<void> reload() async {
    await _loadFromPrefs();
  }

  Future<void> save(SubscriptionModel model) async {
    state = model;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, model.toJson());
    } catch (_) {}
  }

  /// To'lov tasdiqlanganda obunani uzaytirish
  Future<void> extendSubscription({
    required int months,
    required int paidAmount,
    required String reference,
  }) async {
    final now = DateTime.now();
    final currentExpiry = state.expiryDate;
    final baseDate = currentExpiry.isAfter(now) ? currentExpiry : now;
    final newExpiry = baseDate.add(Duration(days: months * 30));

    final updated = state.copyWith(
      expiryDate: newExpiry,
      lastPaymentDate: now,
      lastPaymentAmount: paidAmount,
      lastPaymentReference: reference,
    );

    await save(updated);
  }

  /// Tarif narxini hisoblash
  static int calculateAmount({
    required int tablesCount,
    required int months,
  }) {
    final effectiveTables = tablesCount > 0 ? tablesCount : 1;
    final baseMonthly = effectiveTables * 100000;

    switch (months) {
      case 1:
        return baseMonthly * 1;
      case 3:
        // 5% chegirma
        return ((baseMonthly * 3) * 0.95).round();
      case 6:
        // 10% chegirma
        return ((baseMonthly * 6) * 0.90).round();
      case 12:
        // 20% chegirma
        return ((baseMonthly * 12) * 0.80).round();
      default:
        return baseMonthly * months;
    }
  }
}

final subscriptionProvider =
    NotifierProvider<SubscriptionNotifier, SubscriptionModel>(SubscriptionNotifier.new);
