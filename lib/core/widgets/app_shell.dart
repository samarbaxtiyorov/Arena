// ============================================
// Arena POS — Kassir Asosiy Shell
// Faqat Kassir uchun maxsus toza kassa dasturi
// 4 ta asosiy modul: Maydonlar, Do'kon, Kassa & Cheklar, Qarzlar
// Ortiqcha boshqaruv va boss elementlaridan tozalangan
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';
import '../auth/providers/business_account_provider.dart';
import '../router/app_router.dart';
import '../services/lan_pos_server.dart';
import '../widgets/arena_logo.dart';
import '../../data/repositories/database_providers.dart';
import '../../features/tables/providers/tables_providers.dart';
import '../../features/shop/providers/shop_providers.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith(AppRoutes.shop)) return 1;
    if (location.startsWith(AppRoutes.archive)) return 2;
    if (location.startsWith(AppRoutes.debts)) return 3;
    return 0; // AppRoutes.tables
  }

  void _onNavigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.tables);
        break;
      case 1:
        context.go(AppRoutes.shop);
        break;
      case 2:
        context.go(AppRoutes.archive);
        break;
      case 3:
        context.go(AppRoutes.debts);
        break;
    }
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 24),
            Gap(10),
            Text(
              "Tizimdan chiqish",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: const Text(
          "Haqiqatan ham kassir hisobidan chiqmoqchimisiz?",
          style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Bekor qilish",
                style: TextStyle(
                    color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
              ref.read(businessAccountProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Ha, chiqish",
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 850;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Row(
          children: [
            // ── Kompyuter uchun Professional Chap Panel (Sidebar) ──
            _buildDesktopSidebar(context, ref, currentIndex),

            // ── Asosiy O'nggi Sahifa Maydoni ────────────────────────
            Expanded(
              child: ClipRect(child: child),
            ),
          ],
        ),
      );
    }

    // ── Mobil Telefonlar Uchun Pastki Panel ──
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 64,
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFFDBEAFE),
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF64748B),
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return IconThemeData(
                size: 24,
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B),
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: currentIndex > 3 ? 0 : currentIndex,
            onDestinationSelected: (index) => _onNavigate(context, index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: 'Maydonlar',
              ),
              NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront_rounded),
                label: "Do'kon",
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'Kassa',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book_rounded),
                label: 'Qarzlar',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar(
      BuildContext context, WidgetRef ref, int currentIndex) {
    final businessState = ref.watch(businessAccountProvider);
    final activeVenue = businessState.activeAccount;
    final authState = ref.watch(authProvider);

    final activeSessions =
        ref.watch(activeSessionsStreamProvider).value ?? [];
    final activeCount =
        activeSessions.where((s) => s.status == 'active').length;

    final cart = ref.watch(cartProvider);
    final cartItemsCount = cart.totalQuantity;

    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Hashamatli qorong'i slate
        border: Border(
          right: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      child: Column(
        children: [
          // ── 1. Sidebar Brend Bosh qismi ─────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF1E293B), width: 1),
              ),
            ),
            child: Row(
              children: [
                const ArenaLogo(size: 42, borderRadius: 12),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ARENA POS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF34D399),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        activeVenue?.venueName ?? 'Bilyard & Sport Kassa',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF065F46).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: const Color(0xFF059669), width: 0.8),
                        ),
                        child: const Text(
                          'KASSA ISH O\'RNI',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF6EE7B7),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // LAN Kassa Aloqasi (Nozik va toza badge)
          Consumer(
            builder: (context, ref, _) {
              final lanServer = ref.watch(lanPosServerProvider);
              if (!lanServer.isRunning || lanServer.localIp == null) {
                return const SizedBox(height: 6);
              }
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF064E3B).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: const Color(0xFF059669).withOpacity(0.5), width: 0.8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF34D399),
                      ),
                    ),
                    const Gap(8),
                    Text(
                      "LAN: ${lanServer.localIp}:${lanServer.port}",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6EE7B7),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const Gap(4),

          // ── 2. Navigatsiya Menyu Tugmalari (Faqat 4 ta kassa moduli) ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSidebarNavItem(
                  context: context,
                  index: 0,
                  currentIndex: currentIndex,
                  title: 'Maydonlar & Stollar',
                  icon: Icons.grid_view_rounded,
                  badge: activeCount > 0 ? '$activeCount band' : null,
                  badgeColor: const Color(0xFF10B981),
                  onTap: () => _onNavigate(context, 0),
                ),
                const Gap(6),
                _buildSidebarNavItem(
                  context: context,
                  index: 1,
                  currentIndex: currentIndex,
                  title: "Do'kon & Bar POS",
                  icon: Icons.storefront_rounded,
                  badge: cartItemsCount > 0 ? '$cartItemsCount ta' : null,
                  badgeColor: const Color(0xFF3B82F6),
                  onTap: () => _onNavigate(context, 1),
                ),
                const Gap(6),
                _buildSidebarNavItem(
                  context: context,
                  index: 2,
                  currentIndex: currentIndex,
                  title: 'Kassa & Cheklar',
                  icon: Icons.receipt_long_rounded,
                  onTap: () => _onNavigate(context, 2),
                ),
                const Gap(6),
                _buildSidebarNavItem(
                  context: context,
                  index: 3,
                  currentIndex: currentIndex,
                  title: 'Nasiya Daftari',
                  icon: Icons.menu_book_rounded,
                  onTap: () => _onNavigate(context, 3),
                ),
              ],
            ),
          ),

          // ── 3. Kassir Profili va Chiqish Paneli ───────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF0B1120),
              border: Border(
                top: BorderSide(color: Color(0xFF1E293B), width: 1),
              ),
            ),
            child: Column(
              children: [
                // Profil qatori
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF10B981),
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 20,
                        color: Color(0xFF34D399),
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authState.userName.isNotEmpty
                                ? authState.userName
                                : 'Kassir',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            'Kassir / Xodim',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tizimdan toza chiqish tugmasi
                    IconButton(
                      tooltip: 'Tizimdan chiqish',
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFF87171),
                        size: 20,
                      ),
                      onPressed: () => _confirmLogout(context, ref),
                    ),
                  ],
                ),
                const Gap(8),
                // Bulut Sinxronlash tugmasi
                InkWell(
                  onTap: () async {
                    final sync = ref.read(syncServiceProvider);
                    final res = await sync.syncAll();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res.isSuccess
                              ? "Sinxronlandi! (${res.pulled} ta yuklandi, ${res.pushed} ta yuborildi)"
                              : (res.wasOffline
                                  ? "Internet aloqasi yo'q (Oflayn rejim)"
                                  : "Sinxronizatsiyada xatolik: ${res.errors.join(', ')}")),
                          backgroundColor: res.isSuccess
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sync_rounded,
                            size: 14, color: Color(0xFF38BDF8)),
                        Gap(6),
                        Text(
                          "Bulut bilan sinxronlash",
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF38BDF8)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required BuildContext context,
    required int index,
    required int currentIndex,
    required String title,
    required IconData icon,
    String? badge,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    final isSelected = index == currentIndex;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF2563EB) // Brand faol ko'k
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              ),
              const Gap(12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
              if (badge != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor ?? const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
