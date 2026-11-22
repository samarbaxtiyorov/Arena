// ============================================
// Arena Boss — Xo'jayin Navigatsiya Shell (Executive Boss Shell)
// Faqat: Jonli Radar, Moliya/Analitika, Tariflar, Ombor, Chiroqlar, Xodimlar
// Kassa va chek urishdan 100% tozalangan Boshqaruv Markazi
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';
import '../auth/providers/business_account_provider.dart';
import '../config/app_mode.dart';
import '../services/lan_boss_client.dart';
import '../widgets/arena_logo.dart';

class BossShell extends ConsumerWidget {
  final Widget child;
  const BossShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/boss/analytics')) return 1;
    if (location.startsWith('/boss/tables')) return 2;
    if (location.startsWith('/boss/products')) return 3;
    if (location.startsWith('/boss/lights')) return 4;
    if (location.startsWith('/boss/staff')) return 5;
    if (location.startsWith('/boss/settings')) return 6;
    return 0; // /boss/radar
  }

  void _onNavigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/boss/radar');
        break;
      case 1:
        context.go('/boss/analytics');
        break;
      case 2:
        context.go('/boss/tables');
        break;
      case 3:
        context.go('/boss/products');
        break;
      case 4:
        context.go('/boss/lights');
        break;
      case 5:
        context.go('/boss/staff');
        break;
      case 6:
        context.go('/boss/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 850;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Row(
          children: [
            // ── Desktop Boss Sidebar (Titanium & Gold) ──────────────
            _buildDesktopSidebar(context, ref, currentIndex),

            // ── Asosiy Oyna ─────────────────────────────────────────
            Expanded(
              child: ClipRect(child: child),
            ),
          ],
        ),
      );
    }

    // ── Mobil / Planshet uchun ──
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          border: Border(top: BorderSide(color: Color(0xFF334155))),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 64,
            backgroundColor: const Color(0xFF1E293B),
            indicatorColor: const Color(0xFF334155),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? const Color(0xFFFACC15) : const Color(0xFF94A3B8),
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return IconThemeData(
                size: 24,
                color: isSelected ? const Color(0xFFFACC15) : const Color(0xFF94A3B8),
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: currentIndex > 4 ? 0 : currentIndex,
            onDestinationSelected: (index) => _onNavigate(context, index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.sensors_outlined),
                selectedIcon: Icon(Icons.sensors_rounded),
                label: 'Radar',
              ),
              NavigationDestination(
                icon: Icon(Icons.trending_up_outlined),
                selectedIcon: Icon(Icons.trending_up_rounded),
                label: 'Moliya',
              ),
              NavigationDestination(
                icon: Icon(Icons.table_restaurant_outlined),
                selectedIcon: Icon(Icons.table_restaurant_rounded),
                label: 'Tariflar',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2_rounded),
                label: 'Ombor',
              ),
              NavigationDestination(
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

  Widget _buildDesktopSidebar(BuildContext context, WidgetRef ref, int currentIndex) {
    final business = ref.watch(businessAccountProvider).activeAccount;
    final auth = ref.watch(authProvider);
    final lanState = ref.watch(lanBossClientProvider);

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xFF0B1120), // Luxury deep dark slate
        border: Border(right: BorderSide(color: Color(0xFF1E293B), width: 1.2)),
      ),
      child: Column(
        children: [
          // ── 1. Boss Brend Qismi ──────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              children: [
                const ArenaLogo(size: 44, borderRadius: 14),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'ARENA',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFACC15), // Royal Gold
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Gap(6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF78350F).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFD97706), width: 0.8),
                            ),
                            child: const Text(
                              'BOSS',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFBBF24),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        business?.venueName ?? 'Bilyard Boshqaruv Markazi',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: lanState.isConnected ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            ),
                          ),
                          const Gap(6),
                          Text(
                            lanState.isConnected ? 'Kassa Aloqada' : 'Lokal rejim',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: lanState.isConnected ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Gap(12),

          // ── 2. Navigatsiya Menyulari ─────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildNavItem(
                  title: 'Jonli Zal Radari',
                  icon: Icons.sensors_rounded,
                  index: 0,
                  currentIndex: currentIndex,
                  badge: lanState.activeTablesCount > 0 ? '${lanState.activeTablesCount} band' : null,
                  badgeColor: const Color(0xFF10B981),
                  onTap: () => _onNavigate(context, 0),
                ),
                const Gap(6),
                _buildNavItem(
                  title: 'Moliya & Analitika',
                  icon: Icons.trending_up_rounded,
                  index: 1,
                  currentIndex: currentIndex,
                  onTap: () => _onNavigate(context, 1),
                ),
                const Gap(6),
                _buildNavItem(
                  title: 'Stollar & Tariflar',
                  icon: Icons.table_restaurant_rounded,
                  index: 2,
                  currentIndex: currentIndex,
                  onTap: () => _onNavigate(context, 2),
                ),
                const Gap(6),
                _buildNavItem(
                  title: 'Ombor & Bar Mahsulotlari',
                  icon: Icons.inventory_2_rounded,
                  index: 3,
                  currentIndex: currentIndex,
                  onTap: () => _onNavigate(context, 3),
                ),
                const Gap(6),
                _buildNavItem(
                  title: 'Aqlli Chiroqlar Sozlamasi',
                  icon: Icons.lightbulb_circle_rounded,
                  index: 4,
                  currentIndex: currentIndex,
                  onTap: () => _onNavigate(context, 4),
                ),
                const Gap(6),
                _buildNavItem(
                  title: 'Xodimlar & Xavfsizlik',
                  icon: Icons.badge_rounded,
                  index: 5,
                  currentIndex: currentIndex,
                  onTap: () => _onNavigate(context, 5),
                ),
                const Gap(6),
                _buildNavItem(
                  title: 'Klub Sozlamalari',
                  icon: Icons.settings_suggest_rounded,
                  index: 6,
                  currentIndex: currentIndex,
                  onTap: () => _onNavigate(context, 6),
                ),
              ],
            ),
          ),

          // ── 3. Ega Profili va Qulflash ───────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFF060913),
              border: Border(top: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAB308).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEAB308), width: 1.5),
                      ),
                      child: const Center(
                        child: Icon(Icons.shield_rounded, color: Color(0xFFFACC15), size: 20),
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.userName.isNotEmpty ? auth.userName : 'Boshliq',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            '👑 Klub Egasi',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFFACC15)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'PIN bilan qulflash',
                      icon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                      onPressed: () => ref.read(authProvider.notifier).lock(),
                    ),
                  ],
                ),
                const Gap(10),
                InkWell(
                  onTap: () {
                    ref.read(appModeProvider.notifier).setMode(AppMode.pos);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.point_of_sale_rounded, size: 14, color: Color(0xFF34D399)),
                        Gap(6),
                        Text(
                          "🖥️ Kassa Rejimiga O'tish",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF34D399)),
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

  Widget _buildNavItem({
    required String title,
    required IconData icon,
    required int index,
    required int currentIndex,
    String? badge,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    final isSelected = index == currentIndex;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: const Color(0xFFFACC15).withOpacity(0.5), width: 1) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? const Color(0xFFFACC15) : const Color(0xFF94A3B8),
            ),
            const Gap(12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor ?? const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
