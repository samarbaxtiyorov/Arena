// ============================================
// Arena — Auth & Foydalanuvchi Roli (Riverpod)
// Boshliq (Owner) va Kassir (Cashier)
// ============================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/management/models/staff_member.dart';

enum UserRole { owner, cashier }

class AuthState {
  final bool isAuthenticated;
  final UserRole role;
  final String userName;
  final String phone;
  final String licenseType; // 'VIP', 'PRO', 'START'

  const AuthState({
    this.isAuthenticated = true, // Standart kiritilgan
    this.role = UserRole.owner,
    this.userName = 'Biznes egasi',
    this.phone = '+998 90 000 00 01',
    this.licenseType = 'PREMIUM VIP',
  });

  bool get isOwner => role == UserRole.owner;
  bool get isCashier => role == UserRole.cashier;

  AuthState copyWith({
    bool? isAuthenticated,
    UserRole? role,
    String? userName,
    String? phone,
    String? licenseType,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? this.role,
      userName: userName ?? this.userName,
      phone: phone ?? this.phone,
      licenseType: licenseType ?? this.licenseType,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  // PIN tekshirish: Faqat haqiqiy faol xodimlar ro'yxatidan (Hech qanday backdoor yo'q)
  bool verifyPin(String pin, {List<StaffMember>? staffList}) {
    if (staffList != null && staffList.isNotEmpty) {
      try {
        final match = staffList.firstWhere(
            (s) => s.pin == pin && s.isActive && s.pin.trim().isNotEmpty);
        state = state.copyWith(
          isAuthenticated: true,
          role: match.isOwner ? UserRole.owner : UserRole.cashier,
          userName: match.name,
          phone: match.phone,
        );
        return true;
      } catch (_) {}
    }
    return false;
  }

  void loginAsOwner({required String ownerName, required String phone}) {
    state = state.copyWith(
      isAuthenticated: true,
      role: UserRole.owner,
      userName: ownerName,
      phone: phone,
    );
  }

  void loginAsStaff(StaffMember staff) {
    state = state.copyWith(
      isAuthenticated: true,
      role: staff.isOwner ? UserRole.owner : UserRole.cashier,
      userName: staff.name,
      phone: staff.phone,
    );
  }

  void switchRole(UserRole role) {
    state = state.copyWith(
      role: role,
      userName: role == UserRole.owner ? 'Biznes egasi' : 'Kassir',
    );
  }

  void logout() {
    state = const AuthState(
      isAuthenticated: false,
      role: UserRole.cashier,
      userName: '',
      phone: '',
    );
  }

  void lock() {
    state = state.copyWith(isAuthenticated: false);
  }

  void login() {
    state = state.copyWith(isAuthenticated: true);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

