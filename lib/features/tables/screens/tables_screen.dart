// ============================================
// Arena — Maydonlar Asosiy Ekrani (Skrinshot 6 bilan 1:1)
// billiard_page_bg.jpg orqa fon, billiard_logo.jpg nishoni,
// 1 ta band • 5 ta bo'sh, 📅/☁️/QR tugmalari
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/ui_scale_provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/providers/business_account_provider.dart';
import '../../../core/widgets/arena_logo.dart';
import '../../../data/repositories/database_providers.dart';
import '../../management/providers/subscription_provider.dart';
import '../providers/tables_providers.dart';
import '../widgets/table_card.dart';
import '../widgets/table_category_chips.dart';
import '../../../core/services/lan_pos_server.dart';

class TablesScreen extends ConsumerWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredTables = ref.watch(filteredTablesProvider);
    final activeSessionsAsync = ref.watch(activeSessionsStreamProvider);
    final allTablesAsync = ref.watch(tablesStreamProvider);
    final selectedCategory = ref.watch(tableCategoryProvider);
    final uiScale = ref.watch(uiScaleProvider);

    final activeSessions = activeSessionsAsync.value ?? [];
    final allTables = allTablesAsync.value ?? [];
    final sub = ref.watch(subscriptionProvider);

    final activeCount = activeSessions.where((s) => s.status == 'active').length;
    final idleCount = (allTables.length - activeCount).clamp(0, 999);

    String sectionTitle;
    switch (selectedCategory) {
      case 'football':
        sectionTitle = 'Futbol Maydonlari';
        break;
      case 'billiard':
        sectionTitle = 'Bilyard Stollari';
        break;
      case 'ps':
        sectionTitle = 'PlayStation Xonalari';
        break;
      case 'tennis':
        sectionTitle = 'Tennis Kortlari';
        break;
      default:
        sectionTitle = 'Barcha Maydonlar va Stollar';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // ── Orqa fon (Desktop/Arena_Rasmlar/billiard_page_bg.jpg) ──
          Positioned.fill(
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                'assets/images/billiard_page_bg.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(),
              ),
            ),
          ),

          // Nozik yorug'lik gradienti
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFEFF6FF).withOpacity(0.85),
                    const Color(0xFFF8FAFC).withOpacity(0.96),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── Sarlavha Qatori (billiard_logo.jpg, Maydonlar, 📅/☁️/QR) ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Builder(
                      builder: (context) {
                        final isCompact = MediaQuery.sizeOf(context).width < 650;

                        return Row(
                          children: [
                            // Arena Brend Logotipi
                            ArenaLogo(
                              size: isCompact ? 40 : uiScale.headerAvatarSize,
                              borderRadius: isCompact ? 12 : uiScale.headerAvatarSize / 2,
                            ),
                            const Gap(10),

                            // Sarlavha va band/bo'sh statusi
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Maydonlar',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: isCompact ? 19 : 22,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF0F172A),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const Gap(2),
                                  Text(
                                    '$activeCount ta band • $idleCount ta bo\'sh',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: isCompact ? 11.5 : 13,
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Builder(
                                    builder: (context) {
                                      final lan = ref.watch(lanPosServerProvider);
                                      if (!lan.isRunning || lan.localIp == null) {
                                        return const SizedBox();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          '🟢 LAN: ${lan.localIp}:${lan.port}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF16A34A),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // Mobil ko'rinishda: qo'shimcha menyu (⋮)
                            if (isCompact) ...[
                              PopupMenuButton<String>(
                                tooltip: 'Amallar menyusi',
                                icon: const Icon(
                                  Icons.more_vert_rounded,
                                  color: Color(0xFF475569),
                                  size: 22,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                onSelected: (val) async {
                                  if (val == 'sync') {
                                    final sync = ref.read(syncServiceProvider);
                                    final res = await sync.syncAll();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            res.isSuccess
                                                ? 'Sinxronizatsiya muvaffaqiyatli! (${res.pulled} ta yuklandi, ${res.pushed} ta yuborildi)'
                                                : (res.wasOffline
                                                    ? 'Internet aloqasi yo\'q (Oflayn rejim)'
                                                    : 'Sinxronizatsiyada xatolik: ${res.errors.join(", ")}'),
                                          ),
                                          backgroundColor: res.isSuccess
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFF59E0B),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  } else if (val == 'logout') {
                                    ref.read(authProvider.notifier).logout();
                                    ref.read(businessAccountProvider.notifier).logout();
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'sync',
                                    child: Row(
                                      children: [
                                        Icon(Icons.cloud_done_rounded,
                                            color: Color(0xFF10B981), size: 18),
                                        Gap(10),
                                        Text("Bulut sinxronizatsiyasi",
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'logout',
                                    child: Row(
                                      children: [
                                        Icon(Icons.logout_rounded,
                                            color: Color(0xFFEF4444), size: 18),
                                        Gap(10),
                                        Text("Tizimdan chiqish",
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFFEF4444))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Consumer(
                                builder: (context, ref, _) {
                                  return IconButton(
                                    tooltip: 'Bulut sinxronizatsiyasi',
                                    icon: const Icon(
                                      Icons.cloud_done_rounded,
                                      color: Color(0xFF10B981),
                                      size: 24,
                                    ),
                                    onPressed: () async {
                                      final sync = ref.read(syncServiceProvider);
                                      final res = await sync.syncAll();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              res.isSuccess
                                                  ? 'Sinxronizatsiya muvaffaqiyatli! (${res.pulled} ta yuklandi, ${res.pushed} ta yuborildi)'
                                                  : (res.wasOffline
                                                      ? 'Internet aloqasi yo\'q (Oflayn rejim)'
                                                      : 'Sinxronizatsiyada xatolik: ${res.errors.join(", ")}'),
                                            ),
                                            backgroundColor: res.isSuccess
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFF59E0B),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                              IconButton(
                                tooltip: 'Tizimdan chiqish',
                                icon: const Icon(
                                  Icons.logout_rounded,
                                  color: Color(0xFF94A3B8),
                                  size: 22,
                                ),
                                onPressed: () {
                                  ref.read(authProvider.notifier).logout();
                                  ref.read(businessAccountProvider.notifier).logout();
                                },
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // ── Litsenziya Holati Banneri ─────────
                if (sub.isExpired)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF87171)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
                            Gap(10),
                            Expanded(
                              child: Text(
                                "Litsenziya muddati tugagan! O'yinlarni davom ettirish uchun klub rahbariga murojaat qiling.",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF991B1B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ── Kategoriya Chiplari (Barchasi, Futbol, Bilyard) ──
                const SliverToBoxAdapter(
                  child: TableCategoryChips(),
                ),

                const SliverToBoxAdapter(child: Gap(16)),

                // ── Bo'lim Sarlavhasi (| Futbol Maydonlari) ─────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const Gap(8),
                        Text(
                          sectionTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: Gap(14)),

                // ── Maydonlar Ro'yxati ─────────────────────────────
                filteredTables.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.sports_soccer_outlined,
                                size: 48,
                                color: Color(0xFF94A3B8),
                              ),
                              const Gap(12),
                              const Text(
                                "Maydonlar topilmadi",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const Gap(8),
                              const Text(
                                "Hozircha birorta ham maydon yoki stol kiritilmagan.\nBoshliq tomonidan stollar qo'shilgach, bu yerda ko'rinadi.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const Gap(16),
                              TextButton.icon(
                                onPressed: () async {
                                  final sync = ref.read(syncServiceProvider);
                                  final res = await sync.syncAll();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(res.isSuccess
                                            ? 'Bulut bilan muvaffaqiyatli sinxronlandi! (${res.pulled} ta yuklandi, ${res.pushed} ta yuborildi)'
                                            : (res.wasOffline
                                                ? 'Internet aloqasi yo\'q (Oflayn rejim)'
                                                : 'Sinxronizatsiyada xatolik: ${res.errors.join(", ")}')),
                                        backgroundColor: res.isSuccess
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFF59E0B),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.cloud_sync_rounded, size: 18),
                                label: const Text("Bulutdan yangilash (Sinxronlash)"),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: MediaQuery.of(context).size.width >= 850
                            ? SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 480,
                                  mainAxisExtent: 480,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final table = filteredTables[index];
                                    final session = activeSessions
                                        .where((s) => s.tableId == table.id)
                                        .firstOrNull;

                                    return TableCard(
                                      table: table,
                                      activeSession: session,
                                      index: index + 1,
                                    );
                                  },
                                  childCount: filteredTables.length,
                                ),
                              )
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final table = filteredTables[index];
                                    final session = activeSessions
                                        .where((s) => s.tableId == table.id)
                                        .firstOrNull;

                                    return TableCard(
                                      table: table,
                                      activeSession: session,
                                      index: index + 1,
                                    );
                                  },
                                  childCount: filteredTables.length,
                                ),
                              ),
                      ),

                const SliverToBoxAdapter(child: Gap(30)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
