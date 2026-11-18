// ============================================
// Arena — Qarz Daftari Asosiy Ekrani (Skrinshot 3 bilan 1:1)
// Qarz daftari, + Qarz yozish, Faol qarzdorlar kartasi
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/utils/formatters.dart';
import '../providers/nasiya_providers.dart';
import '../widgets/add_customer_dialog.dart';
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
            // ── Sarlavha Qatori (Qarz daftari, ☁️, + Qarz yozish) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
                  const Icon(
                    Icons.cloud_done_rounded,
                    color: Color(0xFF10B981),
                    size: 22,
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AddCustomerDialog(),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      "Qarz yozish",
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Asosiy Qarz Xulosasi Kartasi (Oq karta, Oltin summa) ─
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Ochiq kitob belgisi (Bej kvadrat)
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: Color(0xFFD97706),
                          size: 28,
                        ),
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Faol qarzdorlar: ${stats.debtorsCount} ta mijoz",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Gap(4),
                          Text(
                            formatSum(stats.totalDebt),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFD97706), // Sariq/oltin rang
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

            // ── Qidiruv Maydoni ───────────────────────────────
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
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "Mijoz ismi yoki telefoni bilan izlas...",
                    hintStyle: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            const Gap(12),

            // ── Filter Chiplari ───────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip(
                    label: "Faol Qarzdorlar",
                    isSelected: currentFilter == DebtFilter.debtors,
                    onTap: () => ref
                        .read(debtFilterProvider.notifier)
                        .select(DebtFilter.debtors),
                  ),
                  const Gap(8),
                  _buildFilterChip(
                    label: "Barchasi",
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

            const Gap(16),

            // ── Mijozlar Ro'yxati yoki Bo'sh holat ────────────
            Expanded(
              child: filteredCustomers.isEmpty
                  ? const Center(
                      child: Text(
                        "Mos mijozlar topilmadi",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFEF3C7) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFDE68A)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, size: 16, color: Color(0xFFD97706)),
              const Gap(6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
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
