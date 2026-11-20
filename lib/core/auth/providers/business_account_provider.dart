// ============================================
// Arena — Biznes / Muassasa Akkauntlari Provideri
// Multi-tenant boshqaruv: har bir klub egasi o'z hisobiga ega
// ============================================

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../constants/app_constants.dart';
import '../../utils/security_helper.dart';
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

  static bool matchPhone(String p1, String p2) {
    if (p1.trim().toLowerCase() == p2.trim().toLowerCase()) return true;
    String d1 = p1.replaceAll(RegExp(r'\D'), '');
    String d2 = p2.replaceAll(RegExp(r'\D'), '');
    if (d1.isEmpty || d2.isEmpty) return false;
    if (d1 == d2) return true;

    // 998 davlat kodini tozalash
    if (d1.startsWith('998') && d1.length > 9) {
      d1 = d1.substring(3);
    }
    if (d2.startsWith('998') && d2.length > 9) {
      d2 = d2.substring(3);
    }

    if (d1 == d2) return true;

    // Agar biri ikkinchisining ichida to'liq bo'lsa yoki oxirgi 7-9 xonasi teng bo'lsa
    final minLen = d1.length < d2.length ? d1.length : d2.length;
    if (minLen >= 7) {
      final sub1 = d1.substring(d1.length - minLen);
      final sub2 = d2.substring(d2.length - minLen);
      if (sub1 == sub2) return true;
    }

    return false;
  }

  /// Supabase bulutli bazasidan telefon orqali akkauntni qidirish
  static Future<Map<String, dynamic>?> _fetchCloudAccount(String phone) async {
    final cleanPhone = phone.trim();
    final digitsOnly = cleanPhone.replaceAll(RegExp(r'\D'), '');

    final headers = {
      'apikey': AppConstants.supabaseAnonKey,
      'Authorization': 'Bearer ${AppConstants.supabaseAnonKey}',
      'Content-Type': 'application/json',
    };

    final phoneVariants = <String>{
      cleanPhone,
      if (digitsOnly.isNotEmpty) digitsOnly,
      if (digitsOnly.startsWith('998')) digitsOnly.substring(3),
      if (!cleanPhone.startsWith('+') && digitsOnly.length == 9) '+998$digitsOnly',
      if (cleanPhone.startsWith('+998')) cleanPhone.substring(4).replaceAll(' ', ''),
    };

    for (final variant in phoneVariants) {
      try {
        final encoded = Uri.encodeComponent(variant);
        final url = Uri.parse('${AppConstants.supabaseUrl}/rest/v1/cloud_accounts?phone=eq.$encoded&limit=1');
        final res = await http.get(url, headers: headers).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final list = List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
          if (list.isNotEmpty) return list.first;
        }
      } catch (_) {}
    }

    try {
      final url = Uri.parse('${AppConstants.supabaseUrl}/rest/v1/cloud_accounts?select=*&limit=50');
      final res = await http.get(url, headers: headers).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final list = List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
        for (final row in list) {
          final p = row['phone']?.toString() ?? '';
          if (matchPhone(p, cleanPhone)) {
            return row;
          }
        }
      }
    } catch (_) {}

    return null;
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

    // 1. Mahalliy ro'yxatda bor-yo'qligini tekshirish
    if (currentAccounts.any((a) => matchPhone(a.phone, cleanPhone))) {
      return false; // Telefon raqami allaqachon mavjud
    }

    // 2. Bulutli bazada (Supabase Cloud) bor-yo'qligini tekshirish
    try {
      final cloudMatch = await _fetchCloudAccount(cleanPhone);
      if (cloudMatch != null) {
        return false; // Bulutda bu telefon raqam allaqachon mavjud!
      }
    } catch (_) {}

    final newAcc = BusinessAccount(
      id: const Uuid().v4(),
      venueName: cleanVenue,
      ownerName: cleanOwner,
      phone: cleanPhone,
      password: SecurityHelper.hashPassword(cleanPass),
      ownerPin: cleanPin,
      licenseType: 'PREMIUM VIP',
      createdAt: DateTime.now(),
    );

    // 3. Bulutli bazaga (Supabase) darhol saqlash
    try {
      final headers = {
        'apikey': AppConstants.supabaseAnonKey,
        'Authorization': 'Bearer ${AppConstants.supabaseAnonKey}',
        'Content-Type': 'application/json',
        'Prefer': 'resolution=merge-duplicates,return=representation',
      };
      final cloudUrl = Uri.parse('${AppConstants.supabaseUrl}/rest/v1/cloud_accounts');
      await http.post(
        cloudUrl,
        headers: headers,
        body: jsonEncode({
          'phone': cleanPhone,
          'pin_hash': SecurityHelper.hashPassword(cleanPass),
          'business_id': newAcc.id,
          'business_name': cleanVenue,
          'license_until': DateTime.now().add(const Duration(days: 3)).toUtc().toIso8601String(),
          'is_blocked': false,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 6));
    } catch (_) {}

    final updated = [...currentAccounts, newAcc];
    await _saveAccounts(updated);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeAccountIdPrefKey, newAcc.id);
    await prefs.setBool(_isLoggedOutPrefKey, false);

    // Yangi hisob uchun 3 kunlik bepul sinov litsenziyasini saqlash
    final trialSub = jsonEncode({
      'venueId': newAcc.id,
      'planName': '3 Kunlik Bepul Sinov',
      'expiryDate': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
      'pricePerTablePerMonth': 100000,
      'licensedTablesCount': 10,
      'isTrial': true,
    });
    await prefs.setString('arena_subscription_${newAcc.id}', trialSub);

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

    // 1. Mahalliy SharedPreferences'dan qidirish
    try {
      final match = state.accounts.firstWhere(
        (a) =>
            (matchPhone(a.phone, cleanPhone) || a.phone == cleanPhone) &&
            (SecurityHelper.verifyPassword(cleanPass, a.password) ||
                (a.ownerPin.isNotEmpty && cleanPass == a.ownerPin)),
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
      // Mahalliy hisoblarda topilmadi — Bulutdan qidiramiz!
    }

    // 2. Bulutli bazadan (Supabase Cloud) qidirish (Boshqa telefondan kirilganda)
    try {
      final cloudAccount = await _fetchCloudAccount(cleanPhone);
      if (cloudAccount != null) {
        final pinHash = cloudAccount['pin_hash']?.toString() ?? '';
        final isBlocked = cloudAccount['is_blocked'] as bool? ?? false;

        if (isBlocked) {
          return false;
        }

        // Parolni tekshirish (tuzlangan yoki oddiy xesh)
        if (pinHash.isEmpty || SecurityHelper.verifyPassword(cleanPass, pinHash)) {
          final venueName = cloudAccount['business_name']?.toString() ?? 'Arena Sport';
          final busId = cloudAccount['business_id']?.toString() ?? const Uuid().v4();
          final licenseUntilStr = cloudAccount['license_until']?.toString();

          final importedAcc = BusinessAccount(
            id: busId,
            venueName: venueName,
            ownerName: 'Boshliq',
            phone: cleanPhone,
            password: SecurityHelper.hashPassword(cleanPass),
            ownerPin: cleanPass.length == 4 ? cleanPass : '0000',
            licenseType: 'PREMIUM VIP',
            createdAt: DateTime.now(),
          );

          final updated = [...state.accounts.where((a) => a.id != importedAcc.id), importedAcc];
          await _saveAccounts(updated);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_activeAccountIdPrefKey, importedAcc.id);
          await prefs.setBool(_isLoggedOutPrefKey, false);

          // Bulutdagi litsenziyani yuklash
          DateTime expiry = DateTime.now().add(const Duration(days: 3));
          bool isTrial = true;
          if (licenseUntilStr != null) {
            final parsed = DateTime.tryParse(licenseUntilStr);
            if (parsed != null) {
              expiry = parsed;
              isTrial = false;
            }
          }
          final subJson = jsonEncode({
            'venueId': importedAcc.id,
            'planName': isTrial ? '3 Kunlik Bepul Sinov' : 'Arena Standart',
            'expiryDate': expiry.toIso8601String(),
            'pricePerTablePerMonth': 100000,
            'licensedTablesCount': 10,
            'isTrial': isTrial,
          });
          await prefs.setString('arena_subscription_${importedAcc.id}', subJson);

          state = state.copyWith(
            accounts: updated,
            activeAccount: importedAcc,
            isLoggedOut: false,
          );
          return true;
        }
      }
    } catch (_) {}

    return false;
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
          ? SecurityHelper.hashPassword(newPassword)
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
