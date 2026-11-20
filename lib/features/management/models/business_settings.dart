import 'dart:convert';

/// Biznes va Tizim Sozlamalari Modeli
class BusinessSettings {
  // ── Aqlli Chiroqlar (Smart Switch & Tuya / Wi-Fi Relay) ──
  final bool smartLightsEnabled;
  final String smartLightType; // 'local_wifi' yoki 'tuya'
  final String tuyaAccessId;
  final String tuyaAccessSecret;
  final String tuyaEndpoint;
  final String tuyaDeviceId;
  final String localRelayIp; // Wi-Fi tarmoqdagi lokal mini qurilma IP manzili
  final Map<String, int> tableRelayChannels; // tableId -> relay channel (1..16)

  // ── Mijozlar uchun To'lov Kartasi ──
  final bool cardPaymentEnabled;
  final String cardNumber; // Masalan: '8600 1234 5678 9012'
  final String cardHolder; // Masalan: 'SAMAR BAXTIYOROV'
  final String bankName; // Masalan: 'Kapitalbank'

  // ── Chek Printer Sozlamalari ──
  final bool printerEnabled;
  final String paperFormat; // '58mm' yoki '80mm'
  final String receiptTitle; // Muassasa / Chek sarlavhasi
  final String receiptFooter; // Chek osti xabari
  final bool autoPrintReceipt; // To'lov qilinganda avtomatik chek chiqarish

  // ── Bulut va Sinxronizatsiya ──
  final bool autoCloudSync;
  final DateTime? lastSyncTime;

  const BusinessSettings({
    this.smartLightsEnabled = false,
    this.smartLightType = 'local_wifi',
    this.tuyaAccessId = '',
    this.tuyaAccessSecret = '',
    this.tuyaEndpoint = 'https://openapi.tuyaeu.com',
    this.tuyaDeviceId = '',
    this.localRelayIp = '192.168.1.100',
    this.tableRelayChannels = const {},
    this.cardPaymentEnabled = true,
    this.cardNumber = '',
    this.cardHolder = '',
    this.bankName = '',
    this.printerEnabled = true,
    this.paperFormat = '58mm',
    this.receiptTitle = 'Arena Sport & Game POS',
    this.receiptFooter = 'Tashrifingiz uchun rahmat! Yana kutamiz!',
    this.autoPrintReceipt = false,
    this.autoCloudSync = true,
    this.lastSyncTime,
  });

  BusinessSettings copyWith({
    bool? smartLightsEnabled,
    String? smartLightType,
    String? tuyaAccessId,
    String? tuyaAccessSecret,
    String? tuyaEndpoint,
    String? tuyaDeviceId,
    String? localRelayIp,
    Map<String, int>? tableRelayChannels,
    bool? cardPaymentEnabled,
    String? cardNumber,
    String? cardHolder,
    String? bankName,
    bool? printerEnabled,
    String? paperFormat,
    String? receiptTitle,
    String? receiptFooter,
    bool? autoPrintReceipt,
    bool? autoCloudSync,
    DateTime? lastSyncTime,
  }) {
    return BusinessSettings(
      smartLightsEnabled: smartLightsEnabled ?? this.smartLightsEnabled,
      smartLightType: smartLightType ?? this.smartLightType,
      tuyaAccessId: tuyaAccessId ?? this.tuyaAccessId,
      tuyaAccessSecret: tuyaAccessSecret ?? this.tuyaAccessSecret,
      tuyaEndpoint: tuyaEndpoint ?? this.tuyaEndpoint,
      tuyaDeviceId: tuyaDeviceId ?? this.tuyaDeviceId,
      localRelayIp: localRelayIp ?? this.localRelayIp,
      tableRelayChannels: tableRelayChannels ?? this.tableRelayChannels,
      cardPaymentEnabled: cardPaymentEnabled ?? this.cardPaymentEnabled,
      cardNumber: cardNumber ?? this.cardNumber,
      cardHolder: cardHolder ?? this.cardHolder,
      bankName: bankName ?? this.bankName,
      printerEnabled: printerEnabled ?? this.printerEnabled,
      paperFormat: paperFormat ?? this.paperFormat,
      receiptTitle: receiptTitle ?? this.receiptTitle,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      autoPrintReceipt: autoPrintReceipt ?? this.autoPrintReceipt,
      autoCloudSync: autoCloudSync ?? this.autoCloudSync,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'smartLightsEnabled': smartLightsEnabled,
      'smartLightType': smartLightType,
      'tuyaAccessId': tuyaAccessId,
      'tuyaAccessSecret': tuyaAccessSecret,
      'tuyaEndpoint': tuyaEndpoint,
      'tuyaDeviceId': tuyaDeviceId,
      'localRelayIp': localRelayIp,
      'tableRelayChannels': tableRelayChannels,
      'cardPaymentEnabled': cardPaymentEnabled,
      'cardNumber': cardNumber,
      'cardHolder': cardHolder,
      'bankName': bankName,
      'printerEnabled': printerEnabled,
      'paperFormat': paperFormat,
      'receiptTitle': receiptTitle,
      'receiptFooter': receiptFooter,
      'autoPrintReceipt': autoPrintReceipt,
      'autoCloudSync': autoCloudSync,
      'lastSyncTime': lastSyncTime?.toIso8601String(),
    };
  }

  factory BusinessSettings.fromMap(Map<String, dynamic> map) {
    Map<String, int> channels = {};
    if (map['tableRelayChannels'] != null) {
      if (map['tableRelayChannels'] is Map) {
        (map['tableRelayChannels'] as Map).forEach((k, v) {
          channels[k.toString()] = int.tryParse(v.toString()) ?? 1;
        });
      }
    }

    return BusinessSettings(
      smartLightsEnabled: map['smartLightsEnabled'] as bool? ?? false,
      smartLightType: map['smartLightType'] as String? ?? 'local_wifi',
      tuyaAccessId: map['tuyaAccessId'] as String? ?? '',
      tuyaAccessSecret: map['tuyaAccessSecret'] as String? ?? '',
      tuyaEndpoint: map['tuyaEndpoint'] as String? ?? 'https://openapi.tuyaeu.com',
      tuyaDeviceId: map['tuyaDeviceId'] as String? ?? '',
      localRelayIp: map['localRelayIp'] as String? ?? '192.168.1.100',
      tableRelayChannels: channels,
      cardPaymentEnabled: map['cardPaymentEnabled'] as bool? ?? true,
      cardNumber: map['cardNumber'] as String? ?? '',
      cardHolder: map['cardHolder'] as String? ?? '',
      bankName: map['bankName'] as String? ?? '',
      printerEnabled: map['printerEnabled'] as bool? ?? true,
      paperFormat: map['paperFormat'] as String? ?? '58mm',
      receiptTitle: map['receiptTitle'] as String? ?? 'Arena Sport & Game POS',
      receiptFooter: map['receiptFooter'] as String? ?? 'Tashrifingiz uchun rahmat! Yana kutamiz!',
      autoPrintReceipt: map['autoPrintReceipt'] as bool? ?? false,
      autoCloudSync: map['autoCloudSync'] as bool? ?? true,
      lastSyncTime: map['lastSyncTime'] != null ? DateTime.tryParse(map['lastSyncTime'] as String) : null,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory BusinessSettings.fromJson(String source) =>
      BusinessSettings.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
