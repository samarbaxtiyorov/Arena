// ============================================
// Arena — Qarz Daftari Asosiy Ekrani (Super Mukammal)
// Qarz daftari, + Qarz yozish, Faol qarzdorlar xulosasi,
// tezkor qidiruv, toifalar va to'liq ma'lumotlar bazasi integratsiyasi
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/utils/formatters.dart';
import '../providers/nasiya_providers.dart';
import '../widgets/add_debt_dialog.dart';
import '../widgets/customer_tile.dart';

class NasiyaScreen extends ConsumerWidget {
  const NasiyaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredCustomers = ref.watch(filteredCustomersProvider);
    final stats = ref.watch(nasiyaStatsProvider);
    final currentFilter = ref.watch(debtFilterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. Sarlavha Qatori (Qarz daftari, ☁️, + Qarz yozish) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  const Text(
                    "Qarz daftari",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Gap(8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_done_rounded,
                      color: Color(0xFF059669),
                      size: 16,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AddDebtDialog(),
                      );
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      "Qarz yozish",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── 2. Asosiy Qarz Xulosasi Kartasi ───────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Ochiq kitobcha ikonkasi
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: Color(0xFFD97706),
                          size: 26,
                        ),
                      ),
                    ),
                    const Gap(14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Faol qarzdorlar: ${stats.debtorsCount} ta mijoz",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Gap(3),
                          Text(
                            formatSum(stats.totalDebt),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFD97706),
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Gap(12),

            // ── 3. Qidiruv Maydoni ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  onChanged: (val) => ref
                      .read(customerSearchQueryProvider.notifier)
                      .setQuery(val),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: "Mijoz ismi yoki telefoni bilan izlash...",
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    suffixIcon: ref.watch(customerSearchQueryProvider).isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                size: 18, color: Color(0xFF64748B)),
                            onPressed: () => ref
                                .read(customerSearchQueryProvider.notifier)
                                .clear(),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ),

            const Gap(12),

            // ── 4. Toifa Chiplari (Sodda va Matni Kesilmaydigan) ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip(
                    label: "Faol Qarzdorlar (${stats.debtorsCount})",
                    isSelected: currentFilter == DebtFilter.debtors,
                    onTap: () => ref
                        .read(debtFilterProvider.notifier)
                        .select(DebtFilter.debtors),
                  ),
                  const Gap(8),
                  _buildFilterChip(
                    label: "Barchasi (${stats.totalCustomers})",
                    isSelected: currentFilter == DebtFilter.all,
                    onTap: () => ref
                        .read(debtFilterProvider.notifier)
                        .select(DebtFilter.all),
                  ),
                  const Gap(8),
                  _buildFilterChip(
                    label: "To'liq yopilgan",
                    isSelected: currentFilter == DebtFilter.cleared,
                    onTap: () => ref
                        .read(debtFilterProvider.notifier)
                        .select(DebtFilter.cleared),
                  ),
                ],
              ),
            ),

            const Gap(14),

            // ── 5. Qarzdor Mijozlar Ro'yxati ──────────────────
            Expanded(
              child: filteredCustomers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.people_outline_rounded,
                              size: 44,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const Gap(14),
                          const Text(
                            "Mijozlar topilmadi",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const Gap(4),
                          const Text(
                            "Yangi qarz yozish uchun yuqoridagi tugmani bosing",
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = filteredCustomers[index];
                        return CustomerTile(customer: customer);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFEF3C7) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFDE68A)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFD97706).withOpacity(0.12)
                  : Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded,
                  size: 15, color: Color(0xFFD97706)),
              const Gap(6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF92400E)
                    : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
