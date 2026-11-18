// ============================================
// Arena — Nasiya Daftari Asosiy Ekrani
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/database_providers.dart';
import '../providers/nasiya_providers.dart';
import '../widgets/add_customer_dialog.dart';
import '../widgets/customer_tile.dart';

class NasiyaScreen extends ConsumerWidget {
  const NasiyaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredCustomers = ref.watch(filteredCustomersProvider);
    final stats = ref.watch(nasiyaStatsProvider);
    final customersAsync = ref.watch(customersStreamProvider);
    final currentFilter = ref.watch(debtFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: const Row(
          children: [
            Icon(Icons.menu_book_rounded, color: AppColors.warning, size: 24),
            Gap(10),
            Text(
              'Nasiya Daftari',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          // Sinxronizatsiya tugmasi
          IconButton(
            tooltip: 'Sinxronizatsiya qilish',
            icon: const Icon(Icons.sync, color: AppColors.textSecondary),
            onPressed: () async {
              final sync = ref.read(syncServiceProvider);
              final res = await sync.syncAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      res.isSuccess
                          ? 'Sinxronizatsiya muvaffaqiyatli! (${res.pushed} push, ${res.pulled} pull)'
                          : (res.wasOffline
                              ? 'Offline rejim'
                              : 'Xatolik yuz berdi'),
                    ),
                    backgroundColor: res.isSuccess
                        ? AppColors.success
                        : AppColors.warning,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          const Gap(8),
        ],
      ),
      body: Column(
        children: [
          // 1. Umumiy statistika paneli
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                // Jami qarz summasi
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: stats.totalDebt > 0
                            ? AppColors.danger.withOpacity(0.4)
                            : AppColors.surfaceBorder,
                      ),
                      boxShadow: [
                        if (stats.totalDebt > 0)
                          BoxShadow(
                            color: AppColors.danger.withOpacity(0.08),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jami Nasiya (Qarz)',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          Formatters.currency(stats.totalDebt),
                          style: TextStyle(
                            color: stats.totalDebt > 0
                                ? AppColors.danger
                                : AppColors.success,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(10),

                // Qarzdorlar soni
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Qarzdorlar',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          '${stats.debtorsCount} nafar',
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Qidiruv paneli
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Mijoz ismi yoki telefon raqami...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: ref.watch(customerSearchQueryProvider).isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          ref
                              .read(customerSearchQueryProvider.notifier)
                              .clear();
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onChanged: (val) {
                ref.read(customerSearchQueryProvider.notifier).setQuery(val);
              },
            ),
          ),

          const Gap(12),

          // 3. Filter tugmalari (Barchasi / Qarzdorlar / Toza)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Barchasi (${stats.totalCustomers})',
                  isSelected: currentFilter == DebtFilter.all,
                  onTap: () => ref
                      .read(debtFilterProvider.notifier)
                      .select(DebtFilter.all),
                ),
                const Gap(8),
                _FilterChip(
                  label: 'Qarzdorlar (${stats.debtorsCount})',
                  isSelected: currentFilter == DebtFilter.debtors,
                  color: AppColors.danger,
                  onTap: () => ref
                      .read(debtFilterProvider.notifier)
                      .select(DebtFilter.debtors),
                ),
                const Gap(8),
                _FilterChip(
                  label: 'Toza (${stats.totalCustomers - stats.debtorsCount})',
                  isSelected: currentFilter == DebtFilter.cleared,
                  color: AppColors.success,
                  onTap: () => ref
                      .read(debtFilterProvider.notifier)
                      .select(DebtFilter.cleared),
                ),
              ],
            ),
          ),

          const Gap(10),

          // 4. Mijozlar ro'yxati
          Expanded(
            child: customersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Center(
                child: Text('Xatolik: $err',
                    style: const TextStyle(color: AppColors.danger)),
              ),
              data: (_) {
                if (filteredCustomers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_search_outlined,
                            size: 64, color: AppColors.textDisabled),
                        const Gap(12),
                        Text(
                          ref.watch(customerSearchQueryProvider).isNotEmpty
                              ? 'Qidiruv bo\'yicha mijoz topilmadi'
                              : 'Hozircha hech qanday mijoz yo\'q',
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                  itemCount: filteredCustomers.length,
                  separatorBuilder: (_, _) => const Gap(10),
                  itemBuilder: (context, index) {
                    final customer = filteredCustomers[index];
                    return CustomerTile(
                      key: ValueKey(customer.id),
                      customer: customer,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.warning,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text(
          'Mijoz qo\'shish',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddCustomerDialog(),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.18)
              : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.surfaceBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? activeColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
