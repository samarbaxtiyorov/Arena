// ============================================
// Arena — Do'kon Tovar Kartasi
// Orqa fonda mahsulotning haqiqiy surati (Cola, Chips, Choy, Fanta, Suv),
// Oltin narx, Qoldiq va interaktiv hisoblagich (+ / -)
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/product_asset_helper.dart';
import '../../../data/local/app_database.dart';
import '../providers/shop_providers.dart';

class ProductCard extends ConsumerWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final inCart = cart.items[product.id];
    final qtyInCart = inCart?.quantity ?? 0;
    final isOutOfStock = product.stock <= 0;
    final isLowStock = product.stock > 0 && product.stock <= 5;

    final imagePath = ProductAssetHelper.getImageForProduct(product.name);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: qtyInCart > 0
              ? const Color(0xFF2563EB)
              : const Color(0xFFE2E8F0),
          width: qtyInCart > 0 ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: qtyInCart > 0
                ? const Color(0xFF2563EB).withOpacity(0.08)
                : Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Tovar Rasmi va Badge'lar ─────────────
          Expanded(
            flex: 11,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                ),
                // Gradient soya
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                // Savatdagi soni (Badge)
                if (qtyInCart > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        "$qtyInCart ta",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                // Qoldiq indikatori pastda
                Positioned(
                  bottom: 6,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isOutOfStock
                          ? const Color(0xFFEF4444)
                          : isLowStock
                              ? const Color(0xFFF59E0B)
                              : Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isOutOfStock
                          ? "Tugagan"
                          : "Qoldiq: ${product.stock} dona",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 2. Tovar Nomi, Narxi va Boshqaruv ────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Gap(2),
                Text(
                  formatSum(product.price),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFD97706),
                  ),
                ),
                const Gap(6),

                // Stepper (+ / -) yoki Savatga tugmasi
                if (qtyInCart > 0)
                  Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () {
                            ref.read(cartProvider.notifier).removeOne(product);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: const SizedBox(
                            width: 28,
                            height: 30,
                            child: Icon(Icons.remove,
                                size: 15, color: Color(0xFF334155)),
                          ),
                        ),
                        Text(
                          '$qtyInCart',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        InkWell(
                          onTap: (qtyInCart < product.stock)
                              ? () {
                                  ref
                                      .read(cartProvider.notifier)
                                      .addItem(product);
                                }
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 28,
                            height: 30,
                            child: Icon(
                              Icons.add,
                              size: 15,
                              color: (qtyInCart < product.stock)
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    height: 30,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isOutOfStock
                          ? null
                          : () {
                              ref.read(cartProvider.notifier).addItem(product);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEFF6FF),
                        foregroundColor: const Color(0xFF2563EB),
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFFBFDBFE)),
                        ),
                      ),
                      child: Text(
                        isOutOfStock ? "Yo'q" : "+ Qo'shish",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
