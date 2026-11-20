// ============================================
// Arena — Biznes / Muassasa Akkauntlari Provideri
// Multi-tenant boshqaruv: har bir klub egasi o'z hisobiga ega
// ============================================

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/business_account.dart';

const String _accountsPrefKey = 'arena_business_accounts_v2';
const String _activeAccountIdPrefKey = 'arena_active_account_id_v2';
const String _isLoggedOutPrefKey = 'arena_business_logged_out_v2';

final defaultInitialAccounts = [
  BusinessAccount(
    id: 'samar-arena',
    venueName: 'Arena Sport Majmuasi',
    ownerName: 'Samar Baxtiyorov',
    phone: '+998 90 000 00 01',
    password: '123',
    ownerPin: '7777',
    licenseType: 'PREMIUM VIP',
    createdAt: DateTime(2026, 1, 1),
  ),
  BusinessAccount(
    id: 'alisher-arena',
    venueName: 'Chempion Arena',
    ownerName: 'Alisher Baxtiyorov',
    phone: '+998 91 000 00 02',
    password: '123',
    ownerPin: '8888',
    licenseType: 'PREMIUM VIP',
    createdAt: DateTime(2026, 1, 1),
  ),
];

class BusinessAccountState {
  final List<BusinessAccount> accounts;
  final BusinessAccount? activeAccount;
  final bool isLoggedOut;
  final bool isLoading;

  const BusinessAccountState({
    this.accounts = const [],
    this.activeAccount,
    this.isLoggedOut = false,
    this.isLoading = false,
  });

  bool get hasActiveAccount => activeAccount != null && !isLoggedOut;

  BusinessAccountState copyWith({
    List<BusinessAccount>? accounts,
    BusinessAccount? activeAccount,
    bool? isLoggedOut,
    bool? isLoading,
    bool clearActive = false,
  }) {
    return BusinessAccountState(
      accounts: accounts ?? this.accounts,
      activeAccount: clearActive ? null : (activeAccount ?? this.activeAccount),
      isLoggedOut: isLoggedOut ?? this.isLoggedOut,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class BusinessAccountNotifier extends Notifier<BusinessAccountState> {
  @override
  BusinessAccountState build() {
    _loadFromPrefs();
    return const BusinessAccountState(isLoading: true);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final rawAccounts = prefs.getString(_accountsPrefKey);
    final isLoggedOut = prefs.getBool(_isLoggedOutPrefKey) ?? false;
    final activeId = prefs.getString(_activeAccountIdPrefKey);

    List<BusinessAccount> list = [];
    if (rawAccounts != null && rawAccounts.trim().isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(rawAccounts) as List<dynamic>;
        list = decoded
            .map((item) =>
                BusinessAccount.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        list = defaultInitialAccounts;
      }
    } else {
      list = defaultInitialAccounts;
      await _saveAccounts(list);
    }

    BusinessAccount? active;
    if (activeId != null) {
      try {
        active = list.firstWhere((a) => a.id == activeId);
      } catch (_) {
        active = list.isNotEmpty ? list.first : null;
      }
    } else {
      active = list.isNotEmpty ? list.first : null;
    }

    state = BusinessAccountState(
      accounts: list,
      activeAccount: active,
      isLoggedOut: isLoggedOut,
      isLoading: false,
    );
  }

  Future<void> _saveAccounts(List<BusinessAccount> list) async {
    final prefs = await SharedPreferences.getInstance();
    final str = jsonEncode(list.map((a) => a.toJson()).toList());
    await prefs.setString(_accountsPrefKey, str);
  }

  Future<bool> registerAccount({
    required String venueName,
    required String ownerName,
    required String phone,
    required String password,
    required String ownerPin,
  }) async {
    final cleanPhone = phone.trim();
    final cleanVenue = venueName.trim();
    final cleanOwner = ownerName.trim();
    final cleanPass = password.trim();
    final cleanPin = ownerPin.trim();

    final currentAccounts = List<BusinessAccount>.from(state.accounts);

    // Telefon raqami band emasligini tekshirish
    if (currentAccounts.any((a) => a.phone == cleanPhone)) {
      return false; // Telefon raqami allaqachon mavjud
    }

    final newAcc = BusinessAccount(
      id: const Uuid().v4(),
      venueName: cleanVenue,
      ownerName: cleanOwner,
      phone: cleanPhone,
      password: cleanPass,
      ownerPin: cleanPin.isNotEmpty ? cleanPin : '7777',
      licenseType: 'PREMIUM VIP',
      createdAt: DateTime.now(),
    );

    final updated = [...currentAccounts, newAcc];
    await _saveAccounts(updated);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeAccountIdPrefKey, newAcc.id);
    await prefs.setBool(_isLoggedOutPrefKey, false);

    state = state.copyWith(
      accounts: updated,
      activeAccount: newAcc,
      isLoggedOut: false,
    );
    return true;
  }

  Future<bool> loginAccount({
    required String phone,
    required String password,
  }) async {
    final cleanPhone = phone.trim();
    final cleanPass = password.trim();

    try {
      final match = state.accounts.firstWhere(
        (a) => a.phone == cleanPhone && a.password == cleanPass,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeAccountIdPrefKey, match.id);
      await prefs.setBool(_isLoggedOutPrefKey, false);

      state = state.copyWith(
        activeAccount: match,
        isLoggedOut: false,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> switchAccount(String accountId) async {
    try {
      final match = state.accounts.firstWhere((a) => a.id == accountId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeAccountIdPrefKey, match.id);
      await prefs.setBool(_isLoggedOutPrefKey, false);

      state = state.copyWith(
        activeAccount: match,
        isLoggedOut: false,
      );
    } catch (_) {}
  }

  Future<void> logoutToAuthScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedOutPrefKey, true);

    state = state.copyWith(
      isLoggedOut: true,
    );
  }

  Future<void> updateAccountInfo({
    required String venueName,
    required String ownerName,
    required String phone,
    String? newPassword,
    String? newOwnerPin,
  }) async {
    if (state.activeAccount == null) return;
    final current = state.activeAccount!;
    final updatedAcc = current.copyWith(
      venueName: venueName.trim(),
      ownerName: ownerName.trim(),
      phone: phone.trim(),
      password: (newPassword != null && newPassword.trim().isNotEmpty)
          ? newPassword.trim()
          : current.password,
      ownerPin: (newOwnerPin != null && newOwnerPin.trim().length == 4)
          ? newOwnerPin.trim()
          : current.ownerPin,
    );

    final updatedList = state.accounts
        .map((a) => a.id == updatedAcc.id ? updatedAcc : a)
        .toList();

    await _saveAccounts(updatedList);
    state = state.copyWith(
      accounts: updatedList,
      activeAccount: updatedAcc,
    );
  }

  Future<bool> deleteAccount(String accountId) async {
    if (state.accounts.length <= 1) return false;
    final updated = state.accounts.where((a) => a.id != accountId).toList();
    await _saveAccounts(updated);

    final prefs = await SharedPreferences.getInstance();
    if (state.activeAccount?.id == accountId) {
      final newActive = updated.first;
      await prefs.setString(_activeAccountIdPrefKey, newActive.id);
      state = state.copyWith(
        accounts: updated,
        activeAccount: newActive,
      );
    } else {
      state = state.copyWith(accounts: updated);
    }
    return true;
  }
}

final businessAccountProvider =
    NotifierProvider<BusinessAccountNotifier, BusinessAccountState>(
        BusinessAccountNotifier.new);
