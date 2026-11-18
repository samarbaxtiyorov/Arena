// ============================================
// Arena — O'yinlar Arxivi Ekrani (Skrinshot 4 bilan 1:1)
// Qorong'i mavzu (#070B14, #0F172A), 4 ta metrika,
// Qidiruv, Sana filtrlari va mukammal o'yin cheklari
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/receipt_generator.dart';
import '../../../data/local/app_database.dart';
import '../../kassa/widgets/receipt_preview_dialog.dart';
import '../providers/archive_providers.dart';

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(archiveStatsProvider);
    final filter = ref.watch(archiveFilterProvider);
    final filterNotifier = ref.read(archiveFilterProvider.notifier);
    final gamesAsync = ref.watch(archiveGamesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Sarlavha Qatori ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: Color(0xFF60A5FA),
                        size: 24,
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
                                "O'yinlar Arxivi",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const Gap(8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF334155),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '${stats.gamesCount} ta o\'yin',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF38BDF8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Gap(2),
                          const Text(
                            "Bugungi yakunlangan o'yinlar va cheklar",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 4 ta Metrika Kartalari (2x2 Grid) ──────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDarkStatCard(
                            icon: Icons.sports_esports_rounded,
                            iconBg: const Color(0xFF1E293B),
                            iconColor: const Color(0xFF94A3B8),
                            label: "O'YINLAR SONI",
                            value: '${stats.gamesCount} ta',
                            valueColor: Colors.white,
                          ),
                        ),
                        const Gap(10),
                        Expanded(
                          child: _buildDarkStatCard(
                            icon: Icons.account_balance_wallet_rounded,
                            iconBg: const Color(0xFF064E3B),
                            iconColor: const Color(0xFF34D399),
                            label: "JAMI TUSHUM",
                            value: formatSum(stats.totalRevenue),
                            valueColor: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const Gap(10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDarkStatCard(
                            icon: Icons.timer_outlined,
                            iconBg: const Color(0xFF083344),
                            iconColor: const Color(0xFF22D3EE),
                            label: "O'YIN TUSHUMI",
                            value: formatSum(stats.gameRevenue),
                            valueColor: const Color(0xFF22D3EE),
                          ),
                        ),
                        const Gap(10),
                        Expanded(
                          child: _buildDarkStatCard(
                            icon: Icons.local_cafe_rounded,
                            iconBg: const Color(0xFF451A03),
                            iconColor: const Color(0xFFFBBF24),
                            label: "BAR TUSHUMI",
                            value: formatSum(stats.barRevenue),
                            valueColor: const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: Gap(16)),

            // ── Qidiruv va Sana Tanlash Qatori ─────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Qidiruv maydoni
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF1E293B),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          onChanged: filterNotifier.setSearch,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          decoration: const InputDecoration(
                            hintText: "Stol, o'yinchi yoki izoh bo'yi...",
                            hintStyle: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const Gap(10),
                    // Sana tugmasi
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2023),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFF2563EB),
                                  onPrimary: Colors.white,
                                  surface: Color(0xFF0F172A),
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          filterNotifier.setCustomDate(picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF1D4ED8),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              color: Color(0xFF38BDF8),
                              size: 18,
                            ),
                            const Gap(6),
                            Text(
                              filter.customDate != null
                                  ? DateFormat('dd.MM').format(filter.customDate!)
                                  : "Sana...",
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: Gap(12)),

            // ── Sana Filtrlari (Pills) ─────────────────────────
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildDatePill(
                      label: "Bugun",
                      isSelected: filter.dateFilter == ArchiveDateFilter.today &&
                          filter.customDate == null,
                      onTap: () => filterNotifier.setFilter(ArchiveDateFilter.today),
                    ),
                    const Gap(8),
                    _buildDatePill(
                      label: "Kecha",
                      isSelected:
                          filter.dateFilter == ArchiveDateFilter.yesterday &&
                              filter.customDate == null,
                      onTap: () =>
                          filterNotifier.setFilter(ArchiveDateFilter.yesterday),
                    ),
                    const Gap(8),
                    _buildDatePill(
                      label: "Oxirgi 7 kun",
                      isSelected: filter.dateFilter == ArchiveDateFilter.week &&
                          filter.customDate == null,
                      onTap: () => filterNotifier.setFilter(ArchiveDateFilter.week),
                    ),
                    const Gap(8),
                    _buildDatePill(
                      label: "Shu oy",
                      isSelected: filter.dateFilter == ArchiveDateFilter.month &&
                          filter.customDate == null,
                      onTap: () => filterNotifier.setFilter(ArchiveDateFilter.month),
                    ),
                    const Gap(8),
                    _buildDatePill(
                      label: "Barchasi",
                      isSelected: filter.dateFilter == ArchiveDateFilter.all &&
                          filter.customDate == null,
                      onTap: () => filterNotifier.setFilter(ArchiveDateFilter.all),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: Gap(16)),

            // ── O'yinlar Ro'yxati yoki Bo'sh holat ─────────────
            gamesAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                ),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(
                  child: Text(
                    "Xatolik: $err",
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
              data: (games) {
                if (games.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0F172A),
                              border: Border.all(
                                color: const Color(0xFF1E293B),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              size: 38,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const Gap(20),
                          const Text(
                            "Tanlangan oraliqda yakunlangan o'yinlar topilmadi",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                          const Gap(8),
                          const Text(
                            "Sana filtrini yoki qidiruv so'zini o'zgartirib ko'ring",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const Gap(24),
                          ElevatedButton.icon(
                            onPressed: () {
                              filterNotifier.setFilter(ArchiveDateFilter.all);
                            },
                            icon: const Icon(Icons.history_rounded, size: 18),
                            label: const Text("Barcha tarixni ko'rish"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final g = games[index];
                        return _buildGameItemCard(context, g);
                      },
                      childCount: games.length,
                    ),
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: Gap(30)),
          ],
        ),
      ),
    );
  }

  // Metrika kartasi
  Widget _buildDarkStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E293B),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const Gap(10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: valueColor,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // Sana pill
  Widget _buildDatePill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, size: 14, color: Colors.white),
              const Gap(4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // O'yin kartasi
  Widget _buildGameItemCard(BuildContext context, ArchivedGameSession g) {
    final s = g.session;
    final tableName = g.table?.name ?? "Maydon";
    final timeStr = s.endedAt != null
        ? "${DateFormat('HH:mm').format(s.startedAt)} - ${DateFormat('HH:mm').format(s.endedAt!)}"
        : DateFormat('HH:mm').format(s.startedAt);

    final durationText = s.durationMin < 60
        ? "${s.durationMin} daqiqa"
        : "${s.durationMin ~/ 60} soat ${s.durationMin % 60} daq";

    final isPaid = s.paymentType != 'debt';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E293B),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Yuqori qator: Stol nomi va To'lov holati
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.sports_soccer_rounded,
                      color: Color(0xFF38BDF8),
                      size: 18,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    tableName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPaid
                      ? const Color(0xFF064E3B)
                      : const Color(0xFF451A03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPaid ? "To'langan (${s.paymentType})" : "Nasiyaga (Qarz)",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isPaid
                        ? const Color(0xFF34D399)
                        : const Color(0xFFFBBF24),
                  ),
                ),
              ),
            ],
          ),

          const Gap(10),

          // Vaqt va muddat
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: Color(0xFF64748B)),
              const Gap(4),
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const Gap(12),
              const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF64748B)),
              const Gap(4),
              Text(
                durationText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF38BDF8),
                ),
              ),
            ],
          ),

          if (g.customer != null) ...[
            const Gap(6),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
                const Gap(4),
                Text(
                  g.customer!.name,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFCBD5E1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],

          const Gap(10),
          const Divider(color: Color(0xFF1E293B), height: 1),
          const Gap(10),

          // O'yin va Bar hisobi
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "O'yin summasi",
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const Gap(2),
                    Text(
                      formatSum(g.gameAmount),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF22D3EE),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Bar buyurtmalari",
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const Gap(2),
                    Text(
                      formatSum(g.barAmount),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Jami summa",
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const Gap(2),
                  Text(
                    formatSum(g.totalAmount),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (g.barItemsSummary.isNotEmpty) ...[
            const Gap(8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.coffee_rounded,
                    size: 14,
                    color: Color(0xFFF59E0B),
                  ),
                  const Gap(6),
                  Expanded(
                    child: Text(
                      g.barItemsSummary,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Gap(10),

          // Chek ko'rish tugmasi
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {
                final tbl = g.table ?? ClubTable(
                  id: s.tableId,
                  name: tableName,
                  type: 'football',
                  pricePerHour: 100000,
                  isActive: true,
                  sortOrder: 1,
                  createdAt: s.startedAt,
                  updatedAt: s.startedAt,
                  isSynced: true,
                );
                final receipt = ReceiptGenerator.forTableSession(
                  table: tbl,
                  session: s,
                  finalAmount: g.totalAmount,
                  paymentType: s.paymentType,
                  customerName: g.customer?.name,
                );
                showDialog(
                  context: context,
                  builder: (_) => ReceiptPreviewDialog(
                    receiptText: receipt,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF334155),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 14,
                      color: Color(0xFF38BDF8),
                    ),
                    Gap(6),
                    Text(
                      "Chekni ko'rish",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF38BDF8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
