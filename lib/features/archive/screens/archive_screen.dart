// ============================================
// Arena — Moliya va Savdo Arxivi Ekrani (Super Ochiq Rangli Dizayn)
// O'yinlar, Do'kon/Bar savdolari va Qarz to'lovlari to'liq hisobi
// Zamonaviy ochiq rangli fon (#F8FAFC, #FFFFFF), statistika va kassa cheklari
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/formatters.dart';
import '../../kassa/widgets/receipt_preview_dialog.dart';
import '../providers/archive_providers.dart';

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  // Har bir arxiv elementi uchun kassa chekini generatsiya qilish
  String _generateReceiptText(ArchiveItem item) {
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(item.timestamp);
    final buffer = StringBuffer();
    buffer.writeln('================================');
    buffer.writeln('           ARENA POS            ');
    buffer.writeln('        Moliya Arxivi           ');
    buffer.writeln('================================');
    buffer.writeln('Sana: $dateStr');
    buffer.writeln('Amal turi: ${item.title}');

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
    buffer.writeln('      Kassa hujjati tasdiqlandi ');
    buffer.writeln('================================');

    return buffer.toString();
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: Colors.white,
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
                                "Moliya va Savdo Arxivi",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const Gap(8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFA7F3D0),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '${stats.totalCount} ta amal',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Gap(2),
                          const Text(
                            "Maydonlar, bar savdosi va qarz to'lovlari hisobi",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 2. Statistika Kartalari (Ochiq rangli 2x2 Grid) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Jami Tushum
                        Expanded(
                          child: _buildLightStatCard(
                            icon: Icons.account_balance_wallet_rounded,
                            iconBg: const Color(0xFFDCFCE7),
                            iconColor: const Color(0xFF059669),
                            label: "JAMI TUSHUM",
                            value: formatSum(stats.totalRevenue),
                            subvalue: "${stats.totalCount} ta jami amal",
                            valueColor: const Color(0xFF059669),
                          ),
                        ),
                        const Gap(10),
                        // Maydonlar Tushumi
                        Expanded(
                          child: _buildLightStatCard(
                            icon: Icons.sports_soccer_rounded,
                            iconBg: const Color(0xFFEFF6FF),
                            iconColor: const Color(0xFF2563EB),
                            label: "MAYDONLAR TUSHUMI",
                            value: formatSum(stats.gameRevenue),
                            subvalue: "${stats.gameCount} ta o'yin",
                            valueColor: const Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                    const Gap(10),
                    Row(
                      children: [
                        // Do'kon / Bar Tushumi
                        Expanded(
                          child: _buildLightStatCard(
                            icon: Icons.shopping_bag_rounded,
                            iconBg: const Color(0xFFFEF3C7),
                            iconColor: const Color(0xFFD97706),
                            label: "DO'KON & BAR SAVDOSI",
                            value: formatSum(stats.shopRevenue),
                            subvalue: "${stats.shopCount} ta savdo",
                            valueColor: const Color(0xFFD97706),
                          ),
                        ),
                        const Gap(10),
                        // Qarz To'lovlari
                        Expanded(
                          child: _buildLightStatCard(
                            icon: Icons.assignment_turned_in_rounded,
                            iconBg: const Color(0xFFF3E8FF),
                            iconColor: const Color(0xFF7C3AED),
                            label: "QARZ TO'LOVLARI",
                            value: formatSum(stats.debtPaymentRevenue),
                            subvalue: "${stats.debtPaymentCount} ta to'lov",
                            valueColor: const Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: Gap(14)),

            // ── 3. Qidiruv Maydoni (Ochiq Rangda) ────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (val) => filterNotifier.setSearch(val),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: "Maydon, tovar yoki mijoz nomini qidirish...",
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: Color(0xFF94A3B8), size: 20),
                      suffixIcon: filter.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  size: 18, color: Color(0xFF64748B)),
                              onPressed: () {
                                filterNotifier.setSearch('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: Gap(12)),

            // ── 4. Toifa Chiplari (Barchasi, Maydonlar, Do'kon, Qarz) ─
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
                      label: "Do'kon & Bar (${stats.shopCount})",
                      type: ArchiveTypeFilter.shop,
                      current: filter.typeFilter,
                      onTap: () =>
                          filterNotifier.setTypeFilter(ArchiveTypeFilter.shop),
                    ),
                    const Gap(8),
                    _buildTypeChip(
                      label: "Qarz To'lovlari (${stats.debtPaymentCount})",
                      type: ArchiveTypeFilter.debtPayment,
                      current: filter.typeFilter,
                      onTap: () => filterNotifier
                          .setTypeFilter(ArchiveTypeFilter.debtPayment),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: Gap(10)),

            // ── 5. Sana Chiplari (Bugun, Kecha, Hafta, Oy, Barchasi) ──
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildDateChip(
                      label: "Bugun",
                      filter: ArchiveDateFilter.today,
                      current: filter.dateFilter,
                      onTap: () => filterNotifier
                          .setDateFilter(ArchiveDateFilter.today),
                    ),
                    const Gap(8),
                    _buildDateChip(
                      label: "Kecha",
                      filter: ArchiveDateFilter.yesterday,
                      current: filter.dateFilter,
                      onTap: () => filterNotifier
                          .setDateFilter(ArchiveDateFilter.yesterday),
                    ),
                    const Gap(8),
                    _buildDateChip(
                      label: "Shu hafta",
                      filter: ArchiveDateFilter.week,
                      current: filter.dateFilter,
                      onTap: () =>
                          filterNotifier.setDateFilter(ArchiveDateFilter.week),
                    ),
                    const Gap(8),
                    _buildDateChip(
                      label: "Shu oy",
                      filter: ArchiveDateFilter.month,
                      current: filter.dateFilter,
                      onTap: () =>
                          filterNotifier.setDateFilter(ArchiveDateFilter.month),
                    ),
                    const Gap(8),
                    _buildDateChip(
                      label: "Barchasi",
                      filter: ArchiveDateFilter.all,
                      current: filter.dateFilter,
                      onTap: () =>
                          filterNotifier.setDateFilter(ArchiveDateFilter.all),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: Gap(14)),

            // ── 6. Arxiv Yozuvlari Ro'yxati ─────────────────────
            itemsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(
                  child: Text(
                    "Xatolik yuz berdi: $err",
                    style: const TextStyle(color: Color(0xFFEF4444)),
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
                          Gap(12),
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
                            "Filtrlarni o'zgartirib ko'ring",
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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

  // ── Arxiv Kartochkasi ──────────────────────────────────
  Widget _buildArchiveItemCard(BuildContext context, ArchiveItem item) {
    IconData typeIcon;
    Color iconBg;
    Color iconColor;
    String typeBadge;
    Color typeBadgeBg;
    Color typeBadgeText;

    switch (item.type) {
      case ArchiveItemType.game:
        typeIcon = Icons.sports_soccer_rounded;
        iconBg = const Color(0xFFEFF6FF);
        iconColor = const Color(0xFF2563EB);
        typeBadge = "O'yin";
        typeBadgeBg = const Color(0xFFDBEAFE);
        typeBadgeText = const Color(0xFF1D4ED8);
        break;
      case ArchiveItemType.shop:
        typeIcon = Icons.storefront_rounded;
        iconBg = const Color(0xFFECFDF5);
        iconColor = const Color(0xFF059669);
        typeBadge = "Do'kon & Bar";
        typeBadgeBg = const Color(0xFFD1FAE5);
        typeBadgeText = const Color(0xFF047857);
        break;
      case ArchiveItemType.debtPayment:
        typeIcon = Icons.assignment_turned_in_rounded;
        iconBg = const Color(0xFFF5F3FF);
        iconColor = const Color(0xFF7C3AED);
        typeBadge = "Qarz to'lovi";
        typeBadgeBg = const Color(0xFFEDE9FE);
        typeBadgeText = const Color(0xFF6D28D9);
        break;
    }

    String payBadge = "Naqd";
    Color payBadgeBg = const Color(0xFFF1F5F9);
    Color payBadgeText = const Color(0xFF475569);

    if (item.paymentType == 'card') {
      payBadge = "Karta";
      payBadgeBg = const Color(0xFFEFF6FF);
      payBadgeText = const Color(0xFF2563EB);
    } else if (item.paymentType == 'debt') {
      payBadge = "Nasiya";
      payBadgeBg = const Color(0xFFFEF3C7);
      payBadgeText = const Color(0xFFB45309);
    }

    final dateFormatted =
        DateFormat('dd-MMM, HH:mm', 'uz').format(item.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Yuqori qator: Ikonka, Nomi, Vaqti va Summasi
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(typeIcon, color: iconColor, size: 22),
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Gap(6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeBadgeBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            typeBadge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: typeBadgeText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(2),
                    Row(
                      children: [
                        Text(
                          dateFormatted,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Gap(6),
                        Text(
                          "• ${item.subtitle}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Gap(8),
              // Summa
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
                  const Gap(2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: payBadgeBg,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      payBadge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: payBadgeText,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Tafsilotlar (agar mavjud bo'lsa)
          if (item.details.isNotEmpty) ...[
            const Gap(8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Text(
                item.details,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
          ],

          const Gap(8),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const Gap(6),

          // Pastki amallar: Chekni ko'rish tugmasi va Mijoz
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (item.customerName != null && item.customerName!.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 14, color: Color(0xFF64748B)),
                    const Gap(4),
                    Text(
                      item.customerName!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                )
              else
                const SizedBox(),

              // Chekni chiqarish / ko'rish tugmasi
              InkWell(
                onTap: () {
                  final receiptText = _generateReceiptText(item);
                  showDialog(
                    context: context,
                    builder: (_) =>
                        ReceiptPreviewDialog(receiptText: receiptText),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_rounded,
                          size: 14, color: Color(0xFF2563EB)),
                      Gap(4),
                      Text(
                        "Chek",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Ochiq Rangli Statistika Kartochkasi ─────────────────
  Widget _buildLightStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required String subvalue,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const Gap(6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Gap(6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Gap(2),
          Text(
            subvalue,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Toifa Chipi ────────────────────────────────────────
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F172A)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF0F172A).withOpacity(0.12)
                  : Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
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

  // ── Sana Chipi ─────────────────────────────────────────
  Widget _buildDateChip({
    required String label,
    required ArchiveDateFilter filter,
    required ArchiveDateFilter current,
    required VoidCallback onTap,
  }) {
    final isSelected = filter == current;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
