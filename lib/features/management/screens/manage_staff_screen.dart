// ============================================
// Arena — Xodimlar va Kassirlar Boshqaruvi Sahifasi
// Kassirlar ro'yxati, PIN-kod o'rnatish/almashtirish,
// yangi xodim qo'shish, tahrirlash va ruxsatlar
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/auth/auth_provider.dart';
import '../models/staff_member.dart';
import '../providers/staff_provider.dart';

class ManageStaffScreen extends ConsumerStatefulWidget {
  const ManageStaffScreen({super.key});

  @override
  ConsumerState<ManageStaffScreen> createState() => _ManageStaffScreenState();
}

class _ManageStaffScreenState extends ConsumerState<ManageStaffScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _revealedPins = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _togglePinVisibility(String staffId) {
    setState(() {
      if (_revealedPins.contains(staffId)) {
        _revealedPins.remove(staffId);
      } else {
        _revealedPins.add(staffId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffListProvider);
    final filteredStaff = ref.watch(filteredStaffProvider);
    final activeFilter = ref.watch(staffRoleFilterProvider);
    final authState = ref.watch(authProvider);

    final allStaff = staffAsync.value ?? [];
    final ownersCount = allStaff.where((s) => s.isOwner).length;
    final cashiersCount = allStaff.where((s) => s.isCashier).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xodimlar va Kassirlar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Kassirlar, PIN-kodlar va ruxsatlar',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _showAddStaffDialog(context),
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text(
                'Yangi xodim',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: staffAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
        error: (err, stack) => Center(
          child: Text("Xatolik yuz berdi: $err"),
        ),
        data: (_) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // ── 1. Statistika Paneli ─────────────────────────
              _buildStatsRow(
                total: allStaff.length,
                owners: ownersCount,
                cashiers: cashiersCount,
              ),

              const Gap(16),

              // ── 2. Qidiruv va Filtrlar ───────────────────────
              _buildSearchBar(),

              const Gap(12),

              _buildFilterChips(
                activeFilter: activeFilter,
                total: allStaff.length,
                owners: ownersCount,
                cashiers: cashiersCount,
              ),

              const Gap(16),

              // ── 3. Xodimlar Ro'yxati ─────────────────────────
              if (filteredStaff.isEmpty)
                _buildEmptyState()
              else
                ...filteredStaff.map((staff) {
                  final isCurrentActiveUser =
                      authState.userName == staff.name ||
                          (staff.isOwner && authState.isOwner && authState.userName == 'Biznes egasi');
                  final isPinRevealed = _revealedPins.contains(staff.id);

                  return _buildStaffCard(
                    staff: staff,
                    isCurrentActiveUser: isCurrentActiveUser,
                    isPinRevealed: isPinRevealed,
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  // ── Statistika Kartalari ──────────────────────────────────
  Widget _buildStatsRow({
    required int total,
    required int owners,
    required int cashiers,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Jami xodimlar',
            value: '$total ta',
            icon: Icons.people_alt_rounded,
            color: const Color(0xFF0F172A),
            bg: Colors.white,
          ),
        ),
        const Gap(10),
        Expanded(
          child: _buildStatCard(
            title: 'Boshliqlar',
            value: '$owners ta',
            icon: Icons.admin_panel_settings_rounded,
            color: const Color(0xFF2563EB),
            bg: const Color(0xFFEFF6FF),
          ),
        ),
        const Gap(10),
        Expanded(
          child: _buildStatCard(
            title: 'Kassirlar',
            value: '$cashiers ta',
            icon: Icons.point_of_sale_rounded,
            color: const Color(0xFF9333EA),
            bg: const Color(0xFFFAF5FF),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Gap(8),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const Gap(2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ── Qidiruv Qatori ────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          ref.read(staffSearchQueryProvider.notifier).setQuery(val);
        },
        decoration: InputDecoration(
          hintText: "Ism, telefon yoki PIN bo'yicha qidirish...",
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search_rounded,
              color: Color(0xFF64748B), size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      size: 18, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(staffSearchQueryProvider.notifier).setQuery('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  // ── Rol Filtrlari ─────────────────────────────────────────
  Widget _buildFilterChips({
    required StaffRole? activeFilter,
    required int total,
    required int owners,
    required int cashiers,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Barchasi ($total)',
            isSelected: activeFilter == null,
            onTap: () =>
                ref.read(staffRoleFilterProvider.notifier).setFilter(null),
          ),
          const Gap(8),
          _buildFilterChip(
            label: 'Boshliqlar ($owners)',
            isSelected: activeFilter == StaffRole.owner,
            onTap: () => ref
                .read(staffRoleFilterProvider.notifier)
                .setFilter(StaffRole.owner),
          ),
          const Gap(8),
          _buildFilterChip(
            label: 'Kassirlar ($cashiers)',
            isSelected: activeFilter == StaffRole.cashier,
            onTap: () => ref
                .read(staffRoleFilterProvider.notifier)
                .setFilter(StaffRole.cashier),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F172A)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // ── Xodim Kartasi ─────────────────────────────────────────
  Widget _buildStaffCard({
    required StaffMember staff,
    required bool isCurrentActiveUser,
    required bool isPinRevealed,
  }) {
    final isOwner = staff.isOwner;
    final initialLetter = staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'X';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrentActiveUser
              ? const Color(0xFF3B82F6)
              : const Color(0xFFE2E8F0),
          width: isCurrentActiveUser ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrentActiveUser
                ? const Color(0xFF3B82F6).withOpacity(0.08)
                : Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Asosiy Profil Qatori ────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isOwner
                          ? [const Color(0xFF60A5FA), const Color(0xFF1D4ED8)]
                          : [const Color(0xFFC084FC), const Color(0xFF7E22CE)],
                      center: const Alignment(0, -0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initialLetter,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const Gap(14),
                // Ism va Telefon
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              staff.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Gap(8),
                          // Badge (Boshliq / Kassir)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isOwner
                                  ? const Color(0xFFDBEAFE)
                                  : const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              staff.role.badgeLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isOwner
                                    ? const Color(0xFF1D4ED8)
                                    : const Color(0xFF7E22CE),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(3),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined,
                              size: 13, color: Color(0xFF94A3B8)),
                          const Gap(4),
                          Text(
                            staff.phone.isNotEmpty
                                ? staff.phone
                                : "Telefon kiritilmagan",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isCurrentActiveUser) ...[
                            const Gap(8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'HOZIRDA FAOL',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Tahrirlash va O'chirish Menyu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: Color(0xFF94A3B8)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showEditStaffDialog(context, staff);
                    } else if (val == 'change_pin') {
                      _showChangePinDialog(context, staff);
                    } else if (val == 'switch') {
                      _switchActiveStaff(staff);
                    } else if (val == 'delete') {
                      _confirmDeleteStaff(context, staff);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'change_pin',
                      child: Row(
                        children: [
                          Icon(Icons.key_rounded,
                              size: 18, color: Color(0xFF2563EB)),
                          Gap(10),
                          Text("PIN-kodni almashtirish"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined,
                              size: 18, color: Color(0xFF0F172A)),
                          Gap(10),
                          Text("Tahrirlash"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'switch',
                      child: Row(
                        children: [
                          Icon(Icons.switch_account_rounded,
                              size: 18, color: Color(0xFF059669)),
                          Gap(10),
                          Text("Ushbu profilga o'tish"),
                        ],
                      ),
                    ),
                    if (!staff.isOwner)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                size: 18, color: Color(0xFFEF4444)),
                            Gap(10),
                            Text("O'chirish",
                                style: TextStyle(color: Color(0xFFEF4444))),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const Gap(14),

            // ── Maxsus PIN-kod Paneli (Ko'rish va O'zgartirish) ────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      size: 16,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Kirish PIN-kodi",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const Gap(2),
                        Row(
                          children: [
                            Text(
                              isPinRevealed ? staff.pin : '••••',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: isPinRevealed ? 3 : 2,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const Gap(6),
                            InkWell(
                              onTap: () => _togglePinVisibility(staff.id),
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: Icon(
                                  isPinRevealed
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  size: 16,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // PIN-kodni o'zgartirish tugmasi
                  TextButton.icon(
                    onPressed: () => _showChangePinDialog(context, staff),
                    icon: const Icon(Icons.key_rounded, size: 15),
                    label: const Text(
                      "PIN almashtirish",
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      backgroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Gap(10),

            // ── Ruxsatlar va Amallar qatori ─────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    isOwner
                        ? Icons.verified_user_rounded
                        : Icons.shield_outlined,
                    size: 15,
                    color: isOwner
                        ? const Color(0xFF10B981)
                        : const Color(0xFF64748B),
                  ),
                  const Gap(6),
                  Expanded(
                    child: Text(
                      staff.role.permissionsDescription,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Gap(12),

            // Tugmalar (Profilga o'tish / Tahrirlash)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isCurrentActiveUser
                        ? null
                        : () => _switchActiveStaff(staff),
                    icon: Icon(
                      isCurrentActiveUser
                          ? Icons.check_circle_rounded
                          : Icons.switch_account_rounded,
                      size: 16,
                    ),
                    label: Text(
                      isCurrentActiveUser
                          ? "Hozirgi profil"
                          : "Profilga o'tish",
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      side: BorderSide(
                        color: isCurrentActiveUser
                            ? const Color(0xFF10B981)
                            : const Color(0xFFCBD5E1),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const Gap(8),
                IconButton.filledTonal(
                  onPressed: () => _showEditStaffDialog(context, staff),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF334155),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  tooltip: "Tahrirlash",
                ),
                if (!staff.isOwner) ...[
                  const Gap(6),
                  IconButton.filledTonal(
                    onPressed: () => _confirmDeleteStaff(context, staff),
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 16, color: Color(0xFFEF4444)),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE2E2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    tooltip: "O'chirish",
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_search_rounded,
                  size: 36, color: Color(0xFF94A3B8)),
            ),
            const Gap(16),
            const Text(
              "Xodim topilmadi",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const Gap(4),
            const Text(
              "Qidiruv so'zini o'zgartiring yoki yangi xodim qo'shing",
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Profilga O'tish (Login As Staff) ──────────────────────
  void _switchActiveStaff(StaffMember staff) {
    ref.read(authProvider.notifier).loginAsStaff(staff);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 20),
            const Gap(10),
            Expanded(
              child: Text(
                "Profil almashdi: ${staff.name} (${staff.role.displayName})",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Yangi Xodim Qo'shish Dialogi ──────────────────────────
  void _showAddStaffDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+998 ');
    final pinCtrl = TextEditingController();
    StaffRole selectedRole = StaffRole.cashier;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Gap(16),
                  const Text(
                    "Yangi Xodim / Kassir Qo'shish",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Text(
                    "Kassir ismi, telefoni va 4 xonali shaxsiy PIN-kodi",
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const Gap(20),

                  // Ismi
                  const Text("Xodim Ismi va Familiyasi *",
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155))),
                  const Gap(6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: "Masalan: Kassir Jasur",
                      prefixIcon: const Icon(Icons.person_outline_rounded,
                          size: 20, color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),

                  const Gap(14),

                  // Telefon raqami
                  const Text("Telefon Raqami",
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155))),
                  const Gap(6),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: "+998 90 123 45 67",
                      prefixIcon: const Icon(Icons.phone_outlined,
                          size: 20, color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),

                  const Gap(14),

                  // Roli
                  const Text("Xodim Roli",
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155))),
                  const Gap(6),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setModalState(() {
                              selectedRole = StaffRole.cashier;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedRole == StaffRole.cashier
                                  ? const Color(0xFFF3E8FF)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedRole == StaffRole.cashier
                                    ? const Color(0xFF9333EA)
                                    : const Color(0xFFE2E8F0),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.point_of_sale_rounded,
                                    color: selectedRole == StaffRole.cashier
                                        ? const Color(0xFF9333EA)
                                        : const Color(0xFF64748B)),
                                const Gap(4),
                                Text(
                                  "Kassir",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: selectedRole == StaffRole.cashier
                                        ? const Color(0xFF7E22CE)
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setModalState(() {
                              selectedRole = StaffRole.owner;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedRole == StaffRole.owner
                                  ? const Color(0xFFEFF6FF)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedRole == StaffRole.owner
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFE2E8F0),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.admin_panel_settings_rounded,
                                    color: selectedRole == StaffRole.owner
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFF64748B)),
                                const Gap(4),
                                Text(
                                  "Boshliq (Ega)",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: selectedRole == StaffRole.owner
                                        ? const Color(0xFF1D4ED8)
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Gap(16),

                  // PIN-kod (4 xonali)
                  const Row(
                    children: [
                      Text("Kirish PIN-kodi (4 ta raqam) *",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155))),
                      Gap(6),
                      Text("(Faqat raqamlar)",
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF94A3B8))),
                    ],
                  ),
                  const Gap(6),
                  TextField(
                    controller: pinCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                    decoration: InputDecoration(
                      hintText: "4 xonali PIN",
                      prefixIcon: const Icon(Icons.lock_outline_rounded,
                          size: 20, color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),

                  const Gap(22),

                  // Saqlash tugmasi
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final navigator = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);
                        final name = nameCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        final pin = pinCtrl.text.trim();

                        if (name.isEmpty) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text("Iltimos, xodim ismini kiriting"),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                          return;
                        }
                        if (pin.length != 4) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "PIN-kod roppa-rosa 4 ta raqamdan iborat bo'lishi shart!"),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                          return;
                        }

                        final success = await ref
                            .read(staffListProvider.notifier)
                            .addStaff(
                              name: name,
                              phone: phone,
                              role: selectedRole,
                              pin: pin,
                            );

                        if (success) {
                          navigator.pop();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                  "$name muvaffaqiyatli qo'shildi! PIN-kod: $pin"),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        } else {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Bu PIN-kod boshqa xodimda mavjud! Boshqa PIN tanlang."),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Xodimni Saqlash",
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── PIN-kodni O'zgartirish Dialogi ────────────────────────
  void _showChangePinDialog(BuildContext context, StaffMember staff) {
    final pinCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.key_rounded,
                  color: Color(0xFF2563EB), size: 22),
            ),
            const Gap(10),
            const Expanded(
              child: Text(
                "PIN-kodni Almashtirish",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${staff.name} (${staff.role.displayName}) uchun yangi 4 xonali PIN-kod belgilang:",
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const Gap(16),
            TextField(
              controller: pinCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
                color: Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: "••••",
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0xFF2563EB), width: 2),
                ),
              ),
            ),
            const Gap(8),
            const Text(
              "Kassir ushbu yangi PIN orqali tizimga kiradi",
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Bekor qilish",
                style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final newPin = pinCtrl.text.trim();
              if (newPin.length != 4) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text("PIN-kod 4 ta raqam bo'lishi kerak!"),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
                return;
              }

              final success = await ref
                  .read(staffListProvider.notifier)
                  .updatePin(id: staff.id, newPin: newPin);

              if (success) {
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                        "${staff.name} uchun yangi PIN-kod ($newPin) o'rnatildi!"),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              } else {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                        "Ushbu PIN-kod boshqa xodim tomonidan band qilingan!"),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Saqlash"),
          ),
        ],
      ),
    );
  }

  // ── Xodimni Tahrirlash Dialogi ────────────────────────────
  void _showEditStaffDialog(BuildContext context, StaffMember staff) {
    final nameCtrl = TextEditingController(text: staff.name);
    final phoneCtrl = TextEditingController(text: staff.phone);
    final pinCtrl = TextEditingController(text: staff.pin);
    StaffRole selectedRole = staff.role;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Gap(16),
                  const Text(
                    "Xodim Ma'lumotlarini Tahrirlash",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Gap(20),

                  // Ism
                  const Text("Xodim Ismi va Familiyasi",
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155))),
                  const Gap(6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),

                  const Gap(14),

                  // Telefon
                  const Text("Telefon Raqami",
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155))),
                  const Gap(6),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),

                  const Gap(14),

                  // PIN-kod
                  const Text("PIN-kod (4 ta raqam)",
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155))),
                  const Gap(6),
                  TextField(
                    controller: pinCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),

                  const Gap(14),

                  // Rol
                  const Text("Xodim Roli",
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155))),
                  const Gap(6),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setModalState(() {
                              selectedRole = StaffRole.cashier;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedRole == StaffRole.cashier
                                  ? const Color(0xFFF3E8FF)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedRole == StaffRole.cashier
                                    ? const Color(0xFF9333EA)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "Kassir",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: selectedRole == StaffRole.cashier
                                      ? const Color(0xFF7E22CE)
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setModalState(() {
                              selectedRole = StaffRole.owner;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedRole == StaffRole.owner
                                  ? const Color(0xFFEFF6FF)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedRole == StaffRole.owner
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "Boshliq (Ega)",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: selectedRole == StaffRole.owner
                                      ? const Color(0xFF1D4ED8)
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Gap(22),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final navigator = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);
                        final name = nameCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        final pin = pinCtrl.text.trim();

                        if (name.isEmpty) return;
                        if (pin.length != 4) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content:
                                  Text("PIN-kod 4 ta raqam bo'lishi kerak!"),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                          return;
                        }

                        final updatedMember = staff.copyWith(
                          name: name,
                          phone: phone,
                          pin: pin,
                          role: selectedRole,
                        );

                        final success = await ref
                            .read(staffListProvider.notifier)
                            .updateStaff(updatedMember);

                        if (success) {
                          navigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Xodim ma'lumotlari muvaffaqiyatli saqlandi!"),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        } else {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "PIN-kod boshqa xodimda mavjud! Boshqa PIN tanlang."),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "O'zgarishlarni Saqlash",
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── O'chirishni Tasdiqlash ────────────────────────────────
  void _confirmDeleteStaff(BuildContext context, StaffMember staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            Gap(8),
            Text("Xodimni O'chirish"),
          ],
        ),
        content: Text(
          "${staff.name} (${staff.role.displayName}) ni ro'yxatdan butunlay o'chirmoqchimisiz?\nU ushbu PIN-kod (${staff.pin}) orqali tizimga kira olmaydi.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Bekor qilish"),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();
              final success = await ref
                  .read(staffListProvider.notifier)
                  .deleteStaff(staff.id);
              if (success) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text("${staff.name} tizimdan o'chirildi!"),
                    backgroundColor: const Color(0xFF0F172A),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text("O'chirish"),
          ),
        ],
      ),
    );
  }
}
