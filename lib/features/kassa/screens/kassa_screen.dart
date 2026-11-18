// ============================================
// Arena — Kassa Asosiy Ekrani
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/database_providers.dart';
import '../providers/kassa_providers.dart';
import '../widgets/add_expense_dialog.dart';
import '../widgets/add_income_dialog.dart';
import '../widgets/transaction_tile.dart';

class KassaScreen extends ConsumerWidget {
  const KassaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(kassaPeriodProvider);
    final summary = ref.watch(kassaSummaryProvider);
    final records = ref.watch(filteredCashRecordsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: const Row(
          children: [
            Icon(Icons.point_of_sale_outlined,
                color: AppColors.info, size: 24),
            Gap(10),
            Text(
              'Kassa & Hisobot',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
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
          // 1. Davr filtrlari
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                _PeriodTab(
                  label: 'Bugun',
                  isSelected: period == KassaPeriod.today,
                  onTap: () => ref
                      .read(kassaPeriodProvider.notifier)
                      .select(KassaPeriod.today),
                ),
                const Gap(8),
                _PeriodTab(
                  label: 'Kecha',
                  isSelected: period == KassaPeriod.yesterday,
                  onTap: () => ref
                      .read(kassaPeriodProvider.notifier)
                      .select(KassaPeriod.yesterday),
                ),
                const Gap(8),
                _PeriodTab(
                  label: 'Hafta',
                  isSelected: period == KassaPeriod.week,
                  onTap: () => ref
                      .read(kassaPeriodProvider.notifier)
                      .select(KassaPeriod.week),
                ),
                const Gap(8),
                _PeriodTab(
                  label: 'Shu oy',
                  isSelected: period == KassaPeriod.month,
                  onTap: () => ref
                      .read(kassaPeriodProvider.notifier)
                      .select(KassaPeriod.month),
                ),
              ],
            ),
          ),

          // 2. Kassa asosiy balansi kartasi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.06),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Sof foyda / Sof qoldiq
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sof Kassa Balansi:',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Gap(4),
                          Text(
                            Formatters.currency(summary.netBalance),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: summary.netBalance >= 0
                                  ? AppColors.success
                                  : AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.receipt_long,
                                size: 14, color: AppColors.textSecondary),
                            const Gap(6),
                            Text(
                              '${records.length} ta amal',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Gap(14),
                  const Divider(color: AppColors.surfaceBorder, height: 1),
                  const Gap(14),

                  // Kirim va Chiqim qatorlari
                  Row(
                    children: [
                      // Jami Kirim
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.arrow_downward,
                                    size: 14, color: AppColors.success),
                                Gap(4),
                                Text(
                                  'Jami Kirim',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const Gap(2),
                            Text(
                              Formatters.currency(summary.totalIncome),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                            const Gap(4),
                            Text(
                              '🎱 ${Formatters.currency(summary.tableIncome)}  •  🛒 ${Formatters.currency(summary.shopIncome)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textDisabled,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      Container(
                        height: 48,
                        width: 1,
                        color: AppColors.surfaceBorder,
                      ),
                      const Gap(16),

                      // Jami Chiqim
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.arrow_upward,
                                    size: 14, color: AppColors.danger),
                                Gap(4),
                                Text(
                                  'Jami Chiqim',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const Gap(2),
                            Text(
                              Formatters.currency(summary.totalExpense),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.danger,
                              ),
                            ),
                            const Gap(4),
                            const Text(
                              'Oylik, ijara va xarajatlar',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textDisabled,
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

          const Gap(14),

          // 3. Harakat tugmalari (Kirim / Chiqim)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_upward, size: 18),
                    label: const Text(
                      'Chiqim yozish',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const AddExpenseDialog(),
                      );
                    },
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_downward, size: 18),
                    label: const Text(
                      'Kirim qilish',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const AddIncomeDialog(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const Gap(14),

          // Sarlavha
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Kassa Amallari Jurnali',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),

          const Gap(8),

          // 4. Tranzaksiyalar ro'yxati
          Expanded(
            child: records.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 64, color: AppColors.textDisabled),
                        Gap(12),
                        Text(
                          'Bu davrda kassa amallari mavjud emas',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: records.length,
                    separatorBuilder: (_, _) => const Gap(8),
                    itemBuilder: (context, index) {
                      final rec = records[index];
                      return TransactionTile(
                        key: ValueKey(rec.id),
                        record: rec,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.surfaceBorder,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
