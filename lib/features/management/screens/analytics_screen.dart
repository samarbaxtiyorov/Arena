// ============================================
// Arena — Biznes Tahlili & Statistika Maxsus Sahifasi
// Maydonlar, Do'kon/Bar, Qarzdorlik va To'lov usullari bo'yicha
// to'liq, mukammal, 100% real hisob-kitoblar va grafik ko'rsatkichlar
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/product_asset_helper.dart';
import '../../kassa/widgets/receipt_preview_dialog.dart';
import '../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  String _getPeriodTitle(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.today:
        return "Bugungi";
      case AnalyticsPeriod.yesterday:
        return "Kechagi";
      case AnalyticsPeriod.week:
        return "Oxirgi 7 kunlik";
      case AnalyticsPeriod.month:
        return "Shu oylik (30 kun)";
      case AnalyticsPeriod.all:
        return "Barcha davr uchun";
    }
  }

  // Tahliliy hisobot cheki matnini generatsiya qilish
  String _generateAnalyticsReport(
      BusinessAnalyticsData data, AnalyticsPeriod period) {
    final now = DateTime.now();
    final dateStr = Formatters.dateTime(now);
    final periodName = _getPeriodTitle(period);

    final buffer = StringBuffer();
    buffer.writeln('================================');
    buffer.writeln('           ARENA POS            ');
    buffer.writeln('    BIZNES TAHLILI VA HISOBOT   ');
    buffer.writeln('================================');
    buffer.writeln('Sana: $dateStr');
    buffer.writeln('Davr: $periodName hisobot');
    buffer.writeln('--------------------------------');
    buffer.writeln('UMUMIY TUSHUM: ${formatSum(data.totalRevenue)}');
    buffer.writeln(' • Maydonlar:  ${formatSum(data.gameRevenue)} (${data.gameCount} ta o\'yin)');
    buffer.writeln(' • Do\'kon/Bar:  ${formatSum(data.shopRevenue)} (${data.shopCount} ta savdo)');
    buffer.writeln(' • Qarz to\'lovi: ${formatSum(data.debtPaymentRevenue)} (${data.debtPaymentCount} ta to\'lov)');
    buffer.writeln('--------------------------------');
    buffer.writeln('SAMARADORLIK:');
    buffer.writeln(' • O\'rtacha o\'yin cheki: ${formatSum(data.averageGameCheck)}');
    buffer.writeln(' • O\'rtacha davomiylik: ${data.averageGameDurationMinutes} daqiqa');
    buffer.writeln(' • Eng faol soatlar: ${data.peakHourRange}');
    buffer.writeln('--------------------------------');
    buffer.writeln('TO\'LOV USULLARI:');
    buffer.writeln(' • Naqd pul: ${formatSum(data.cashTotal)}');
    buffer.writeln(' • Plastik karta: ${formatSum(data.cardTotal)}');
    buffer.writeln(' • Nasiya (qarz): ${formatSum(data.debtTotal)}');
    buffer.writeln('--------------------------------');
    if (data.tableStats.isNotEmpty) {
      buffer.writeln('MAYDONLAR FOYDASI:');
      for (final t in data.tableStats) {
        buffer.writeln(' • ${t.tableName}: ${formatSum(t.revenue)} (${t.gamesCount} ta, ${t.sharePercent.toStringAsFixed(1)}%)');
      }
      buffer.writeln('--------------------------------');
    }
    buffer.writeln('      HISOBOT TASDIQLANDI       ');
    buffer.writeln('================================');

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(analyticsPeriodProvider);
    final periodNotifier = ref.read(analyticsPeriodProvider.notifier);
    final analyticsAsync = ref.watch(businessAnalyticsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Biznes Tahlili & Statistika",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            Text(
              "${_getPeriodTitle(period)} to'liq moliyaviy hisobot",
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          // Hisobot chekini chiqarish tugmasi
          analyticsAsync.maybeWhen(
            data: (data) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                onPressed: () {
                  final text = _generateAnalyticsReport(data, period);
                  showDialog(
                    context: context,
                    builder: (_) => ReceiptPreviewDialog(receiptText: text),
                  );
                },
                icon: const Icon(Icons.receipt_long_rounded, size: 16),
                label: const Text(
                  "Hisobot",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            orElse: () => const SizedBox(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Davr Tanlash Chiplari (Bugun, Kecha, Hafta, Oy, Barchasi) ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPeriodChip(
                    label: "Bugun",
                    period: AnalyticsPeriod.today,
                    current: period,
                    onTap: () =>
                        periodNotifier.setPeriod(AnalyticsPeriod.today),
                  ),
                  const Gap(8),
                  _buildPeriodChip(
                    label: "Kecha",
                    period: AnalyticsPeriod.yesterday,
                    current: period,
                    onTap: () =>
                        periodNotifier.setPeriod(AnalyticsPeriod.yesterday),
                  ),
                  const Gap(8),
                  _buildPeriodChip(
                    label: "Oxirgi 7 kun",
                    period: AnalyticsPeriod.week,
                    current: period,
                    onTap: () =>
                        periodNotifier.setPeriod(AnalyticsPeriod.week),
                  ),
                  const Gap(8),
                  _buildPeriodChip(
                    label: "Shu oy (30 kun)",
                    period: AnalyticsPeriod.month,
                    current: period,
                    onTap: () =>
                        periodNotifier.setPeriod(AnalyticsPeriod.month),
                  ),
                  const Gap(8),
                  _buildPeriodChip(
                    label: "Barcha vaqt",
                    period: AnalyticsPeriod.all,
                    current: period,
                    onTap: () =>
                        periodNotifier.setPeriod(AnalyticsPeriod.all),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // ── Asosiy Tahlil Ma'lumotlari ──────────────────────
          Expanded(
            child: analyticsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF0284C7),
                ),
              ),
              error: (err, _) => Center(
                child: Text(
                  "Tahlil yuklashda xatolik: $err",
                  style: const TextStyle(color: Color(0xFFEF4444)),
                ),
              ),
              data: (data) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── 1. Asosiy Daromad Xulosasi Paneli ─────────
                    Container(
                      padding: const EdgeInsets.all(18),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "SOF JAMI TUSHUM",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "100% Real Vaqt",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0369A1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Gap(6),
                          Text(
                            formatSum(data.totalRevenue),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF059669),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Gap(16),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const Gap(14),

                          // 3 ta Ustun: Maydonlar, Bar, Qarzlar
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
                                      formatSum(data.gameRevenue),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      "${data.gameCount} ta o'yin",
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
                                  height: 38,
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
                                      formatSum(data.shopRevenue),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      "${data.shopCount} ta savdo",
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
                                  height: 38,
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
                                      formatSum(data.debtPaymentRevenue),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      "${data.debtPaymentCount} ta to'lov",
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

                    const Gap(16),

                    // ── 2. Samaradorlik Ko'rsatkichlari (2x2 Grid) ──
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.payments_outlined,
                            iconColor: const Color(0xFF059669),
                            iconBg: const Color(0xFFECFDF5),
                            title: "O'rtacha O'yin Cheki",
                            value: formatSum(data.averageGameCheck),
                            subtitle: "1 ta o'yin hisobi",
                          ),
                        ),
                        const Gap(10),
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.timer_outlined,
                            iconColor: const Color(0xFF2563EB),
                            iconBg: const Color(0xFFEFF6FF),
                            title: "O'rtacha Davomiylik",
                            value: "${data.averageGameDurationMinutes} daqiqa",
                            subtitle: "1 ta o'yin vaqti",
                          ),
                        ),
                      ],
                    ),
                    const Gap(10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.access_time_rounded,
                            iconColor: const Color(0xFFD97706),
                            iconBg: const Color(0xFFFEF3C7),
                            title: "Umumiy O'yin Vaqti",
                            value:
                                "${data.totalGameMinutes ~/ 60}s ${data.totalGameMinutes % 60}m",
                            subtitle: "Maydonlar bandligi",
                          ),
                        ),
                        const Gap(10),
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.local_fire_department_rounded,
                            iconColor: const Color(0xFFDC2626),
                            iconBg: const Color(0xFFFEE2E2),
                            title: "Eng Faol Soatlar",
                            value: data.peakHourRange,
                            subtitle: "Mijozlar eng ko'p payti",
                          ),
                        ),
                      ],
                    ),

                    const Gap(20),

                    // ── 3. Maydonlar va Stollar Daromad Reytingi ──
                    const Text(
                      "Maydonlar va Stollar Daromadi",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Gap(4),
                    const Text(
                      "Qaysi maydon qancha daromad keltirganining to'liq tahlili:",
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const Gap(10),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: data.tableStats.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: Text(
                                  "Maydonlar bo'yicha ma'lumot yo'q",
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFF94A3B8)),
                                ),
                              ),
                            )
                          : Column(
                              children: data.tableStats.map((table) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              _buildTableTypeIcon(
                                                  table.tableType),
                                              const Gap(8),
                                              Text(
                                                table.tableName,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                              const Gap(6),
                                              Text(
                                                "(${table.gamesCount} ta o'yin)",
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            formatSum(table.revenue),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF059669),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Gap(6),
                                      // Progress Bar
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(6),
                                        child: LinearProgressIndicator(
                                          value: (table.sharePercent / 100)
                                              .clamp(0.0, 1.0),
                                          backgroundColor:
                                              const Color(0xFFF1F5F9),
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                  Color>(Color(0xFF2563EB)),
                                          minHeight: 6,
                                        ),
                                      ),
                                      const Gap(3),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Bandlik: ${table.totalMinutes ~/ 60} soat ${table.totalMinutes % 60} daqiqa",
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF94A3B8)),
                                          ),
                                          Text(
                                            "${table.sharePercent.toStringAsFixed(1)}% ulush",
                                            style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF2563EB)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),

                    const Gap(20),

                    // ── 4. Do'konda Eng Ko'p Sotilgan Mahsulotlar ──
                    const Text(
                      "Top Mahsulotlar (Do'kon & Bar)",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Gap(4),
                    const Text(
                      "Mijozlar eng ko'p sotib olgan ichimlik va gazaklar:",
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const Gap(10),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: data.topProducts.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: Text(
                                  "Hozircha sotilgan tovarlar yo'q",
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFF94A3B8)),
                                ),
                              ),
                            )
                          : Column(
                              children: data.topProducts.take(5).map((prod) {
                                final imgPath =
                                    ProductAssetHelper.getImageForProduct(
                                        prod.name);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: Row(
                                    children: [
                                      // Rasm
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        child: Container(
                                          width: 44,
                                          height: 44,
                                          color: const Color(0xFFF1F5F9),
                                          child: Image.asset(
                                            imgPath,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                const Icon(
                                              Icons.fastfood_rounded,
                                              size: 20,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Gap(12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              prod.name,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF0F172A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              "${prod.quantity} dona sotildi",
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        formatSum(prod.totalRevenue),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFFD97706),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),

                    const Gap(20),

                    // ── 5. To'lov Usullari Taqsimoti ──────────────
                    const Text(
                      "To'lov Usullari Taqsimoti",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Gap(4),
                    const Text(
                      "Kassa, Bank kartasi va Nasiya oqimi:",
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const Gap(10),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _buildPaymentRow(
                            label: "Naqd pul",
                            amount: data.cashTotal,
                            total: data.totalRevenue,
                            color: const Color(0xFF059669),
                            icon: Icons.payments_rounded,
                          ),
                          const Gap(12),
                          _buildPaymentRow(
                            label: "Plastik karta",
                            amount: data.cardTotal,
                            total: data.totalRevenue,
                            color: const Color(0xFF2563EB),
                            icon: Icons.credit_card_rounded,
                          ),
                          const Gap(12),
                          _buildPaymentRow(
                            label: "Nasiya / Qarz",
                            amount: data.debtTotal,
                            total: data.totalRevenue,
                            color: const Color(0xFFD97706),
                            icon: Icons.assignment_ind_rounded,
                          ),
                        ],
                      ),
                    ),

                    const Gap(30),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip({
    required String label,
    required AnalyticsPeriod period,
    required AnalyticsPeriod current,
    required VoidCallback onTap,
  }) {
    final isSelected = period == current;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
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

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const Gap(10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Gap(3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Gap(2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildTableTypeIcon(String type) {
    IconData icon;
    Color color;
    switch (type.toLowerCase()) {
      case 'football':
        icon = Icons.sports_soccer_rounded;
        color = const Color(0xFF10B981);
        break;
      case 'billiard':
        icon = Icons.sports_baseball_outlined;
        color = const Color(0xFF2563EB);
        break;
      case 'ps':
        icon = Icons.sports_esports_rounded;
        color = const Color(0xFF8B5CF6);
        break;
      case 'tennis':
        icon = Icons.sports_tennis_rounded;
        color = const Color(0xFFF59E0B);
        break;
      default:
        icon = Icons.games_rounded;
        color = const Color(0xFF64748B);
    }
    return Icon(icon, color: color, size: 16);
  }

  Widget _buildPaymentRow({
    required String label,
    required int amount,
    required int total,
    required Color color,
    required IconData icon,
  }) {
    final percent = total > 0 ? (amount / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const Gap(8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  formatSum(amount),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Gap(6),
                Text(
                  "(${(percent * 100).toStringAsFixed(1)}%)",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
        const Gap(6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}
