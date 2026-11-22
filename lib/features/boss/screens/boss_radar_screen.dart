// ============================================
// Arena Boss — Jonli Zal Radari (Executive Live Hall Radar)
// Ega uchun maxsus: Kassaga aralashmasdan butun zalni va kassani jonli kuzatish
// ============================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/providers/business_account_provider.dart';
import '../../../core/services/lan_boss_client.dart';
import '../../../core/utils/formatters.dart';
import '../../tables/providers/tables_providers.dart';

class BossRadarScreen extends ConsumerStatefulWidget {
  const BossRadarScreen({super.key});

  @override
  ConsumerState<BossRadarScreen> createState() => _BossRadarScreenState();
}

class _BossRadarScreenState extends ConsumerState<BossRadarScreen> {
  Timer? _tickerTimer;
  final TextEditingController _ipController = TextEditingController(text: '192.168.0.');
  bool _isAutoConnecting = false;

  @override
  void initState() {
    super.initState();
    // Soniyalarni jonli hisoblash uchun har 1 soniyada tick berish
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    // Boshlang'ichda avtomatik kassa bilan bog'lanishni tekshirish
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final client = ref.read(lanBossClientProvider);
      if (!client.isConnected) {
        _autoScan();
      }
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _connect(String ip) async {
    setState(() => _isAutoConnecting = true);
    final client = ref.read(lanBossClientProvider.notifier);
    final success = await client.connectToCashier(ip);
    setState(() => _isAutoConnecting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? "🟢 Kassa bilan jonli aloqa o'rnatildi!" : "❌ Kassa topilmadi. IP ni tekshiring."),
          backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _autoScan() async {
    setState(() => _isAutoConnecting = true);
    final client = ref.read(lanBossClientProvider.notifier);
    final foundIp = await client.autoDiscoverCashier();
    setState(() => _isAutoConnecting = false);

    if (mounted && foundIp != null) {
      _ipController.text = foundIp;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lanState = ref.watch(lanBossClientProvider);
    final business = ref.watch(businessAccountProvider).activeAccount;
    final auth = ref.watch(authProvider);

    // Agar kassa LAN orqali ulanmagan bo'lsa, lokal bazadan olamiz (fallback)
    final localTablesAsync = ref.watch(tablesStreamProvider);
    final localSessionsAsync = ref.watch(activeSessionsStreamProvider);

    final localTables = localTablesAsync.value ?? [];
    final localSessions = localSessionsAsync.value ?? [];
    final sessionMap = {for (final s in localSessions) s.tableId: s};

    final isLanLive = lanState.isConnected;
    final activeCount = isLanLive ? lanState.activeTablesCount : localSessions.length;
    final totalCount = isLanLive ? lanState.totalTablesCount : localTables.length;
    final todayRevenue = isLanLive ? lanState.todayRevenue : 0.0;
    final todayCash = isLanLive ? lanState.todayCash : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Luxury Executive Titanium Dark
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── 1. Boss Header Paneli ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAB308).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEAB308), width: 1.5),
                      ),
                      child: const Center(
                        child: Text("👑", style: TextStyle(fontSize: 24)),
                      ),
                    ),
                    const Gap(14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                "ARENA BOSS",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFFACC15),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Gap(8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF334155)),
                                ),
                                child: const Text(
                                  "XO'JAYIN MONITORI",
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            business?.venueName ?? 'Bilyard & Sport Klubi',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFE2E8F0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Foydalanuvchi va Qulflash
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_rounded, color: Color(0xFFFACC15), size: 16),
                          const Gap(6),
                          Text(
                            auth.userName.isNotEmpty ? auth.userName : "Boshliq",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 2. Jonli Kassa Ulanish Holati (LAN Banner) ──────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isLanLive ? const Color(0xFF064E3B).withOpacity(0.6) : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isLanLive ? const Color(0xFF10B981) : const Color(0xFF334155),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isLanLive ? const Color(0xFF34D399) : const Color(0xFFF59E0B),
                          boxShadow: [
                            BoxShadow(
                              color: (isLanLive ? const Color(0xFF34D399) : const Color(0xFFF59E0B)).withOpacity(0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: Text(
                          isLanLive
                              ? "🟢 Kassa bilan jonli aloqa faol (${lanState.cashierIp}:${lanState.port}) • Har 3 sek yangilanmoqda"
                              : "🟡 Kassa bilan Wi-Fi aloqasi yo'q. Ulanish uchun IP kiriting yoki avto qidiring.",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isLanLive ? const Color(0xFF6EE7B7) : const Color(0xFFFDE68A),
                          ),
                        ),
                      ),
                      if (!isLanLive) ...[
                        SizedBox(
                          width: 150,
                          height: 32,
                          child: TextField(
                            controller: _ipController,
                            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              hintText: "Kassa IP",
                              hintStyle: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                            ),
                          ),
                        ),
                        const Gap(8),
                        ElevatedButton(
                          onPressed: _isAutoConnecting ? null : () => _connect(_ipController.text.trim()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                          child: _isAutoConnecting
                              ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))
                              : const Text("Ulanish"),
                        ),
                        const Gap(6),
                        IconButton(
                          tooltip: "Avto qidirish",
                          icon: const Icon(Icons.radar_rounded, color: Color(0xFF38BDF8), size: 18),
                          onPressed: _isAutoConnecting ? null : _autoScan,
                        ),
                      ] else ...[
                        IconButton(
                          tooltip: "Yangilash",
                          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF34D399), size: 20),
                          onPressed: () => ref.read(lanBossClientProvider.notifier).refreshLiveStatus(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: Gap(16)),

            // ── 3. Jonli Asosiy Ko'rsatkichlar (KPI Metrikalar) ──────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // 1. Band Stollar
                    Expanded(
                      child: _buildKpiCard(
                        title: "BAND STOLLAR",
                        value: "$activeCount / $totalCount",
                        subtitle: "${totalCount - activeCount} ta bo'sh",
                        color: const Color(0xFF10B981),
                        icon: Icons.sports_volleyball_rounded,
                      ),
                    ),
                    const Gap(12),
                    // 2. Bugungi Tushum
                    Expanded(
                      child: _buildKpiCard(
                        title: "BUGUNGI KASSA",
                        value: formatSum(todayRevenue.toInt()),
                        subtitle: "Naqd: ${formatSum(todayCash.toInt())}",
                        color: const Color(0xFF38BDF8),
                        icon: Icons.point_of_sale_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: Gap(22)),

            // ── 4. Zal Radari Sarlavhasi ────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.sensors_rounded, color: Color(0xFFFACC15), size: 20),
                        Gap(8),
                        Text(
                          "Bilyard Zali — Jonli Holat",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
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
                            "0-ms Sinxron",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: Gap(12)),

            // ── 5. Bilyard Stollarining VIP Jonli Kartalari ──────────
            if (isLanLive && lanState.liveTables.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 360,
                    mainAxisExtent: 220,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, idx) {
                      final t = lanState.liveTables[idx];
                      return _buildLiveTableCardFromLan(t);
                    },
                    childCount: lanState.liveTables.length,
                  ),
                ),
              ),
            ] else if (localTables.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 360,
                    mainAxisExtent: 220,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, idx) {
                      final t = localTables[idx];
                      final s = sessionMap[t.id];
                      return _buildLiveTableCardFromLocal(t, s);
                    },
                    childCount: localTables.length,
                  ),
                ),
              ),
            ] else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.table_restaurant_outlined, size: 48, color: Color(0xFF64748B)),
                        const Gap(12),
                        const Text(
                          "Hozircha stollar ma'lumoti yuklanmadi",
                          style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w700),
                        ),
                        const Gap(8),
                        TextButton(
                          onPressed: () => context.go('/boss/tables'),
                          child: const Text("Boshqaruv markazidan stol qo'shish ➡️"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: Gap(30)),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                ),
                const Gap(2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTableCardFromLan(Map<String, dynamic> t) {
    final isActive = t['isActive'] == true;
    final name = t['name'] ?? 'Stol';
    final rate = (t['hourlyRate'] as num?)?.toInt() ?? 30000;
    final session = t['session'] as Map<String, dynamic>?;

    String durationStr = "00:00:00";
    int currentBill = 0;

    if (isActive && session != null) {
      final startStr = session['startedAt'] as String?;
      if (startStr != null) {
        final start = DateTime.tryParse(startStr);
        if (start != null) {
          final diff = DateTime.now().difference(start);
          final hours = diff.inHours.toString().padLeft(2, '0');
          final mins = (diff.inMinutes % 60).toString().padLeft(2, '0');
          final secs = (diff.inSeconds % 60).toString().padLeft(2, '0');
          durationStr = "$hours:$mins:$secs";

          final minutes = diff.inMinutes;
          currentBill = ((minutes / 60.0) * rate).round();
        }
      }
    }

    return _buildCardUI(
      name: name,
      rate: rate,
      isActive: isActive,
      durationStr: durationStr,
      currentBill: currentBill,
      notes: session?['notes'],
    );
  }

  Widget _buildLiveTableCardFromLocal(dynamic t, dynamic s) {
    final isActive = s != null && s.status == 'active';
    final name = t.name;
    final rate = t.pricePerHour;

    String durationStr = "00:00:00";
    int currentBill = 0;

    if (isActive) {
      final start = s.startedAt;
      final diff = DateTime.now().difference(start);
      final hours = diff.inHours.toString().padLeft(2, '0');
      final mins = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final secs = (diff.inSeconds % 60).toString().padLeft(2, '0');
      durationStr = "$hours:$mins:$secs";

      final minutes = diff.inMinutes;
      currentBill = ((minutes / 60.0) * rate).round();
    }

    return _buildCardUI(
      name: name,
      rate: rate,
      isActive: isActive,
      durationStr: durationStr,
      currentBill: currentBill,
      notes: s?.notes,
    );
  }

  Widget _buildCardUI({
    required String name,
    required int rate,
    required bool isActive,
    required String durationStr,
    required int currentBill,
    String? notes,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? const Color(0xFF10B981) : const Color(0xFF334155),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive ? const Color(0xFF10B981).withOpacity(0.15) : Colors.black.withOpacity(0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sarlavha
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? const Color(0xFF10B981) : const Color(0xFF64748B),
                ),
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF064E3B) : const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? "🟢 O'YIN KETMOQDA" : "⚪ BO'SH",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: isActive ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),

          const Divider(color: Color(0xFF334155), height: 20),

          // Taymer va hisob
          if (isActive) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("O'YIN VAQTI", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
                    const Gap(2),
                    Text(
                      durationStr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF38BDF8),
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("HOZIRGI HISOB", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
                    const Gap(2),
                    Text(
                      formatSum(currentBill),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF34D399)),
                    ),
                  ],
                ),
              ],
            ),
            const Gap(8),
            // Chiroq statusi
            Row(
              children: [
                const Icon(Icons.lightbulb_rounded, size: 14, color: Color(0xFFFACC15)),
                const Gap(4),
                const Text("Chiroq: 💡 YONIQ", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFFDE68A))),
                const Spacer(),
                Text(
                  "Tarif: ${formatSum(rate)}/soat",
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ] else ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.nightlight_round, size: 28, color: Color(0xFF475569)),
                    const Gap(6),
                    Text(
                      "Tarif: ${formatSum(rate)}/soat",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                    ),
                    const Text("Chiroq: 🌑 O'chiq", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
