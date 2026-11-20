import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/auth/providers/business_account_provider.dart';
import '../models/business_settings.dart';

class BusinessSettingsNotifier extends Notifier<BusinessSettings> {
  String get _storageKey {
    final activeVenue = ref.read(businessAccountProvider).activeAccount;
    final id = activeVenue?.id ?? 'default';
    return 'business_settings_$id';
  }

  @override
  BusinessSettings build() {
    _loadSettings();
    final activeVenue = ref.read(businessAccountProvider).activeAccount;
    return BusinessSettings(
      receiptTitle: activeVenue?.venueName ?? 'Arena Sport & Game POS',
      cardHolder: activeVenue?.ownerName ?? '',
    );
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        state = BusinessSettings.fromJson(jsonStr);
      }
    } catch (_) {}
  }

  Future<void> reload() async {
    await _loadSettings();
  }

  Future<void> saveSettings(BusinessSettings newSettings) async {
    state = newSettings;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, newSettings.toJson());
    } catch (_) {}
  }

  Future<void> updateCardSettings({
    required bool enabled,
    required String cardNumber,
    required String cardHolder,
    required String bankName,
  }) async {
    final updated = state.copyWith(
      cardPaymentEnabled: enabled,
      cardNumber: cardNumber.trim(),
      cardHolder: cardHolder.trim(),
      bankName: bankName.trim(),
    );
    await saveSettings(updated);
  }

  Future<void> updateSmartLightSettings({
    required bool enabled,
    required String type,
    required String tuyaAccessId,
    required String tuyaAccessSecret,
    required String tuyaEndpoint,
    required String tuyaDeviceId,
    required String localRelayIp,
  }) async {
    final updated = state.copyWith(
      smartLightsEnabled: enabled,
      smartLightType: type,
      tuyaAccessId: tuyaAccessId.trim(),
      tuyaAccessSecret: tuyaAccessSecret.trim(),
      tuyaEndpoint: tuyaEndpoint.trim(),
      tuyaDeviceId: tuyaDeviceId.trim(),
      localRelayIp: localRelayIp.trim(),
    );
    await saveSettings(updated);
  }

  Future<void> setTableRelayChannel(String tableId, int channel) async {
    final currentChannels = Map<String, int>.from(state.tableRelayChannels);
    currentChannels[tableId] = channel;
    final updated = state.copyWith(tableRelayChannels: currentChannels);
    await saveSettings(updated);
  }

  Future<void> updatePrinterSettings({
    required bool enabled,
    required String paperFormat,
    required String receiptTitle,
    required String receiptFooter,
    required bool autoPrintReceipt,
  }) async {
    final updated = state.copyWith(
      printerEnabled: enabled,
      paperFormat: paperFormat,
      receiptTitle: receiptTitle.trim(),
      receiptFooter: receiptFooter.trim(),
      autoPrintReceipt: autoPrintReceipt,
    );
    await saveSettings(updated);
  }

  Future<void> recordSyncTime(DateTime time) async {
    final updated = state.copyWith(lastSyncTime: time);
    await saveSettings(updated);
  }
}

final businessSettingsProvider =
    NotifierProvider<BusinessSettingsNotifier, BusinessSettings>(
        BusinessSettingsNotifier.new);
