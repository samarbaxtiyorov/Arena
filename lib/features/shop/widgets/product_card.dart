// ============================================
// Arena — Do'kon Tovar Kartasi
// Ikonka, Nomi, Narxi, Qoldiq va interaktiv hisoblagich (+ / -)
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/local/app_database.dart';
import '../providers/shop_providers.dart';

class ProductCard extends ConsumerWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  IconData _getProductIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('suv') || n.contains('water') || n.contains('chortoq')) {
      return Icons.water_drop_rounded;
    } else if (n.contains('choy') || n.contains('kofe') || n.contains('tea') || n.contains('qahva')) {
      return Icons.local_cafe_rounded;
    } else if (n.contains('chips') || n.contains('lays') || n.contains('pista') || n.contains('snack') || n.contains('shokolad')) {
      return Icons.fastfood_rounded;
    } else if (n.contains('cola') || n.contains('fanta') || n.contains('pepsi') || n.contains('sharbat') || n.contains('sok') || n.contains('redbull')) {
      return Icons.local_drink_rounded;
    }
    return Icons.inventory_2_outlined;
  }

  Color _getProductColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('suv') || n.contains('water') || n.contains('chortoq')) {
      return const Color(0xFF0284C7); // Cyan
    } else if (n.contains('choy') || n.contains('kofe') || n.contains('tea') || n.contains('qahva')) {
      return const Color(0xFFD97706); // Amber
    } else if (n.contains('chips') || n.contains('lays') || n.contains('pista') || n.contains('snack')) {
      return const Color(0xFFEA580C); // Orange
    } else if (n.contains('cola')) {
      return const Color(0xFFDC2626); // Red
    } else if (n.contains('fanta')) {
      return const Color(0xFFF97316); // Orange-Red
    }
    return const Color(0xFF2563EB); // Blue default
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final inCart = cart.items[product.id];
    final qtyInCart = inCart?.quantity ?? 0;
    final isOutOfStock = product.stock <= 0;
    final isLowStock = product.stock > 0 && product.stock <= 5;

    final iconColor = _getProductColor(product.name);
    final iconData = _getProductIcon(product.name);

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
                ? const Color(0xFF2563EB).withOpacity(0.06)
                : Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── 1. Ikonka va Cart nishoni ────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              if (qtyInCart > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(8),
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
            ],
          ),

          const Gap(8),

          // ── 2. Nomi va Narxi ─────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(
                formatSum(product.price),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD97706),
                ),
              ),
              const Gap(2),
              Text(
                isOutOfStock
                    ? "Tugagan"
                    : isLowStock
                        ? "Qoldiq: ${product.stock} (kam)"
                        : "Qoldiq: ${product.stock} dona",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isOutOfStock
                      ? const Color(0xFFEF4444)
                      : isLowStock
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF64748B),
                ),
              ),
            ],
          ),

          const Gap(8),

          // ── 3. Interaktiv Stepper yoki Savatga tugmasi ─
          if (qtyInCart > 0)
            Container(
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
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
                      width: 32,
                      height: 32,
                      child: Icon(Icons.remove, size: 16, color: Color(0xFF475569)),
                    ),
                  ),
                  Text(
                    '$qtyInCart',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  InkWell(
                    onTap: (qtyInCart < product.stock)
                        ? () {
                            ref.read(cartProvider.notifier).addItem(product);
                          }
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: Icon(
                        Icons.add,
                        size: 16,
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
              height: 32,
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
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
