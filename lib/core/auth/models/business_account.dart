// ============================================
// Arena — Biznes / Muassasa Akkaunti Modeli
// Har bir sport majmuasi / poliya egasi uchun alohida hisob
// ============================================

class BusinessAccount {
  final String id;
  final String venueName; // Muassasa / Majmua nomi (masalan: "Arena Jeyda")
  final String ownerName; // Boshliq ismi (masalan: "Samar Baxtiyorov")
  final String phone;     // Telefon raqami / Login (+998...)
  final String password;  // Akkaunt paroli
  final String ownerPin;  // 4 xonali shaxsiy boshliq PIN-kodi
  final String licenseType;
  final DateTime createdAt;

  const BusinessAccount({
    required this.id,
    required this.venueName,
    required this.ownerName,
    required this.phone,
    required this.password,
    required this.ownerPin,
    this.licenseType = 'PREMIUM VIP',
    required this.createdAt,
  });

  BusinessAccount copyWith({
    String? id,
    String? venueName,
    String? ownerName,
    String? phone,
    String? password,
    String? ownerPin,
    String? licenseType,
    DateTime? createdAt,
  }) {
    return BusinessAccount(
      id: id ?? this.id,
      venueName: venueName ?? this.venueName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      ownerPin: ownerPin ?? this.ownerPin,
      licenseType: licenseType ?? this.licenseType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'venueName': venueName,
        'ownerName': ownerName,
        'phone': phone,
        'password': password,
        'ownerPin': ownerPin,
        'licenseType': licenseType,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BusinessAccount.fromJson(Map<String, dynamic> json) {
    return BusinessAccount(
      id: json['id'] as String,
      venueName: json['venueName'] as String? ?? 'Arena Majmuasi',
      ownerName: json['ownerName'] as String? ?? 'Biznes Egasi',
      phone: json['phone'] as String? ?? '',
      password: json['password'] as String? ?? '',
      ownerPin: json['ownerPin'] as String? ?? '7777',
      licenseType: json['licenseType'] as String? ?? 'PREMIUM VIP',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
