// ============================================
// Arena — Auth & Foydalanuvchi Roli (Riverpod)
// Boshliq (Owner) va Kassir (Cashier)
// ============================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  // PIN tekshirish: 7777 - Ega, 1111 - Kassir
  bool verifyPin(String pin) {
    if (pin == '7777') {
      state = state.copyWith(
        isAuthenticated: true,
        role: UserRole.owner,
        userName: 'Biznes egasi',
      );
      return true;
    } else if (pin == '1111') {
      state = state.copyWith(
        isAuthenticated: true,
        role: UserRole.cashier,
        userName: 'Kassir Samar',
      );
      return true;
    }
    return false;
  }

  void switchRole(UserRole role) {
    state = state.copyWith(
      role: role,
      userName: role == UserRole.owner ? 'Biznes egasi' : 'Kassir',
    );
  }

  void logout() {
    state = state.copyWith(isAuthenticated: false);
  }

  void login() {
    state = state.copyWith(isAuthenticated: true);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
