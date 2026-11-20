import 'dart:convert';

class SubscriptionModel {
  final String venueId;
  final String planName;
  final DateTime expiryDate;
  final int pricePerTablePerMonth;
  final int licensedTablesCount; // Litsenziya bo'yicha ruxsat berilgan stollar soni
  final bool isTrial; // 3 kunlik bepul sinov litsenziyasi
  final DateTime? lastPaymentDate;
  final int? lastPaymentAmount;
  final String? lastPaymentReference;

  const SubscriptionModel({
    required this.venueId,
    this.planName = 'Arena Professional',
    required this.expiryDate,
    this.pricePerTablePerMonth = 100000,
    this.licensedTablesCount = 5,
    this.isTrial = false,
    this.lastPaymentDate,
    this.lastPaymentAmount,
    this.lastPaymentReference,
  });

  bool get isExpired => DateTime.now().isAfter(expiryDate);
  bool get isTrialActive => isTrial && !isExpired;

  int get daysRemaining {
    final diff = expiryDate.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  int get hoursRemaining {
    final diff = expiryDate.difference(DateTime.now()).inHours;
    return diff > 0 ? diff : 0;
  }

  String get statusBadge {
    if (isExpired) return "MUDDATI O'TGAN";
    if (isTrial) return "SINOV DAVRI";
    return "FAOL";
  }

  SubscriptionModel copyWith({
    String? venueId,
    String? planName,
    DateTime? expiryDate,
    int? pricePerTablePerMonth,
    int? licensedTablesCount,
    bool? isTrial,
    DateTime? lastPaymentDate,
    int? lastPaymentAmount,
    String? lastPaymentReference,
  }) {
    return SubscriptionModel(
      venueId: venueId ?? this.venueId,
      planName: planName ?? this.planName,
      expiryDate: expiryDate ?? this.expiryDate,
      pricePerTablePerMonth: pricePerTablePerMonth ?? this.pricePerTablePerMonth,
      licensedTablesCount: licensedTablesCount ?? this.licensedTablesCount,
      isTrial: isTrial ?? this.isTrial,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      lastPaymentAmount: lastPaymentAmount ?? this.lastPaymentAmount,
      lastPaymentReference: lastPaymentReference ?? this.lastPaymentReference,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'venueId': venueId,
      'planName': planName,
      'expiryDate': expiryDate.toIso8601String(),
      'pricePerTablePerMonth': pricePerTablePerMonth,
      'licensedTablesCount': licensedTablesCount,
      'isTrial': isTrial,
      'lastPaymentDate': lastPaymentDate?.toIso8601String(),
      'lastPaymentAmount': lastPaymentAmount,
      'lastPaymentReference': lastPaymentReference,
    };
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      venueId: map['venueId'] as String? ?? 'default',
      planName: map['planName'] as String? ?? 'Arena Professional',
      expiryDate: map['expiryDate'] != null
          ? DateTime.tryParse(map['expiryDate'] as String) ??
              DateTime.now().add(const Duration(days: 3))
          : DateTime.now().add(const Duration(days: 3)),
      pricePerTablePerMonth: (map['pricePerTablePerMonth'] as num?)?.toInt() ?? 100000,
      licensedTablesCount: (map['licensedTablesCount'] as num?)?.toInt() ?? 5,
      isTrial: map['isTrial'] as bool? ?? false,
      lastPaymentDate: map['lastPaymentDate'] != null
          ? DateTime.tryParse(map['lastPaymentDate'] as String)
          : null,
      lastPaymentAmount: (map['lastPaymentAmount'] as num?)?.toInt(),
      lastPaymentReference: map['lastPaymentReference'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory SubscriptionModel.fromJson(String source) =>
      SubscriptionModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
