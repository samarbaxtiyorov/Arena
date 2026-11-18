// ============================================
// Arena — Tovar Kartasi (Product Card)
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/local/app_database.dart';
import '../providers/shop_providers.dart';
import 'add_stock_dialog.dart';

class ProductCard extends ConsumerWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'drink':
        return Icons.local_drink_outlined;
      case 'energy':
        return Icons.bolt;
      case 'snack':
        return Icons.cookie_outlined;
      case 'coffee':
        return Icons.coffee_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final inCartItem = cartState.items[product.id];
    final cartQuantity = inCartItem?.quantity ?? 0;
    final isOutOfStock = product.stock <= 0;

    // Qoldiq rangi
    Color stockColor;
    String stockLabel;
    if (product.stock > 10) {
      stockColor = AppColors.success;
      stockLabel = '${product.stock} dona';
    } else if (product.stock > 0) {
      stockColor = AppColors.warning;
      stockLabel = '${product.stock} dona qoldi';
    } else {
      stockColor = AppColors.danger;
      stockLabel = 'Tugagan';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cartQuantity > 0
              ? AppColors.primary.withOpacity(0.6)
              : AppColors.surfaceBorder,
          width: cartQuantity > 0 ? 1.5 : 1,
        ),
        boxShadow: [
          if (cartQuantity > 0)
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 12,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Yuqori qator: Ikonka, Qoldiq va Prikhod tugmasi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Icon(
                    _getCategoryIcon(product.category),
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                // Qoldiq ko'rsatkichi
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: stockColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: stockColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    stockLabel,
                    style: TextStyle(
                      color: stockColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Prikhod (zaxira oshirish) menyusi
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AddStockDialog(product: product),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add,
                        size: 16, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),

            const Gap(10),

            // Nomi va Narxi
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(4),
                Text(
                  Formatters.currency(product.price),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),

            const Gap(10),

            // Pastki savat boshqaruvi
            if (cartQuantity > 0)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      color: AppColors.danger,
                      onPressed: () {
                        ref.read(cartProvider.notifier).removeOne(product);
                      },
                    ),
                    Text(
                      cartQuantity.toString(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      color: AppColors.success,
                      onPressed: () {
                        ref.read(cartProvider.notifier).add(product);
                      },
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isOutOfStock ? AppColors.surfaceAlt : AppColors.primary,
                    foregroundColor:
                        isOutOfStock ? AppColors.textDisabled : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.add_shopping_cart, size: 16),
                  label: Text(
                    isOutOfStock ? 'Tugagan' : 'Savatga',
                    style: const TextStyle(fontSize: 13),
                  ),
                  onPressed: isOutOfStock
                      ? null
                      : () {
                          ref.read(cartProvider.notifier).add(product);
                        },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
