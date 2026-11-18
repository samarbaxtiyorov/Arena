// ============================================
// Arena — Kassa Tranzaksiya Kartasi
// ============================================

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/receipt_generator.dart';
import '../../../data/local/app_database.dart';
import 'receipt_preview_dialog.dart';

class TransactionTile extends StatelessWidget {
  final CashRecord record;

  const TransactionTile({super.key, required this.record});

  IconData _getCategoryIcon(String? category, String type) {
    if (type == 'expense') {
      switch (category) {
        case 'salary':
          return Icons.work_outline;
        case 'rent':
          return Icons.apartment_outlined;
        case 'utility':
          return Icons.bolt_outlined;
        case 'cleaning':
          return Icons.cleaning_services_outlined;
        case 'stock_purchase':
          return Icons.shopping_bag_outlined;
        default:
          return Icons.arrow_upward;
      }
    } else {
      switch (category) {
        case 'table':
          return Icons.table_restaurant_outlined;
        case 'shop':
          return Icons.storefront_outlined;
        case 'debt_payment':
          return Icons.book_outlined;
        default:
          return Icons.arrow_downward;
      }
    }
  }

  String _getCategoryLabel(String? category, String type) {
    if (type == 'expense') {
      switch (category) {
        case 'salary':
          return 'Ish haqi';
        case 'rent':
          return 'Ijara';
        case 'utility':
          return 'Kommunal';
        case 'cleaning':
          return 'Tozalash';
        case 'stock_purchase':
          return 'Tovar xaridi';
        default:
          return 'Chiqim';
      }
    } else {
      switch (category) {
        case 'table':
          return 'Stol to\'lovi';
        case 'shop':
          return 'Bar savdosi';
        case 'debt_payment':
          return 'Nasiya to\'lovi';
        default:
          return 'Kirim';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = record.type == 'income';
    final amountColor = isIncome ? AppColors.success : AppColors.danger;
    final absAmount = record.amount.abs();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            final receiptText =
                ReceiptGenerator.forCashRecord(record: record);
            showDialog(
              context: context,
              builder: (context) =>
                  ReceiptPreviewDialog(receiptText: receiptText),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                // Ikonka
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isIncome
                        ? AppColors.success.withOpacity(0.12)
                        : AppColors.danger.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getCategoryIcon(record.category, record.type),
                    color: amountColor,
                    size: 20,
                  ),
                ),
                const Gap(12),

                // Ma'lumot
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getCategoryLabel(record.category, record.type),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const Gap(8),
                          Text(
                            Formatters.timeOnly(record.recordedAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textDisabled,
                            ),
                          ),
                        ],
                      ),
                      const Gap(4),
                      Text(
                        record.description ??
                            (isIncome ? 'Kassa tushumi' : 'Chiqim'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const Gap(8),

                // Summa va Chek ko'rish
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${isIncome ? '+' : '-'}${Formatters.currency(absAmount)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: amountColor,
                      ),
                    ),
                    const Gap(6),
                    IconButton(
                      icon: const Icon(Icons.receipt_outlined,
                          size: 18, color: AppColors.textSecondary),
                      tooltip: 'Chekni ko\'rish',
                      onPressed: () {
                        final receiptText =
                            ReceiptGenerator.forCashRecord(record: record);
                        showDialog(
                          context: context,
                          builder: (context) =>
                              ReceiptPreviewDialog(receiptText: receiptText),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
