// ============================================
// Arena — Do'kon Tovar Kartasi (Super Zamonaviy POS Dizayn)
// Haqiqiy surat, toifa emojisi, jonli zaxira indikatori,
// ko'zga yoqimli narx va tezkor savat stepperi (+ / -)
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

  String _getCategoryEmoji(String category, String name) {
    final n = name.toLowerCase();
    if (category == 'drink' ||
        n.contains('cola') ||
        n.contains('fanta') ||
        n.contains('pepsi') ||
        n.contains('suv')) {
      return '🥤';
    } else if (category == 'energy' ||
        n.contains('flash') ||
        n.contains('redbull')) {
      return '⚡';
    } else if (category == 'snack' ||
        n.contains('chips') ||
        n.contains('lays') ||
        n.contains('pista')) {
      return '🍫';
    } else if (category == 'coffee' ||
        category == 'hot' ||
        n.contains('choy') ||
        n.contains('kofe') ||
        n.contains('coffee')) {
      return '☕';
    }
    return '📦';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final inCart = cart.items[product.id];
    final qtyInCart = inCart?.quantity ?? 0;
    final isOutOfStock = product.stock <= 0;
    final isLowStock = product.stock > 0 && product.stock <= 5;

    final imagePath = ProductAssetHelper.getImageForProduct(product.name);
    final emoji = _getCategoryEmoji(product.category ?? '', product.name);

    return InkWell(
      onTap: isOutOfStock
          ? null
          : () {
              // Kartani bir marta bosish orqali tezkor savatga qo'shish
              if (qtyInCart < product.stock) {
                ref.read(cartProvider.notifier).addItem(product);
              }
            },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: qtyInCart > 0
                ? const Color(0xFF2563EB)
                : const Color(0xFFE2E8F0),
            width: qtyInCart > 0 ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: qtyInCart > 0
                  ? const Color(0xFF2563EB).withOpacity(0.12)
                  : Colors.black.withOpacity(0.04),
              blurRadius: qtyInCart > 0 ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Tovar Rasmi va Badge'lar ─────────────
            Expanded(
              flex: 12,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Asosiy fotosurat
                  Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFFF1F5F9),
                      child: const Center(
                        child: Icon(Icons.shopping_bag_outlined,
                            size: 36, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                  // Silliq qoraytirish gradienti
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.25),
                          Colors.transparent,
                          Colors.black.withOpacity(0.65),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),

                  // Yuqori Chapda: Kategoriya emojisi
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24, width: 0.5),
                      ),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),

                  // Yuqori O'ngda: Savatdagi soni (Ko'k jonli badge)
                  if (qtyInCart > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shopping_cart,
                                size: 12, color: Colors.white),
                            const Gap(4),
                            Text(
                              "$qtyInCart",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Pastki Chapda: Zaxira indikatori
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOutOfStock
                            ? const Color(0xFFDC2626).withOpacity(0.9)
                            : (isLowStock
                                ? const Color(0xFFD97706).withOpacity(0.9)
                                : const Color(0xFF0F172A).withOpacity(0.75)),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: isOutOfStock
                              ? const Color(0xFFFCA5A5)
                              : (isLowStock
                                  ? const Color(0xFFFCD34D)
                                  : const Color(0xFF34D399)),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOutOfStock
                                  ? Colors.white
                                  : (isLowStock
                                      ? const Color(0xFFFCD34D)
                                      : const Color(0xFF34D399)),
                            ),
                          ),
                          const Gap(4),
                          Text(
                            isOutOfStock
                                ? "Tugagan"
                                : "${product.stock} dona",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── 2. Tovar Nomi, Narxi va Boshqaruv ────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tovar nomi
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Gap(2),

                  // Narxi
                  Row(
                    children: [
                      Text(
                        formatSum(product.price),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF059669),
                        ),
                      ),
                      const Gap(4),
                      if (product.barcode != null &&
                          product.barcode!.isNotEmpty)
                        const Icon(Icons.qr_code_2_rounded,
                            size: 13, color: Color(0xFF94A3B8)),
                    ],
                  ),

                  const Gap(8),

                  // Stepper (+ / -) yoki Savatga qo'shish tugmasi
                  if (qtyInCart > 0)
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                            color: const Color(0xFFBFDBFE), width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Ayirish
                          InkWell(
                            onTap: () {
                              ref
                                  .read(cartProvider.notifier)
                                  .removeOne(product);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: const SizedBox(
                              width: 32,
                              height: 32,
                              child: Center(
                                child: Icon(Icons.remove_rounded,
                                    size: 17, color: Color(0xFF1E40AF)),
                              ),
                            ),
                          ),
                          // Soni
                          Text(
                            '$qtyInCart',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                          // Qo'shish
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
                              width: 32,
                              height: 32,
                              child: Center(
                                child: Icon(
                                  Icons.add_rounded,
                                  size: 17,
                                  color: (qtyInCart < product.stock)
                                      ? const Color(0xFF1E40AF)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 32,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isOutOfStock
                            ? null
                            : () {
                                ref
                                    .read(cartProvider.notifier)
                                    .addItem(product);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOutOfStock
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFF0F172A),
                          foregroundColor: isOutOfStock
                              ? const Color(0xFF94A3B8)
                              : Colors.white,
                          padding: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isOutOfStock
                                  ? Icons.block_rounded
                                  : Icons.add_rounded,
                              size: 15,
                            ),
                            const Gap(4),
                            Text(
                              isOutOfStock ? "Tugagan" : "Savatga",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
