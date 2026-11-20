// ============================================
// Arena — Xodimlar va Kassirlar Modeli
// Har bir xodim uchun ID, Ism, Telefon, Rol va 4 xonali PIN
// ============================================

enum StaffRole {
  owner,
  cashier;

  String get displayName {
    switch (this) {
      case StaffRole.owner:
        return 'Boshliq (Ega)';
      case StaffRole.cashier:
        return 'Kassir';
    }
  }

  String get badgeLabel {
    switch (this) {
      case StaffRole.owner:
        return 'BOSHLIQ';
      case StaffRole.cashier:
        return 'KASSIR';
    }
  }

  String get permissionsDescription {
    switch (this) {
      case StaffRole.owner:
        return 'Cheksiz ruxsat: Barcha sozlamalar, narxlar, ombor, xodimlar va to\'liq hisobotlar';
      case StaffRole.cashier:
        return 'Cheklangan ruxsat: Maydonlar va o\'yinlar, do\'kon POS savdosi va qarz yozish';
    }
  }
}

class StaffMember {
  final String id;
  final String name;
  final String phone;
  final StaffRole role;
  final String pin; // 4 xonali PIN-kod
  final bool isActive;
  final DateTime createdAt;

  const StaffMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.pin,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isOwner => role == StaffRole.owner;
  bool get isCashier => role == StaffRole.cashier;

  StaffMember copyWith({
    String? id,
    String? name,
    String? phone,
    StaffRole? role,
    String? pin,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return StaffMember(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      pin: pin ?? this.pin,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'role': role.name,
        'pin': pin,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String? ?? '',
      role: json['role'] == 'owner' ? StaffRole.owner : StaffRole.cashier,
      pin: json['pin'] as String,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
