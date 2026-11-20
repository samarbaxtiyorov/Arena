// ============================================
// Arena — Maydonlar Asosiy Ekrani (Skrinshot 6 bilan 1:1)
// billiard_page_bg.jpg orqa fon, billiard_logo.jpg nishoni,
// 1 ta band • 5 ta bo'sh, 📅/☁️/QR tugmalari
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/ui_scale_provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../data/repositories/database_providers.dart';
import '../../management/providers/subscription_provider.dart';
import '../providers/tables_providers.dart';
import '../widgets/table_card.dart';
import '../widgets/table_category_chips.dart';
import '../widgets/add_table_dialog.dart';

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
                    child: Row(
                      children: [
                        // 8-ball real surati (Desktopdagi billiard_logo.jpg)
                        Container(
                          width: uiScale.headerAvatarSize,
                          height: uiScale.headerAvatarSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF2563EB),
                              width: 2.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/billiard_logo.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: const Color(0xFF0F172A),
                                child: const Center(
                                  child: Text(
                                    '8',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Gap(12),

                        // Sarlavha va band/bo'sh statusi
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Maydonlar',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const Gap(2),
                              Text(
                                '$activeCount ta band • $idleCount ta bo\'sh',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // O'ng tomondagi 3 ta tugma: 📅, ☁️, QR
                        IconButton(
                          tooltip: 'Sana',
                          icon: const Icon(
                            Icons.calendar_month_outlined,
                            color: Color(0xFF2563EB),
                            size: 22,
                          ),
                          onPressed: () {},
                        ),
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
                                            ? 'Sinxronizatsiya muvaffaqiyatli! (${res.pushed} push, ${res.pulled} pull)'
                                            : (res.wasOffline
                                                ? 'Offline rejim'
                                                : 'Xatolik yuz berdi'),
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
                          tooltip: 'Shtrix-kod skaneri',
                          icon: const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Color(0xFF2563EB),
                            size: 22,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Kamera orqali QR skanerlash tayyor"),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Litsenziya / Sinov Davri Holati Banneri ─────────
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
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
                            const Gap(10),
                            const Expanded(
                              child: Text(
                                "Litsenziya muddati tugagan! O'yinlarni boshlash uchun to'lov qiling.",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF991B1B)),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => context.push('/management/subscription'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                              ),
                              child: const Text("To'lash"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (sub.isTrialActive)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF93C5FD)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.stars_rounded, color: Color(0xFF2563EB), size: 22),
                            const Gap(10),
                            Expanded(
                              child: Text(
                                "🎁 3 kunlik bepul sinov davri faol (${sub.daysRemaining > 0 ? '${sub.daysRemaining} kun' : '${sub.hoursRemaining} soat'} qoldi)",
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF)),
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/management/subscription'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF2563EB),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                              ),
                              child: const Text("Tariflar"),
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
                              const Gap(16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  final auth = ref.read(authProvider);
                                  if (auth.isCashier) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Kassirga maydon qo'shish huquqi berilmagan! Faqat Boshliq qo'sha oladi."),
                                        backgroundColor: Color(0xFFEF4444),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }
                                  showDialog(
                                    context: context,
                                    builder: (_) => const AddTableDialog(),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text("Yangi maydon qo'shish"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final table = filteredTables[index];
                              // Shu stol uchun faol sessiyani topish
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
