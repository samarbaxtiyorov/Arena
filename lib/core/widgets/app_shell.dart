// ============================================
// Champion POS — Asosiy Shell
// Mobil qurilmalarda pastki NavigationBar,
// Kompyuter va planshetlarda professional Desktop Sidebar
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';
import '../auth/providers/business_account_provider.dart';
import '../config/app_mode.dart';
import '../router/app_router.dart';
import '../widgets/arena_logo.dart';
import '../../data/repositories/database_providers.dart';
import '../../features/tables/providers/tables_providers.dart';
import '../../features/shop/providers/shop_providers.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _locationToIndex(String location, bool isPos) {
    if (location.startsWith(AppRoutes.shop)) return 1;
    if (location.startsWith(AppRoutes.archive)) return 2;
    if (location.startsWith(AppRoutes.debts)) return 3;
    if (!isPos && location.startsWith(AppRoutes.management)) return 4;
    return 0; // AppRoutes.tables
  }

  void _onNavigate(BuildContext context, int index, bool isPos) {
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
      case 4:
        if (!isPos) {
          context.go(AppRoutes.management);
        } else {
          context.go(AppRoutes.tables);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final appMode = ref.watch(appModeProvider);
    final isPos = appMode == AppMode.pos;
    final currentIndex = _locationToIndex(location, isPos);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 850;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Row(
          children: [
            // ── Kompyuter uchun Professional Chap Panel (Sidebar) ──
            _buildDesktopSidebar(context, ref, currentIndex, isPos),

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
            selectedIndex: currentIndex > (isPos ? 3 : 4) ? 0 : currentIndex,
            onDestinationSelected: (index) => _onNavigate(context, index, isPos),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: 'Maydonlar',
              ),
              const NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront_rounded),
                label: "Do'kon",
              ),
              NavigationDestination(
                icon: Icon(isPos ? Icons.point_of_sale_outlined : Icons.inventory_2_outlined),
                selectedIcon: Icon(isPos ? Icons.point_of_sale_rounded : Icons.inventory_2_rounded),
                label: isPos ? 'Kassa' : 'Arxiv',
              ),
              const NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book_rounded),
                label: 'Qarzlar',
              ),
              if (!isPos)
                const NavigationDestination(
                  icon: Icon(Icons.admin_panel_settings_outlined),
                  selectedIcon: Icon(Icons.admin_panel_settings_rounded),
                  label: 'Boshqaruv',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar(
      BuildContext context, WidgetRef ref, int currentIndex, bool isPos) {
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
        color: Color(0xFF0F172A), // Dark luxury slate
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
                      Text(
                        isPos ? 'ARENA POS' : 'ARENA BOSS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isPos ? const Color(0xFF34D399) : const Color(0xFF38BDF8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        activeVenue?.venueName ?? (isPos ? 'Bilyard Kassa' : 'Boshqaruv Tizimi'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isPos
                              ? const Color(0xFF065F46).withOpacity(0.6)
                              : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(4),
                          border: isPos
                              ? Border.all(color: const Color(0xFF059669), width: 0.8)
                              : null,
                        ),
                        child: Text(
                          isPos ? 'KASSA ISH O\'RNI' : 'BOSHQARUV MARKAZI',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: isPos ? const Color(0xFF6EE7B7) : const Color(0xFF94A3B8),
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

          const Gap(14),

          // ── 2. Navigatsiya Menyu Tugmalari ───────────────────────
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
                  onTap: () => _onNavigate(context, 0, isPos),
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
                  onTap: () => _onNavigate(context, 1, isPos),
                ),
                const Gap(6),
                _buildSidebarNavItem(
                  context: context,
                  index: 2,
                  currentIndex: currentIndex,
                  title: isPos ? 'Kassa & Cheklar' : 'Kassa & Arxiv',
                  icon: isPos ? Icons.point_of_sale_rounded : Icons.receipt_long_rounded,
                  onTap: () => _onNavigate(context, 2, isPos),
                ),
                const Gap(6),
                _buildSidebarNavItem(
                  context: context,
                  index: 3,
                  currentIndex: currentIndex,
                  title: 'Nasiya Daftari',
                  icon: Icons.menu_book_rounded,
                  onTap: () => _onNavigate(context, 3, isPos),
                ),
                if (!isPos) ...[
                  const Gap(6),
                  _buildSidebarNavItem(
                    context: context,
                    index: 4,
                    currentIndex: currentIndex,
                    title: 'Boshqaruv Markazi',
                    icon: Icons.admin_panel_settings_rounded,
                    onTap: () => _onNavigate(context, 4, isPos),
                  ),
                ],
              ],
            ),
          ),

          // ── 3. Foydalanuvchi va Qulflash Paneli (Pastki qism) ─────
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
                        color: authState.isOwner
                            ? const Color(0xFFEAB308).withOpacity(0.2)
                            : const Color(0xFF10B981).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: authState.isOwner
                              ? const Color(0xFFEAB308)
                              : const Color(0xFF10B981),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        authState.isOwner
                            ? Icons.admin_panel_settings_rounded
                            : Icons.badge_rounded,
                        size: 20,
                        color: authState.isOwner
                            ? const Color(0xFFFACC15)
                            : const Color(0xFF34D399),
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
                                : (authState.isOwner ? 'Boshliq' : 'Kassir'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            authState.isOwner ? '👑 Boshliq' : '👤 Kassir',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: authState.isOwner
                                  ? const Color(0xFFFACC15)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Ekranni PIN bilan tezkor qulflash
                    IconButton(
                      tooltip: 'PIN bilan qulflash',
                      icon: const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                      onPressed: () {
                        ref.read(authProvider.notifier).lock();
                      },
                    ),
                  ],
                ),
                const Gap(8),
                // Bulut Sinxronlash va Chiqish tugmalari
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
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
                          padding: const EdgeInsets.symmetric(vertical: 6),
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
                                "Sinxronlash",
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF38BDF8)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (authState.isOwner) ...[
                  const Gap(8),
                  InkWell(
                    onTap: () {
                      ref.read(appModeProvider.notifier).setMode(AppMode.boss);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF78350F).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD97706), width: 1),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_rounded, size: 14, color: Color(0xFFFACC15)),
                          Gap(6),
                          Text(
                            "👑 Arena Boss (Boshqaruv)ga O'tish",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFACC15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                ? const Color(0xFF2563EB) // Brand active blue
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
