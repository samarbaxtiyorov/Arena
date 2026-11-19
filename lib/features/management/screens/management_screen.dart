// ============================================
// Arena — Boshqaruv Markazi (Skrinshotlar 1 va 2 bilan 1:1)
// Boshliq va Kassir ruxsatlari, Obuna tizimi, Sozlamalar
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/ui_scale_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../kassa/providers/kassa_providers.dart';
import 'manage_products_screen.dart';
import 'manage_tables_screen.dart';

class ManagementScreen extends ConsumerWidget {
  const ManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // ── Salom va Sarlavha ────────────────────────────
            Text(
              'Salom, ${auth.userName}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Gap(2),
            const Text(
              'Boshqaruv Markazi',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),

            const Gap(16),

            // ── Boshliq / Profil Kartasi (To'q fon) ──────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Dumaloq avatar (B harfi, ko'k nur)
                  Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0xFF60A5FA), Color(0xFF1D4ED8)],
                        center: Alignment(0, -0.2),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        auth.isOwner ? 'B' : 'K',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              auth.userName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const Gap(8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF064E3B),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                auth.isOwner ? 'EGA' : 'KASSIR',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF34D399),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Gap(3),
                        Text(
                          auth.phone,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Gap(6),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const Gap(6),
                            const Text(
                              'Arena POS • Barcha modullar faol',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w600,
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

            const Gap(24),

            // ── Bo'lim sarlavhasi ─────────────────────────────
            const Text(
              "Boshqaruv Bo'limlari",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),

            const Gap(12),

            // ── 1. Biznes Tahlili va Statistika ───────────────
            _buildMenuCard(
              context: context,
              icon: Icons.trending_up_rounded,
              iconBg: const Color(0xFFE0F2FE),
              iconColor: const Color(0xFF0284C7),
              title: "Biznes Tahlili va Statistika",
              badge: "Tahlil",
              badgeColor: const Color(0xFFE0F2FE),
              badgeTextColor: const Color(0xFF0369A1),
              subtitle: "Kunlik tushum, xarajat, savdo...",
              onTap: () {
                _showAnalyticsDialog(context, ref);
              },
            ),

            const Gap(10),

            // ── 2. Biznes va Tizim Sozlamalari ────────────────
            _buildMenuCard(
              context: context,
              icon: Icons.settings_outlined,
              iconBg: const Color(0xFFDBEAFE),
              iconColor: const Color(0xFF2563EB),
              title: "Biznes va Tizim Sozlamalari",
              badge: "Muhim",
              badgeColor: const Color(0xFFDBEAFE),
              badgeTextColor: const Color(0xFF1D4ED8),
              subtitle: "Tariflar, tungi rejim, aqlli chir...",
              onTap: () {
                _checkOwnerPermission(context, auth, () {
                  _showSettingsDialog(context, ref);
                });
              },
            ),

            const Gap(10),

            // ── 3. Ombor va Mahsulotlar ───────────────────────
            _buildMenuCard(
              context: context,
              icon: Icons.inventory_2_outlined,
              iconBg: const Color(0xFFD1FAE5),
              iconColor: const Color(0xFF059669),
              title: "Ombor va Mahsulotlar",
              subtitle: "Barning barcha tovarlari, nar...",
              onTap: () {
                _checkOwnerPermission(context, auth, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageProductsScreen(),
                    ),
                  );
                });
              },
            ),

            const Gap(10),

            // ── 4. Maydonlar va Stollar ───────────────────────
            _buildMenuCard(
              context: context,
              icon: Icons.sports_soccer_rounded,
              iconBg: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFD97706),
              title: "Maydonlar va Stollar",
              subtitle: "Bilyard, futbol, karaoke, kino...",
              onTap: () {
                _checkOwnerPermission(context, auth, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageTablesScreen(),
                    ),
                  );
                });
              },
            ),

            const Gap(10),

            // ── 5. Xodimlar va Kassirlar ──────────────────────
            _buildMenuCard(
              context: context,
              icon: Icons.group_outlined,
              iconBg: const Color(0xFFF3E8FF),
              iconColor: const Color(0xFF9333EA),
              title: "Xodimlar va Kassirlar",
              subtitle: "Kassirlar ro'yxati, ruxsatlar va...",
              onTap: () {
                _checkOwnerPermission(context, auth, () {
                  _showStaffDialog(context, authNotifier);
                });
              },
            ),

            const Gap(10),

            // ── 6. Tarix va Moliyaviy Hisobotlar ─────────────
            _buildMenuCard(
              context: context,
              icon: Icons.history_rounded,
              iconBg: const Color(0xFFFCE7F3),
              iconColor: const Color(0xFFDB2777),
              title: "Tarix va Moliyaviy Hisobotlar",
              subtitle: "Sotuvlar arxivi, tushumlar va...",
              onTap: () {
                _showFinancialReportDialog(context, ref);
              },
            ),

            const Gap(10),

            // ── 7. Obuna va Litsenziya ────────────────────────
            _buildMenuCard(
              context: context,
              icon: Icons.military_tech_outlined,
              iconBg: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFB45309),
              title: "Obuna va Litsenziya",
              badge: "PREMIUM VIP",
              badgeColor: const Color(0xFFD1FAE5),
              badgeTextColor: const Color(0xFF047857),
              subtitle: "START, PRO va VIP litsenziya...",
              onTap: () {
                _showSubscriptionDialog(context, auth);
              },
            ),

            const Gap(10),

            // ── 8. Xavfsizlik va Audit Jurnali ────────────────
            _buildMenuCard(
              context: context,
              icon: Icons.shield_outlined,
              iconBg: const Color(0xFFF1F5F9),
              iconColor: const Color(0xFF475569),
              title: "Xavfsizlik va Audit Jurnali",
              subtitle: "Kassirlar harakatlari va tizim...",
              onTap: () {
                _showSecurityDialog(context, authNotifier, auth);
              },
            ),

            const Gap(10),

            // ── 9. Tizimdan chiqish ───────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFEE2E2), width: 1.5),
              ),
              child: ListTile(
                onTap: () {
                  authNotifier.logout();
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFEF4444),
                    size: 22,
                  ),
                ),
                title: const Text(
                  "Tizimdan chiqish",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEF4444),
                  ),
                ),
                subtitle: const Text(
                  "Hisobdan xavfsiz chiqish",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFCBD5E1),
                ),
              ),
            ),

            const Gap(20),
          ],
        ),
      ),
    );
  }

  // Ruxsat tekshiruvi (faqat boshliq)
  void _checkOwnerPermission(
      BuildContext context, AuthState auth, VoidCallback onAllowed) {
    if (auth.isOwner) {
      onAllowed();
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: Color(0xFFEF4444)),
              Gap(8),
              Text("Ruxsat Cheklangan"),
            ],
          ),
          content: const Text(
            "Ushbu bo'lim faqat Boshliq (Biznes egasi) uchun ochiq.\nIltimos, Ega PIN-kodi (7777) orqali kiring.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Tushunarli"),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            if (badge != null) ...[
              const Gap(6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor ?? const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeTextColor ?? const Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }

  // ── Obuna va Litsenziya Modali (Arena POS Monizatsiyasi) ─────
  void _showSubscriptionDialog(BuildContext context, AuthState auth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Arena POS Litsenziyasi",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "PREMIUM VIP",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(8),
              const Text(
                "Sizning obunangiz: 2026-yil oxirigacha faol. Barcha modullar (Offline SQLite, Supabase Cloud Sync, Arxiv, Cheklar) cheklovlarsiz ishlaydi.",
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              ),
              const Gap(20),

              // Tariflar
              _buildPlanTile(
                title: "START Reja",
                price: "150 000 so'm / oy",
                desc: "3 tagacha maydon, asosiy kassa va chek chiqarish",
                isCurrent: false,
              ),
              const Gap(8),
              _buildPlanTile(
                title: "PRO Biznes",
                price: "350 000 so'm / oy",
                desc: "10 ta maydon, do'kon ombori, qarz daftari va statistika",
                isCurrent: false,
              ),
              const Gap(8),
              _buildPlanTile(
                title: "PREMIUM VIP",
                price: "600 000 so'm / oy",
                desc: "Cheksiz maydonlar, 2-tomonlama bulut sinxronizatsiyasi, 24/7 qo'llab-quvvatlash",
                isCurrent: true,
              ),

              const Gap(24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Litsenziyani uzaytirish: +998 90 000 00 01 (Samar Baxtiyorov)"),
                        backgroundColor: Color(0xFF2563EB),
                      ),
                    );
                  },
                  icon: const Icon(Icons.verified_rounded),
                  label: const Text("Litsenziyani uzaytirish"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const Gap(16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlanTile({
    required String title,
    required String price,
    required String desc,
    required bool isCurrent,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCurrent ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: isCurrent ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
            size: 20,
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isCurrent ? const Color(0xFF2563EB) : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                const Gap(2),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Biznes Tahlili Dialogi ────────────────────────────────
  void _showAnalyticsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.trending_up_rounded, color: Color(0xFF0284C7)),
            Gap(8),
            Text("Biznes Tahlili"),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Bugungi jami savdo: 100% tahlil faol"),
            Gap(10),
            Text("• Eng ko'p daromad keltirgan maydon: Maydon 1"),
            Text("• Eng ko'p sotilgan bar mahsuloti: Cola 0.5L"),
            Text("• O'rtacha o'yin davomiyligi: 1 soat 15 daqiqa"),
            Gap(10),
            Text(
              "Barcha o'yinlar to'liq Arxiv bo'limida saqlanmoqda.",
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Yopish"),
          ),
        ],
      ),
    );
  }

  // ── Biznes Sozlamalari Dialogi ────────────────────────────
  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final currentScale = ref.watch(uiScaleProvider);
          final scaleNotifier = ref.read(uiScaleProvider.notifier);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: const Row(
              children: [
                Icon(Icons.tune_rounded, color: Color(0xFF2563EB)),
                Gap(8),
                Text(
                  "Tizim va Ekran Sozlamalari",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "EKRAN VA SHRIFT KATTALIGI",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Gap(4),
                  const Text(
                    "O'zingizga qulay ko'rinish va zichlikni tanlang:",
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                  const Gap(12),

                  // 3 xil Kattalik / Zichlik varianti
                  ...UiScale.values.map((scale) {
                    final isSelected = currentScale == scale;
                    return InkWell(
                      onTap: () {
                        scaleNotifier.setScale(scale);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF94A3B8),
                              size: 20,
                            ),
                            const Gap(12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        scale.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: isSelected
                                              ? const Color(0xFF1D4ED8)
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFFDBEAFE)
                                              : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "${scale.textScale}x",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: isSelected
                                                ? const Color(0xFF1D4ED8)
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Gap(2),
                                  Text(
                                    scale.subtitle,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const Gap(16),
                  const Divider(),
                  const Gap(8),

                  const Text(
                    "QO'SHIMCHA FUNKSIYALAR",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Gap(8),

                  const ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.nightlight_round, color: Color(0xFF2563EB)),
                    title: Text("Tungi tarif (22:00 - 06:00)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text("Soatiga +20 000 so'm qo'shimcha", style: TextStyle(fontSize: 11)),
                    trailing: Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                  ),
                  const ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.lightbulb_outline, color: Color(0xFFF59E0B)),
                    title: Text("Aqlli chiroqlar (Smart Relay)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text("O'yin boshlanganda avtomatik yonadi", style: TextStyle(fontSize: 11)),
                    trailing: Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Saqlash"),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Xodimlar va Kassirlar Dialogi ─────────────────────────
  void _showStaffDialog(BuildContext context, AuthNotifier authNotifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Xodimlar va Kassirlar"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF2563EB),
                child: Text("B", style: TextStyle(color: Colors.white)),
              ),
              title: const Text("Biznes egasi (EGA)"),
              subtitle: const Text("PIN: 7777 • Cheksiz ruxsat"),
              trailing: ElevatedButton(
                onPressed: () {
                  authNotifier.switchRole(UserRole.owner);
                  Navigator.pop(ctx);
                },
                child: const Text("Tanlash"),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF9333EA),
                child: Text("K", style: TextStyle(color: Colors.white)),
              ),
              title: const Text("Kassir Samar (KASSIR)"),
              subtitle: const Text("PIN: 1111 • Faqat savdo va kassa"),
              trailing: ElevatedButton(
                onPressed: () {
                  authNotifier.switchRole(UserRole.cashier);
                  Navigator.pop(ctx);
                },
                child: const Text("Tanlash"),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Yopish"),
          ),
        ],
      ),
    );
  }

  // ── Moliyaviy Hisobotlar Dialogi ──────────────────────────
  void _showFinancialReportDialog(BuildContext context, WidgetRef ref) {
    final cashAsync = ref.watch(allCashRecordsProvider);
    final records = cashAsync.value ?? [];

    int income = 0;
    int expense = 0;
    for (final r in records) {
      if (r.type == 'income') income += r.amount.toInt();
      if (r.type == 'expense') expense += r.amount.toInt();
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.history_rounded, color: Color(0xFFDB2777)),
            Gap(8),
            Text("Moliyaviy Hisobot"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Jami Kirim: ${formatSum(income)}",
                style: const TextStyle(
                    color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
            const Gap(6),
            Text("Jami Chiqim: ${formatSum(expense)}",
                style: const TextStyle(
                    color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
            const Gap(6),
            Text("Sof Foyda: ${formatSum(income - expense)}",
                style: const TextStyle(
                    color: Color(0xFF2563EB), fontWeight: FontWeight.w900)),
            const Gap(12),
            Text("Kassa operatsiyalari soni: ${records.length} ta"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Yopish"),
          ),
        ],
      ),
    );
  }

  // ── Xavfsizlik Dialogi ────────────────────────────────────
  void _showSecurityDialog(
      BuildContext context, AuthNotifier authNotifier, AuthState auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Xavfsizlik va PIN"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Hozirgi profil:"),
            const Gap(6),
            Text(
              "${auth.userName} (${auth.isOwner ? 'Boshliq' : 'Kassir'})",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Gap(14),
            const Text("Ega PIN-kodi: 7777"),
            const Text("Kassir PIN-kodi: 1111"),
            const Gap(14),
            const Text("Audit jurnali: Har bir sessiya va to'lov vaqti qayd etiladi."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Yopish"),
          ),
        ],
      ),
    );
  }
}
