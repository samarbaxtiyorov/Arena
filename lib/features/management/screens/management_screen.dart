// ============================================
// Arena — Boshqaruv Markazi (Skrinshotlar 1 va 2 bilan 1:1)
// Boshliq va Kassir ruxsatlari, Obuna tizimi, Sozlamalar
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/providers/business_account_provider.dart';
import '../../../data/repositories/database_providers.dart';
import 'analytics_screen.dart';
import 'business_settings_screen.dart';
import 'manage_products_screen.dart';
import 'manage_staff_screen.dart';
import 'manage_tables_screen.dart';
import 'subscription_screen.dart';

class ManagementScreen extends ConsumerWidget {
  const ManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final businessState = ref.watch(businessAccountProvider);
    final activeVenue = businessState.activeAccount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // ── Salom va Sarlavha ────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salom, ${auth.userName}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Gap(2),
                Text(
                  activeVenue?.venueName ?? 'Boshqaruv Markazi',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AnalyticsScreen(),
                  ),
                );
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
              subtitle: "Aqlli chiroqlar, to'lov kartasi, printer...",
              onTap: () {
                _checkOwnerPermission(context, auth, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BusinessSettingsScreen(),
                    ),
                  );
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
              subtitle: "Kassirlar ro'yxati, PIN-kodlar va...",
              onTap: () {
                _checkOwnerPermission(context, auth, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageStaffScreen(),
                    ),
                  );
                });
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
              badge: "Har bir stol 100 000",
              badgeColor: const Color(0xFFD1FAE5),
              badgeTextColor: const Color(0xFF047857),
              subtitle: "Tariflar, muddatlar va TezCheck to'lov...",
              onTap: () {
                _checkOwnerPermission(context, auth, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionScreen(),
                    ),
                  );
                });
              },
            ),

            const Gap(10),

            // ── 8. Xavfsizlik va Bulut Zaxirasi ──────────────
            _buildMenuCard(
              context: context,
              icon: Icons.shield_outlined,
              iconBg: const Color(0xFFF1F5F9),
              iconColor: const Color(0xFF475569),
              title: "Xavfsizlik va Bulut Zaxirasi",
              subtitle: "Ma'lumotlar bazasi, SHA-256 va sinxronizatsiya",
              onTap: () {
                _showSecurityDialog(context, authNotifier, auth, ref);
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


  // ── Xavfsizlik va Bulut Paneli ───────────────────────────
  void _showSecurityDialog(
      BuildContext context, AuthNotifier authNotifier, AuthState auth, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isSyncing = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Gap(16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.security_rounded,
                          color: Color(0xFF2563EB),
                          size: 24,
                        ),
                      ),
                      const Gap(12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Xavfsizlik va Ma'lumotlar",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            "Bank darajasidagi himoya va Bulut sinxronizatsiyasi",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Gap(20),

                  // 1. Bulut holati
                  _buildSecurityRow(
                    icon: Icons.cloud_done_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: "Bulutli Zaxira (Supabase Cloud)",
                    desc: "Ulangan: PostgreSQL Cloud orqali avtomatik zaxiralanadi",
                    badge: "ONLINE",
                    badgeColor: const Color(0xFFD1FAE5),
                    badgeTextColor: const Color(0xFF047857),
                  ),
                  const Gap(12),

                  // 2. Lokal oflayn baza
                  _buildSecurityRow(
                    icon: Icons.storage_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    title: "Lokal Xotira (Offline SQLite)",
                    desc: "Har bir poliya o'zining mustaqil shifrlangan bazasida ishlaydi",
                    badge: "IZOLYATSIYA",
                    badgeColor: const Color(0xFFDBEAFE),
                    badgeTextColor: const Color(0xFF1D4ED8),
                  ),
                  const Gap(12),

                  // 3. SHA-256 Kriptografik xesh
                  _buildSecurityRow(
                    icon: Icons.lock_outline_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    title: "Parollar Himoyasi (SHA-256)",
                    desc: "Parollar ochiq saqlanmaydi, kriptografik xesh bilan shifrlangan",
                    badge: "SHA-256",
                    badgeColor: const Color(0xFFEDE9FE),
                    badgeTextColor: const Color(0xFF6D28D9),
                  ),
                  const Gap(12),

                  // 4. Brute-Force PIN blokirovkasi
                  _buildSecurityRow(
                    icon: Icons.timer_outlined,
                    iconColor: const Color(0xFFF59E0B),
                    title: "PIN-kod Brute-Force Himoyasi",
                    desc: "5 marta xato PIN kiritilsa, tizim 30 soniyaga avtomatik qulflanadi",
                    badge: "ANTI-HACK",
                    badgeColor: const Color(0xFFFEF3C7),
                    badgeTextColor: const Color(0xFFB45309),
                  ),

                  const Gap(24),

                  // Qo'lda sinxronlash tugmasi
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSyncing
                          ? null
                          : () async {
                              setModalState(() => isSyncing = true);
                              try {
                                await ref.read(syncServiceProvider).syncAll();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Barcha ma'lumotlar bulutga muvaffaqiyatli sinxronlandi!"),
                                      backgroundColor: Color(0xFF10B981),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Sinxronlash xatosi: $e"),
                                      backgroundColor: const Color(0xFFEF4444),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } finally {
                                setModalState(() => isSyncing = false);
                              }
                            },
                      icon: isSyncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.sync_rounded),
                      label: Text(
                        isSyncing
                            ? "Bulutga yuklanmoqda..."
                            : "Hozir Sinxronlash (Bulutga zaxiralash)",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const Gap(10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildSecurityRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required String badge,
    required Color badgeColor,
    required Color badgeTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
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
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(3),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
