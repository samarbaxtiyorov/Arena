import 'dart:convert';

class SubscriptionModel {
  final String venueId;
  final String planName;
  final DateTime expiryDate;
  final int pricePerTablePerMonth;
  final int licensedTablesCount; // Litsenziya bo'yicha ruxsat berilgan stollar soni
  final DateTime? lastPaymentDate;
  final int? lastPaymentAmount;
  final String? lastPaymentReference;

  const SubscriptionModel({
    required this.venueId,
    this.planName = 'Arena Professional',
    required this.expiryDate,
    this.pricePerTablePerMonth = 100000,
    this.licensedTablesCount = 5,
    this.lastPaymentDate,
    this.lastPaymentAmount,
    this.lastPaymentReference,
  });

  bool get isExpired => DateTime.now().isAfter(expiryDate);

  int get daysRemaining {
    final diff = expiryDate.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  String get statusBadge => isExpired ? "MUDDATI O'TGAN" : "FAOL";

  SubscriptionModel copyWith({
    String? venueId,
    String? planName,
    DateTime? expiryDate,
    int? pricePerTablePerMonth,
    int? licensedTablesCount,
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
              DateTime.now().add(const Duration(days: 30))
          : DateTime.now().add(const Duration(days: 30)),
      pricePerTablePerMonth: (map['pricePerTablePerMonth'] as num?)?.toInt() ?? 100000,
      licensedTablesCount: (map['licensedTablesCount'] as num?)?.toInt() ?? 5,
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
