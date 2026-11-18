// ============================================
// Arena — Mijoz Karta Elementi (Customer Tile)
// ============================================

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/local/app_database.dart';
import 'customer_detail_sheet.dart';
import 'make_payment_dialog.dart';

class CustomerTile extends StatelessWidget {
  final Customer customer;

  const CustomerTile({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    Color debtColor;
    if (customer.totalDebt >= 500000) {
      debtColor = AppColors.debtHigh;
    } else if (customer.totalDebt > 0) {
      debtColor = AppColors.debtMedium;
    } else {
      debtColor = AppColors.debtLow;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: customer.totalDebt > 0
              ? debtColor.withOpacity(0.3)
              : AppColors.surfaceBorder,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => CustomerDetailSheet(customer: customer),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.surfaceAlt,
                  child: Text(
                    customer.name.isNotEmpty
                        ? customer.name[0].toUpperCase()
                        : 'M',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: debtColor,
                    ),
                  ),
                ),
                const Gap(12),

                // Ma'lumotlar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(3),
                      Row(
                        children: [
                          if (customer.phone != null &&
                              customer.phone!.isNotEmpty) ...[
                            const Icon(Icons.phone_outlined,
                                size: 12, color: AppColors.textSecondary),
                            const Gap(4),
                            Text(
                              customer.phone!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ] else
                            const Text(
                              'Telefon kiritilmagan',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textDisabled,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Gap(10),

                // Qarz miqdori badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: debtColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: debtColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        customer.totalDebt > 0
                            ? Formatters.currency(customer.totalDebt)
                            : 'Toza',
                        style: TextStyle(
                          color: debtColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                const Gap(8),

                // Tezkor to'lov tugmasi
                if (customer.totalDebt > 0)
                  IconButton(
                    icon: const Icon(Icons.payments_outlined,
                        color: AppColors.success, size: 20),
                    tooltip: 'To\'lov qabul qilish',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            MakePaymentDialog(customer: customer),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
