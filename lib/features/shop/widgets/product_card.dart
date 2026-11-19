// ============================================
// Arena — Do'kon Tovar Kartasi
// Haqiqiy professional fotosurat, aniq narx,
// qoldiq zaxirasi va qulay savat hisoblagichi (+ / -)
// Hech qanday keraksiz emoji yoki shtrix-kodlarsiz!
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

    return InkWell(
      onTap: isOutOfStock
          ? null
          : () {
              // Kartani bosganda savatga 1 dona qo'shish
              if (qtyInCart < product.stock) {
                ref.read(cartProvider.notifier).addItem(product);
              }
            },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
              blurRadius: qtyInCart > 0 ? 10 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Tovar Haqiqiy Fotosurati ─────────────
            Expanded(
              flex: 12,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Haqiqiy fotosurat
                  Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFFF1F5F9),
                      child: const Center(
                        child: Icon(Icons.fastfood_rounded,
                            size: 36, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),

                  // Yengil silliq soya
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.55),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),

                  // Yuqori O'ngda: Savatdagi soni (faqat savatda bor bo'lsa)
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
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Text(
                          "$qtyInCart ta",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),

                  // Pastki Chapda: Zaxira indikatori
                  Positioned(
                    bottom: 6,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOutOfStock
                            ? const Color(0xFFDC2626)
                            : (isLowStock
                                ? const Color(0xFFD97706)
                                : const Color(0xFF0F172A).withOpacity(0.75)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isOutOfStock
                            ? "Tugagan"
                            : "${product.stock} dona",
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

            // ── 2. Nomi, Narxi va Boshqaruv ─────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nomi
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Gap(2),

                  // Narxi
                  Text(
                    formatSum(product.price),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF059669),
                    ),
                  ),

                  const Gap(8),

                  // Stepper (+ / -) yoki Savatga qo'shish tugmasi
                  if (qtyInCart > 0)
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
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
                                    size: 16, color: Color(0xFF1E40AF)),
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
                                  size: 16,
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          isOutOfStock ? "Tugagan" : "+ Savatga",
                          style: const TextStyle(
                            fontSize: 12,
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
      ),
    );
  }
}
