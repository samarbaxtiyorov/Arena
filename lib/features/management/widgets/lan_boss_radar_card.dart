// ============================================
// Arena Boss — Jonli Kassa Radari (LAN Live Link Widget)
// Uydagi yoki klubdagi Wi-Fi orqali Arena POS ga to'g'ridan-to'g'ri ulanish
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/services/lan_boss_client.dart';
import '../../../core/utils/formatters.dart';

class LanBossRadarCard extends ConsumerStatefulWidget {
  const LanBossRadarCard({super.key});

  @override
  ConsumerState<LanBossRadarCard> createState() => _LanBossRadarCardState();
}

class _LanBossRadarCardState extends ConsumerState<LanBossRadarCard> {
  final TextEditingController _ipController = TextEditingController(text: '192.168.0.');
  bool _isConnecting = false;

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _handleConnect() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;

    setState(() => _isConnecting = true);
    final client = ref.read(lanBossClientProvider.notifier);
    final success = await client.connectToCashier(ip);
    setState(() => _isConnecting = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Arena POS Kassa bilan muvaffaqiyatli bog'lanildi!"),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Kassa bilan bog'lanib bo'lmadi. IP va Wi-Fi ni tekshiring."),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleAutoScan() async {
    setState(() => _isConnecting = true);
    final client = ref.read(lanBossClientProvider.notifier);
    final foundIp = await client.autoDiscoverCashier();
    setState(() => _isConnecting = false);

    if (mounted) {
      if (foundIp != null) {
        _ipController.text = foundIp;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🎉 Kassa topildi va ulandi: $foundIp!"),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Tarmoqda ochiq Arena POS kassa topilmadi. IP manzilini qo'lda kiriting."),
            backgroundColor: Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lanState = ref.watch(lanBossClientProvider);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: lanState.isConnected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
          width: lanState.isConnected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: lanState.isConnected
                ? const Color(0xFF10B981).withOpacity(0.08)
                : Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sarlavha qatori
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: lanState.isConnected
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  lanState.isConnected ? Icons.sensors_rounded : Icons.sensors_off_rounded,
                  color: lanState.isConnected ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                  size: 22,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Jonli Kassa Radari",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const Gap(8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: lanState.isConnected
                                ? const Color(0xFF10B981).withOpacity(0.15)
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            lanState.isConnected ? "JONLI ALOQA" : "OFFLINE",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: lanState.isConnected
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      lanState.isConnected
                          ? "Kassa: ${lanState.cashierIp}:${lanState.port} (Har 3 sek yangilanadi)"
                          : "Uydagi/klubdagi Wi-Fi orqali kassir kompyuteriga to'g'ridan-to'g'ri ulanish",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (lanState.isConnected)
                IconButton(
                  tooltip: "Aloqani uzish",
                  icon: const Icon(Icons.link_off_rounded, color: Color(0xFFEF4444)),
                  onPressed: () {
                    ref.read(lanBossClientProvider.notifier).disconnect();
                  },
                ),
            ],
          ),

          const Gap(14),

          // Agar ulanmagan bo'lsa: IP kiritish va Skanerlash paneli
          if (!lanState.isConnected) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ipController,
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: "Kassa IP manzili (masalan: 192.168.0.196)",
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.wifi_rounded, size: 20, color: Color(0xFF2563EB)),
                          ),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Gap(8),
                      ElevatedButton(
                        onPressed: _isConnecting ? null : _handleConnect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        child: _isConnecting
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text("Ulanish", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Kassa IP manzilini bilmaysizmi?",
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      TextButton.icon(
                        onPressed: lanState.isScanning ? null : _handleAutoScan,
                        icon: lanState.isScanning
                            ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5))
                            : const Icon(Icons.radar_rounded, size: 16),
                        label: Text(
                          lanState.isScanning ? "Qidirilmoqda..." : "Avto Qidirish",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // Agar ulangan bo'lsa: JONLI STATISTIKA
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("BAND STOLLAR", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF16A34A))),
                        const Gap(2),
                        Text(
                          "${lanState.activeTablesCount} ta band",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("BUGUNGI TUSHUM", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
                        const Gap(2),
                        Text(
                          formatSum(lanState.todayRevenue),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (lanState.liveTables.isNotEmpty) ...[
              const Gap(12),
              const Text("Stollar holati:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
              const Gap(8),
              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: lanState.liveTables.length,
                  separatorBuilder: (_, __) => const Gap(8),
                  itemBuilder: (context, idx) {
                    final t = lanState.liveTables[idx];
                    final isActive = t['isActive'] == true;
                    return Container(
                      width: 130,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                          width: isActive ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                ),
                              ),
                              const Gap(6),
                              Expanded(
                                child: Text(
                                  t['name'] ?? 'Stol',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isActive ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Gap(4),
                          Text(
                            isActive ? "🟢 O'yin ketmoqda" : "⚪ Bo'sh",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isActive ? const Color(0xFF34D399) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
