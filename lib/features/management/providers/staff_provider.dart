// ============================================
// Arena — Xodimlar va Kassirlar Provideri
// Har bir biznes/poliya hisobi uchun alohida ajratilgan xodimlar va PIN-kodlar
// ============================================

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/auth/providers/business_account_provider.dart';
import '../models/staff_member.dart';

final defaultStaffList = [
  StaffMember(
    id: 'owner-1',
    name: 'Biznes egasi (EGA)',
    phone: '+998 90 000 00 01',
    role: StaffRole.owner,
    pin: '7777',
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
  ),
  StaffMember(
    id: 'cashier-1',
    name: 'Kassir Samar',
    phone: '+998 90 123 45 67',
    role: StaffRole.cashier,
    pin: '1111',
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
  ),
];

class StaffListNotifier extends AsyncNotifier<List<StaffMember>> {
  String get _currentKey {
    final activeId =
        ref.read(businessAccountProvider).activeAccount?.id ?? 'samar-arena';
    return 'arena_staff_members_$activeId';
  }

  @override
  Future<List<StaffMember>> build() async {
    // Faol hisob o'zgarganda xodimlar ro'yxati avtomatik qayta yuklanadi
    ref.watch(businessAccountProvider.select((s) => s.activeAccount?.id));
    return _loadStaff();
  }

  Future<List<StaffMember>> _loadStaff() async {
    final activeAccount = ref.read(businessAccountProvider).activeAccount;
    final accountId = activeAccount?.id ?? 'samar-arena';
    final key = 'arena_staff_members_$accountId';

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);

    List<StaffMember> initialList;
    if (accountId == 'samar-arena' || accountId == 'default') {
      initialList = defaultStaffList;
    } else {
      // Yangi hisob uchun faqat shu hisobning egasi boshlang'ich bo'ladi
      initialList = [
        StaffMember(
          id: 'owner-$accountId',
          name: activeAccount?.ownerName ?? 'Biznes Egasi',
          phone: activeAccount?.phone ?? '',
          role: StaffRole.owner,
          pin: activeAccount?.ownerPin ?? '7777',
          isActive: true,
          createdAt: DateTime.now(),
        ),
      ];
    }

    if (raw == null || raw.trim().isEmpty) {
      await _saveList(initialList);
      return initialList;
    }

    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final list = decoded
          .map((item) => StaffMember.fromJson(item as Map<String, dynamic>))
          .toList();
      if (list.isEmpty) {
        await _saveList(initialList);
        return initialList;
      }
      return list;
    } catch (_) {
      await _saveList(initialList);
      return initialList;
    }
  }

  Future<void> _saveList(List<StaffMember> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_currentKey, jsonStr);
  }

  Future<bool> addStaff({
    required String name,
    required String phone,
    required StaffRole role,
    required String pin,
  }) async {
    final currentList = state.value ?? [];

    if (pin.length != 4) return false;
    if (currentList.any((s) => s.pin == pin)) {
      return false; // Ushbu PIN allaqachon mavjud
    }

    final newMember = StaffMember(
      id: const Uuid().v4(),
      name: name.trim(),
      phone: phone.trim(),
      role: role,
      pin: pin.trim(),
      isActive: true,
      createdAt: DateTime.now(),
    );

    final updated = [...currentList, newMember];
    state = AsyncData(updated);
    await _saveList(updated);
    return true;
  }

  Future<bool> updateStaff(StaffMember member) async {
    final currentList = state.value ?? [];

    final conflict =
        currentList.any((s) => s.id != member.id && s.pin == member.pin);
    if (conflict) return false;

    final updated =
        currentList.map((s) => s.id == member.id ? member : s).toList();
    state = AsyncData(updated);
    await _saveList(updated);
    return true;
  }

  Future<bool> updatePin({required String id, required String newPin}) async {
    if (newPin.length != 4) return false;
    final currentList = state.value ?? [];

    final conflict = currentList.any((s) => s.id != id && s.pin == newPin);
    if (conflict) return false;

    final updated = currentList.map((s) {
      if (s.id == id) {
        return s.copyWith(pin: newPin);
      }
      return s;
    }).toList();

    state = AsyncData(updated);
    await _saveList(updated);
    return true;
  }

  Future<bool> deleteStaff(String id) async {
    final currentList = state.value ?? [];
    final target = currentList.firstWhere((s) => s.id == id,
        orElse: () => currentList.first);

    if (target.isOwner) {
      final ownersCount = currentList.where((s) => s.isOwner).length;
      if (ownersCount <= 1) return false;
    }

    final updated = currentList.where((s) => s.id != id).toList();
    state = AsyncData(updated);
    await _saveList(updated);
    return true;
  }

  Future<void> toggleActive(String id) async {
    final currentList = state.value ?? [];
    final updated = currentList.map((s) {
      if (s.id == id) {
        return s.copyWith(isActive: !s.isActive);
      }
      return s;
    }).toList();
    state = AsyncData(updated);
    await _saveList(updated);
  }

  StaffMember? findByPin(String pin) {
    final list = state.value ?? defaultStaffList;
    try {
      return list.firstWhere((s) => s.pin == pin && s.isActive);
    } catch (_) {
      return null;
    }
  }
}

final staffListProvider =
    AsyncNotifierProvider<StaffListNotifier, List<StaffMember>>(
        StaffListNotifier.new);

// Qidiruv va Filtr provayderlari
class StaffSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String q) => state = q;
}

final staffSearchQueryProvider =
    NotifierProvider<StaffSearchQueryNotifier, String>(
        StaffSearchQueryNotifier.new);

class StaffRoleFilterNotifier extends Notifier<StaffRole?> {
  @override
  StaffRole? build() => null;
  void setFilter(StaffRole? f) => state = f;
}

final staffRoleFilterProvider =
    NotifierProvider<StaffRoleFilterNotifier, StaffRole?>(
        StaffRoleFilterNotifier.new);

final filteredStaffProvider = Provider<List<StaffMember>>((ref) {
  final staffAsync = ref.watch(staffListProvider);
  final list = staffAsync.value ?? [];
  final query = ref.watch(staffSearchQueryProvider).toLowerCase().trim();
  final roleFilter = ref.watch(staffRoleFilterProvider);

  return list.where((s) {
    if (roleFilter != null && s.role != roleFilter) return false;
    if (query.isNotEmpty) {
      final nameMatches = s.name.toLowerCase().contains(query);
      final phoneMatches = s.phone.toLowerCase().contains(query);
      final pinMatches = s.pin.contains(query);
      return nameMatches || phoneMatches || pinMatches;
    }
    return true;
  }).toList();
});
