// ============================================
// Arena — Moliya va Savdo Arxivi
// Sodda, ochiq rangli, tushunarli va professional
// O'yinlar, Do'kon/Bar savdosi va Qarz to'lovlari
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/utils/formatters.dart';
import '../../kassa/widgets/receipt_preview_dialog.dart';
import '../providers/archive_providers.dart';

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  // Elektron kassa chekini generatsiya qilish
  String _generateReceiptText(ArchiveItem item) {
    final dateStr = Formatters.dateTime(item.timestamp);
    final buffer = StringBuffer();
    buffer.writeln('================================');
    buffer.writeln('          CHAMPION POS          ');
    buffer.writeln('        Moliya Arxivi           ');
    buffer.writeln('================================');
    buffer.writeln('Sana: $dateStr');
    buffer.writeln('Amal: ${item.title}');

    if (item.customerName != null && item.customerName!.isNotEmpty) {
      buffer.writeln('Mijoz: ${item.customerName}');
    }

    buffer.writeln('--------------------------------');

    if (item.details.isNotEmpty) {
      buffer.writeln('Tafsilotlar:');
      final lines = item.details.split('\n');
      for (final line in lines) {
        buffer.writeln(' • $line');
      }
      buffer.writeln('--------------------------------');
    }

    buffer.writeln('JAMI SUMMA: ${formatSum(item.amount)}');

    String payName = 'NAQD PUL';
    if (item.paymentType == 'card') {
      payName = 'BANK KARTASI';
    } else if (item.paymentType == 'debt') {
      payName = 'NASIYA / QARZ';
    }
    buffer.writeln('To\'lov turi: $payName');

    buffer.writeln('================================');
    buffer.writeln('    Kassa hujjati tasdiqlandi   ');
    buffer.writeln('================================');

    return buffer.toString();
  }

  String _getDateFilterName(ArchiveDateFilter filter) {
    switch (filter) {
      case ArchiveDateFilter.today:
        return "Bugun";
      case ArchiveDateFilter.yesterday:
        return "Kecha";
      case ArchiveDateFilter.week:
        return "Shu hafta";
      case ArchiveDateFilter.month:
        return "Shu oy";
      case ArchiveDateFilter.all:
        return "Barchasi";
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(archiveOverallStatsProvider);
    final filter = ref.watch(archiveFilterProvider);
    final filterNotifier = ref.read(archiveFilterProvider.notifier);
    final itemsAsync = ref.watch(archiveItemsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── 1. Sarlavha Paneli ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const Gap(12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Savdo va Kassa Arxivi",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            "Maydonlar, bar va qarz to'lovlari hisob-kitobi",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Sana tanlash menyusi
                    PopupMenuButton<ArchiveDateFilter>(
                      initialValue: filter.dateFilter,
                      onSelected: (val) => filterNotifier.setDateFilter(val),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 14, color: Color(0xFF2563EB)),
                            const Gap(6),
                            Text(
                              _getDateFilterName(filter.dateFilter),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const Gap(2),
                            const Icon(Icons.arrow_drop_down_rounded,
                                size: 18, color: Color(0xFF64748B)),
                          ],
                        ),
                      ),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: ArchiveDateFilter.today,
                          child: Text("Bugun"),
                        ),
                        const PopupMenuItem(
                          value: ArchiveDateFilter.yesterday,
                          child: Text("Kecha"),
                        ),
                        const PopupMenuItem(
                          value: ArchiveDateFilter.week,
                          child: Text("Shu hafta"),
                        ),
                        const PopupMenuItem(
                          value: ArchiveDateFilter.month,
                          child: Text("Shu oy"),
                        ),
                        const PopupMenuItem(
                          value: ArchiveDateFilter.all,
                          child: Text("Barcha vaqt"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── 2. Asosiy Yagona Tushum Paneli (Sodda va Aniq) ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Jami Tushum sarlavhasi va Summasi
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "UMUMIY TUSHUM",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const Gap(4),
                              Text(
                                formatSum(stats.totalRevenue),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF059669),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "${stats.totalCount} ta amal",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Gap(14),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const Gap(12),

                      // 3 ta Bo'lim: Maydonlar, Do'kon, Qarzlar
                      Row(
                        children: [
                          // Maydonlar
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.sports_soccer_rounded,
                                        size: 14, color: Color(0xFF2563EB)),
                                    Gap(4),
                                    Text(
                                      "Maydonlar",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                                const Gap(4),
                                Text(
                                  formatSum(stats.gameRevenue),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "${stats.gameCount} ta o'yin",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                              height: 36,
                              width: 1,
                              color: const Color(0xFFF1F5F9)),
                          const Gap(12),

                          // Do'kon & Bar
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.storefront_rounded,
                                        size: 14, color: Color(0xFFD97706)),
                                    Gap(4),
                                    Text(
                                      "Do'kon & Bar",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                                const Gap(4),
                                Text(
                                  formatSum(stats.shopRevenue),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "${stats.shopCount} ta savdo",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                              height: 36,
                              width: 1,
                              color: const Color(0xFFF1F5F9)),
                          const Gap(12),

                          // Qarz To'lovlari
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.assignment_turned_in_rounded,
                                        size: 14, color: Color(0xFF7C3AED)),
                                    Gap(4),
                                    Text(
                                      "Qarz to'lovi",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                                const Gap(4),
                                Text(
                                  formatSum(stats.debtPaymentRevenue),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "${stats.debtPaymentCount} ta to'lov",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: Gap(12)),

            // ── 3. Qidiruv Maydoni ─────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    onChanged: (val) => filterNotifier.setSearch(val),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: "Qidirish: maydon, tovar yoki mijoz...",
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: Color(0xFF94A3B8), size: 19),
                      suffixIcon: filter.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  size: 17, color: Color(0xFF64748B)),
                              onPressed: () => filterNotifier.setSearch(''),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: Gap(10)),

            // ── 4. Toifa Chiplari (Bitta Toza Qator) ────────────
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildTypeChip(
                      label: "Barchasi (${stats.totalCount})",
                      type: ArchiveTypeFilter.all,
                      current: filter.typeFilter,
                      onTap: () =>
                          filterNotifier.setTypeFilter(ArchiveTypeFilter.all),
                    ),
                    const Gap(8),
                    _buildTypeChip(
                      label: "Maydonlar (${stats.gameCount})",
                      type: ArchiveTypeFilter.game,
                      current: filter.typeFilter,
                      onTap: () =>
                          filterNotifier.setTypeFilter(ArchiveTypeFilter.game),
                    ),
                    const Gap(8),
                    _buildTypeChip(
                      label: "Do'kon (${stats.shopCount})",
                      type: ArchiveTypeFilter.shop,
                      current: filter.typeFilter,
                      onTap: () =>
                          filterNotifier.setTypeFilter(ArchiveTypeFilter.shop),
                    ),
                    const Gap(8),
                    _buildTypeChip(
                      label: "Qarzlar (${stats.debtPaymentCount})",
                      type: ArchiveTypeFilter.debtPayment,
                      current: filter.typeFilter,
                      onTap: () => filterNotifier
                          .setTypeFilter(ArchiveTypeFilter.debtPayment),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: Gap(12)),

            // ── 5. Amallar Ro'yxati (100% Xavfsiz va Ravshan) ───
            itemsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              error: (err, stack) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      "Xatolik yuz berdi: $err",
                      style: const TextStyle(
                          color: Color(0xFFEF4444), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_toggle_off_rounded,
                            size: 48,
                            color: Color(0xFF94A3B8),
                          ),
                          Gap(10),
                          Text(
                            "Arxivda amallar topilmadi",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                          Gap(4),
                          Text(
                            "Filtrni o'zgartirib ko'ring",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = items[index];
                        return _buildArchiveItemCard(context, item);
                      },
                      childCount: items.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Ro'yxat Kartochkasi (Toza, Katta, Ravshan) ──────────
  Widget _buildArchiveItemCard(BuildContext context, ArchiveItem item) {
    IconData typeIcon;
    Color iconBg;
    Color iconColor;

    switch (item.type) {
      case ArchiveItemType.game:
        typeIcon = Icons.sports_soccer_rounded;
        iconBg = const Color(0xFFEFF6FF);
        iconColor = const Color(0xFF2563EB);
        break;
      case ArchiveItemType.shop:
        typeIcon = Icons.storefront_rounded;
        iconBg = const Color(0xFFECFDF5);
        iconColor = const Color(0xFF059669);
        break;
      case ArchiveItemType.debtPayment:
        typeIcon = Icons.assignment_turned_in_rounded;
        iconBg = const Color(0xFFF5F3FF);
        iconColor = const Color(0xFF7C3AED);
        break;
    }

    String payName = "Naqd";
    if (item.paymentType == 'card') {
      payName = "Karta";
    } else if (item.paymentType == 'debt') {
      payName = "Nasiya";
    }

    final dateFormatted = Formatters.uzDateTime(item.timestamp);

    return InkWell(
      onTap: () {
        final receiptText = _generateReceiptText(item);
        showDialog(
          context: context,
          builder: (_) => ReceiptPreviewDialog(receiptText: receiptText),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ikonka
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeIcon, color: iconColor, size: 22),
                ),
                const Gap(12),

                // Asosiy Ma'lumot
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(2),
                      Text(
                        "$dateFormatted • $payName",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const Gap(10),

                // Summa va Chek
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatSum(item.amount),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF059669),
                      ),
                    ),
                    const Gap(3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "Chek ➔",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Tafsilotlar (Tovar ro'yxati yoki o'yin vaqti / bo'lingan)
            if (item.details.isNotEmpty) ...[
              const Gap(10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Text(
                  item.details,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Toifa Chipi ─────────────────────────────────────────
  Widget _buildTypeChip({
    required String label,
    required ArchiveTypeFilter type,
    required ArchiveTypeFilter current,
    required VoidCallback onTap,
  }) {
    final isSelected = type == current;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F172A)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
