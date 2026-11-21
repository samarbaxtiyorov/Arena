// ============================================
// Arena — Biznes / Muassasa Akkauntlari Provideri
// Multi-tenant boshqaruv: Login va Parol asosida
// ============================================

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../constants/app_constants.dart';
import '../../utils/security_helper.dart';
import '../models/business_account.dart';
import '../../../data/local/app_database.dart';
import '../../../data/remote/supabase_remote.dart';
import '../../../data/sync/sync_service.dart';

const String _accountsPrefKey = 'arena_business_accounts_v4';
const String _activeAccountIdPrefKey = 'arena_active_account_id_v4';
const String _isLoggedOutPrefKey = 'arena_business_logged_out_v4';

final defaultInitialAccounts = const <BusinessAccount>[];

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
  static SharedPreferences? initialPrefs;

  @override
  BusinessAccountState build() {
    if (initialPrefs != null) {
      return _parseFromPrefs(initialPrefs!);
    }
    _loadFromPrefs();
    return const BusinessAccountState(isLoading: true);
  }

  static BusinessAccountState _parseFromPrefs(SharedPreferences prefs) {
    String? rawAccounts = prefs.getString(_accountsPrefKey);
    if (rawAccounts == null || rawAccounts.trim().isEmpty) {
      final legacyAccounts = prefs.getString('arena_business_accounts_v3');
      if (legacyAccounts != null && legacyAccounts.trim().isNotEmpty) {
        rawAccounts = legacyAccounts;
      }
    }

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

    return BusinessAccountState(
      accounts: list,
      activeAccount: active,
      isLoggedOut: isLoggedOut,
      isLoading: false,
    );
  }

  // ── 1. Validatsiya Qoidalari ──────────────────────────────

  /// Eski telefon formatlarini solishtirish (Backward-compatibility)
  static bool matchPhone(String p1, String p2) {
    if (p1.trim().toLowerCase() == p2.trim().toLowerCase()) return true;
    String d1 = p1.replaceAll(RegExp(r'\D'), '');
    String d2 = p2.replaceAll(RegExp(r'\D'), '');
    if (d1.isEmpty || d2.isEmpty) return false;
    if (d1 == d2) return true;
    if (d1.startsWith('998') && d1.length > 9) d1 = d1.substring(3);
    if (d2.startsWith('998') && d2.length > 9) d2 = d2.substring(3);
    if (d1 == d2) return true;
    final minLen = d1.length < d2.length ? d1.length : d2.length;
    if (minLen >= 7) {
      if (d1.substring(d1.length - minLen) == d2.substring(d2.length - minLen)) return true;
    }
    return false;
  }

  /// Login validatsiyasi:
  /// - Kamida 6 ta belgi
  /// - Probel (bo'sh joy) bo'lishi mumkin emas
  /// - Nuqta, vergul yoki boshqa tinish belgilari bo'lishi mumkin emas
  /// - Faqat lotin harflari, raqamlar va pastki chiziq (_)
  static String? validateLogin(String login) {
    final clean = login.trim();
    if (clean.isEmpty) {
      return "Iltimos, loginni kiriting!";
    }
    if (clean.contains(' ')) {
      return "Loginda probel (bo'sh joy) bo'lishi mumkin emas!";
    }
    if (clean.contains('.') || clean.contains(',') || clean.contains(';') || clean.contains(':')) {
      return "Loginda nuqta, vergul yoki boshqa tinish belgilari bo'lishi mumkin emas!";
    }
    if (clean.length < 6) {
      return "Login kamida 6 ta belgidan iborat bo'lishi kerak!";
    }
    final validRegex = RegExp(r'^[a-zA-Z0-9_]{6,32}$');
    if (!validRegex.hasMatch(clean)) {
      return "Login faqat lotin harflari va raqamlardan iborat bo'lishi kerak (masalan: arena01, jasmina)";
    }
    return null;
  }

  /// Akkaunt paroli validatsiyasi:
  /// - Kamida 8 ta belgidan kam bo'lmasligi kerak
  static String? validatePassword(String password) {
    final clean = password.trim();
    if (clean.isEmpty) {
      return "Iltimos, akkaunt parolini kiriting!";
    }
    if (clean.length < 8) {
      return "Akkaunt paroli kamida 8 ta belgidan iborat bo'lishi shart!";
    }
    return null;
  }

  // ── 2. Mahalliy Xotirani Boshqarish ──────────────────────

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Eski v3 pref key'dan v4 ga xavfsiz ko'chirish
    String? rawAccounts = prefs.getString(_accountsPrefKey);
    if (rawAccounts == null || rawAccounts.trim().isEmpty) {
      final legacyAccounts = prefs.getString('arena_business_accounts_v3');
      if (legacyAccounts != null && legacyAccounts.trim().isNotEmpty) {
        rawAccounts = legacyAccounts;
      }
    }

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

  // ── 3. Supabase Bulutli Bazasidan Qidirish ───────────────

  /// Supabase bulutidan login (yoki eski telefon) bo'yicha qidirish
  static Future<Map<String, dynamic>?> _fetchCloudAccount(String login) async {
    final cleanLogin = login.trim().toLowerCase();
    if (cleanLogin.isEmpty) return null;

    final headers = {
      'apikey': AppConstants.supabaseAnonKey,
      'Authorization': 'Bearer ${AppConstants.supabaseAnonKey}',
      'Content-Type': 'application/json',
    };

    try {
      final encoded = Uri.encodeComponent(cleanLogin);
      // Supabase cloud_accounts jadvali PK ustuni: 'phone'
      final url = Uri.parse('${AppConstants.supabaseUrl}/rest/v1/cloud_accounts?phone=ilike.$encoded&limit=1');
      final res = await http.get(url, headers: headers).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final list = List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
        if (list.isNotEmpty) return list.first;
      }
    } catch (_) {}

    try {
      final url = Uri.parse('${AppConstants.supabaseUrl}/rest/v1/cloud_accounts?select=*&limit=100');
      final res = await http.get(url, headers: headers).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final list = List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
        for (final row in list) {
          final p = row['phone']?.toString().trim().toLowerCase() ?? '';
          if (p == cleanLogin || matchPhone(p, cleanLogin)) {
            return row;
          }
        }
      }
    } catch (_) {}

    return null;
  }

  // ── 4. Yangi Akkaunt Ro'yxatdan O'tkazish ─────────────────

  Future<bool> registerAccount({
    required String venueName,
    required String ownerName,
    String? login,
    String? phone, // backward compatibility
    required String password,
    required String ownerPin,
  }) async {
    final rawLogin = (login != null && login.trim().isNotEmpty) ? login : (phone ?? '');
    final cleanLogin = rawLogin.trim().toLowerCase();
    final cleanVenue = venueName.trim();
    final cleanOwner = ownerName.trim();
    final cleanPass = password.trim();
    final cleanPin = ownerPin.trim();

    // Validatsiya
    final loginErr = validateLogin(cleanLogin);
    if (loginErr != null) return false;

    final passErr = validatePassword(cleanPass);
    if (passErr != null) return false;

    final currentAccounts = List<BusinessAccount>.from(state.accounts);

    // 1. Mahalliy ro'yxatda bor-yo'qligini tekshirish
    if (currentAccounts.any((a) => a.login.trim().toLowerCase() == cleanLogin)) {
      return false; // Login allaqachon mavjud
    }

    // 2. Bulutli bazada (Supabase Cloud) bor-yo'qligini tekshirish
    try {
      final cloudMatch = await _fetchCloudAccount(cleanLogin);
      if (cloudMatch != null) {
        return false; // Bulutda bu login allaqachon band!
      }
    } catch (_) {}

    final newAcc = BusinessAccount(
      id: const Uuid().v4(),
      venueName: cleanVenue,
      ownerName: cleanOwner,
      login: cleanLogin,
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
          'phone': cleanLogin, // Supabase PK ustunida login saqlanadi
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

  // ── 5. Tizimga Kirish (Login) ─────────────────────────────

  Future<bool> loginAccount({
    String? login,
    String? phone, // backward compatibility
    required String password,
  }) async {
    final rawLogin = (login != null && login.trim().isNotEmpty) ? login : (phone ?? '');
    final cleanLogin = rawLogin.trim().toLowerCase();
    final cleanPass = password.trim();

    if (cleanLogin.isEmpty || cleanPass.isEmpty) return false;

    // 1. Mahalliy SharedPreferences'dan qidirish
    try {
      final match = state.accounts.firstWhere(
        (a) =>
            (a.login.trim().toLowerCase() == cleanLogin ||
             a.phone.trim().toLowerCase() == cleanLogin ||
             matchPhone(a.phone, cleanLogin) ||
             matchPhone(a.login, cleanLogin)) &&
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

      // Mahalliy topilgan bo'lsa ham, bulutdan eng so'nggi ma'lumotlarni darhol yuklab sinxronlaymiz
      _syncFromCloudSnapshot(match.id, match.login);

      return true;
    } catch (_) {
      // Mahalliy hisoblarda topilmadi — Bulutdan qidiramiz!
    }

    // 2. Bulutli bazadan (Supabase Cloud) qidirish (Boshqa telefondan/qurilmadan kirilganda)
    try {
      final cloudAccount = await _fetchCloudAccount(cleanLogin);
      if (cloudAccount != null) {
        final pinHash = cloudAccount['pin_hash']?.toString() ?? '';
        final isBlocked = cloudAccount['is_blocked'] as bool? ?? false;

        if (isBlocked) {
          return false;
        }

        // Parolni tekshirish (tuzlangan yoki oddiy SHA-256 xesh yoki PIN)
        bool passMatches = pinHash.isEmpty || SecurityHelper.verifyPassword(cleanPass, pinHash);
        final rawSnapshot = cloudAccount['data_snapshot'];
        Map<String, dynamic>? snapMap;
        if (rawSnapshot != null) {
          if (rawSnapshot is Map<String, dynamic>) {
            snapMap = rawSnapshot;
          } else if (rawSnapshot is String && rawSnapshot.isNotEmpty) {
            try {
              snapMap = jsonDecode(rawSnapshot) as Map<String, dynamic>;
            } catch (_) {}
          }
        }
        if (!passMatches && snapMap != null && snapMap['staff'] is List) {
          for (final s in snapMap['staff']) {
            if (s is Map && s['role'] == 'owner' && s['pin']?.toString() == cleanPass) {
              passMatches = true;
              break;
            }
          }
        }

        if (passMatches) {
          final venueName = cloudAccount['business_name']?.toString() ?? 'Arena Sport';
          final busId = cloudAccount['business_id']?.toString() ?? const Uuid().v4();
          final licenseUntilStr = cloudAccount['license_until']?.toString();

          final importedAcc = BusinessAccount(
            id: busId,
            venueName: venueName,
            ownerName: 'Boshliq',
            login: cleanLogin,
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
            'planName': isTrial ? '3 Kunlik Bepul Sinov' : 'Premium VIP',
            'expiryDate': expiry.toIso8601String(),
            'pricePerTablePerMonth': 100000,
            'licensedTablesCount': 10,
            'isTrial': isTrial,
          });
          await prefs.setString('arena_subscription_${importedAcc.id}', subJson);

          // Bulutdagi to'liq ma'lumotlar snapshotini darhol yuklab lokal bazaga tiklash
          if (snapMap != null && snapMap.isNotEmpty) {
            try {
              final db = AppDatabase.forAccount(importedAcc.id);
              final remote = SupabaseRemote(
                businessId: importedAcc.id,
                accountLogin: cleanLogin,
              );
              final sync = SyncService(db, remote);
              await sync.importSnapshot(snapMap);
              await db.close();
            } catch (_) {}
          }

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

  Future<void> _syncFromCloudSnapshot(String accountId, String login) async {
    try {
      final cloudAccount = await _fetchCloudAccount(login);
      if (cloudAccount != null && cloudAccount['data_snapshot'] != null) {
        final rawSnapshot = cloudAccount['data_snapshot'];
        Map<String, dynamic>? snapMap;
        if (rawSnapshot is Map<String, dynamic>) {
          snapMap = rawSnapshot;
        } else if (rawSnapshot is String && rawSnapshot.isNotEmpty) {
          snapMap = jsonDecode(rawSnapshot) as Map<String, dynamic>;
        }
        if (snapMap != null && snapMap.isNotEmpty) {
          final db = AppDatabase.forAccount(accountId);
          final remote = SupabaseRemote(
            businessId: accountId,
            accountLogin: login,
          );
          final sync = SyncService(db, remote);
          await sync.importSnapshot(snapMap);
          await db.close();
        }
      }
    } catch (_) {}
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
    String? login,
    String? phone,
    String? newPassword,
    String? newOwnerPin,
  }) async {
    if (state.activeAccount == null) return;
    final current = state.activeAccount!;
    final targetLogin = (login != null && login.trim().isNotEmpty)
        ? login.trim().toLowerCase()
        : (phone != null && phone.trim().isNotEmpty ? phone.trim().toLowerCase() : current.login);

    final updatedAcc = current.copyWith(
      venueName: venueName.trim(),
      ownerName: ownerName.trim(),
      login: targetLogin,
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
