// ============================================
// Arena — Mijoz Profili va Qarz Tarixi Modali
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/database_providers.dart';
import 'add_debt_dialog.dart';
import 'make_payment_dialog.dart';

class CustomerDetailSheet extends ConsumerWidget {
  final Customer customer;

  const CustomerDetailSheet({super.key, required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);

    // Mijozning yangilangan ma'lumotlarini kuzatish
    return StreamBuilder<Customer?>(
      stream: db.customersDao.watchAllCustomers().map(
            (list) => list.where((c) => c.id == customer.id).firstOrNull,
          ),
      initialData: customer,
      builder: (context, snapshot) {
        final currentCustomer = snapshot.data ?? customer;
        final hasDebt = currentCustomer.totalDebt > 0;

        Color debtColor;
        if (currentCustomer.totalDebt >= 500000) {
          debtColor = AppColors.debtHigh;
        } else if (currentCustomer.totalDebt > 0) {
          debtColor = AppColors.debtMedium;
        } else {
          debtColor = AppColors.debtLow;
        }

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Yuqori drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryGlow,
                      child: Text(
                        currentCustomer.name.isNotEmpty
                            ? currentCustomer.name[0].toUpperCase()
                            : 'M',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const Gap(14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentCustomer.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (currentCustomer.phone != null &&
                              currentCustomer.phone!.isNotEmpty) ...[
                            const Gap(2),
                            Text(
                              currentCustomer.phone!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(color: AppColors.surfaceBorder, height: 1),

              // Qarz balansi kartasi
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: debtColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Umumiy qarz balansi:',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const Gap(4),
                          Text(
                            Formatters.currency(currentCustomer.totalDebt),
                            style: TextStyle(
                              color: debtColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: debtColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          hasDebt ? 'QARZDOR' : 'TOZA',
                          style: TextStyle(
                            color: debtColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Harakat tugmalari: To'lov qabul qilish & Qarz yozish
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.payments_outlined, size: 20),
                        label: const Text(
                          'To\'lov qabul qilish',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => MakePaymentDialog(
                              customer: currentCustomer,
                            ),
                          );
                        },
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        label: const Text(
                          'Qarz yozish',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AddDebtDialog(
                              customer: currentCustomer,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const Gap(16),

              // Tarix sarlavhasi
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Amallar tarixi (Tranzaksiyalar)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),

              const Gap(10),

              // Tranzaksiyalar ro'yxati
              Flexible(
                child: StreamBuilder<List<Debt>>(
                  stream: db.debtsDao.watchDebtsForCustomer(currentCustomer.id),
                  builder: (context, snapshot) {
                    final debts = snapshot.data ?? [];

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (debts.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            'Ushbu mijozda hali hech qanday amallar tarixi yo\'q',
                            style: TextStyle(color: AppColors.textDisabled),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: debts.length,
                      separatorBuilder: (_, _) => const Gap(8),
                      itemBuilder: (context, index) {
                        final item = debts[index];
                        final isPayment = item.amount < 0 || item.type == 'payment';
                        final absAmount = item.amount.abs();

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isPayment
                                      ? AppColors.success.withOpacity(0.15)
                                      : AppColors.danger.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isPayment
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: isPayment
                                      ? AppColors.success
                                      : AppColors.danger,
                                  size: 18,
                                ),
                              ),
                              const Gap(12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.description ??
                                          (isPayment ? 'To\'lov' : 'Qarz'),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const Gap(2),
                                    Text(
                                      Formatters.dateTime(item.createdAt),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isPayment ? '-' : '+'}${Formatters.currency(absAmount)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isPayment
                                      ? AppColors.success
                                      : AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
