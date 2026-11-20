// ============================================
// Arena — Do'kon POS Asosiy Ekrani
// Kassir va Bar uchun sodda, tezkor va professional savdo interfeysi
// Ortiqcha skaner va plyus tugmalarsiz, haqiqiy tovar suratlari bilan
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/repositories/database_providers.dart';
import '../../kassa/widgets/receipt_preview_dialog.dart';
import '../providers/shop_providers.dart';
import '../widgets/product_card.dart';
import '../widgets/cart_checkout_sheet.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredProducts = ref.watch(filteredProductsProvider);
    final allProducts = ref.watch(productsStreamProvider).value ?? [];
    final cart = ref.watch(cartProvider);
    final selectedCategory = ref.watch(shopCategoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // ── 1. Sarlavha Paneli ────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(
                      children: [
                        // Chapda: Do'kon & Bar logotipi va sarlavhasi
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.storefront_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Do'kon & Bar POS",
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                "Mavjud: ${allProducts.length} xil mahsulot",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // O'ngda: Faqat Sinxronizatsiya tugmasi
                        IconButton(
                          icon: const Icon(
                            Icons.sync_rounded,
                            color: Color(0xFF2563EB),
                            size: 22,
                          ),
                          tooltip: "Sinxronlash",
                          onPressed: () async {
                            final sync = ref.read(syncServiceProvider);
                            final res = await sync.syncAll();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res.isSuccess
                                      ? "Sinxronizatsiya muvaffaqiyatli!"
                                      : "Offline rejim"),
                                  backgroundColor: res.isSuccess
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFF59E0B),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // ── 2. Qidiruv Maydoni (Skanersiz, Sodda va Tezkor) ───
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (val) => ref
                            .read(shopSearchQueryProvider.notifier)
                            .setQuery(val),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: "Mahsulot nomini qidirish...",
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                          ),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: Color(0xFF94A3B8), size: 20),
                          suffixIcon: ref.watch(shopSearchQueryProvider).isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded,
                                      size: 18, color: Color(0xFF64748B)),
                                  onPressed: () {
                                    ref
                                        .read(shopSearchQueryProvider.notifier)
                                        .clear();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: Gap(12)),

                // ── 3. Toifalar Chiplari (Emojisiz, Toza Matn) ───────
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildCategoryChip(
                          ref: ref,
                          label: "Barchasi",
                          categoryKey: 'all',
                          isSelected: selectedCategory == 'all',
                        ),
                        const Gap(8),
                        _buildCategoryChip(
                          ref: ref,
                          label: "Ichimliklar",
                          categoryKey: 'drink',
                          isSelected: selectedCategory == 'drink',
                        ),
                        const Gap(8),
                        _buildCategoryChip(
                          ref: ref,
                          label: "Energetiklar",
                          categoryKey: 'energy',
                          isSelected: selectedCategory == 'energy',
                        ),
                        const Gap(8),
                        _buildCategoryChip(
                          ref: ref,
                          label: "Gazaklar",
                          categoryKey: 'snack',
                          isSelected: selectedCategory == 'snack',
                        ),
                        const Gap(8),
                        _buildCategoryChip(
                          ref: ref,
                          label: "Choy va Qahva",
                          categoryKey: 'hot',
                          isSelected: selectedCategory == 'hot',
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: Gap(14)),

                // ── 4. 2-Ustunli Mahsulotlar To'ri (Grid) ─────────────
                filteredProducts.isEmpty
                    ? const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.storefront_outlined,
                                size: 44,
                                color: Color(0xFF94A3B8),
                              ),
                              Gap(12),
                              Text(
                                "Mahsulot topilmadi",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.74,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final product = filteredProducts[index];
                              return ProductCard(product: product);
                            },
                            childCount: filteredProducts.length,
                          ),
                        ),
                      ),
              ],
            ),

            // ── 5. Pastki Floating Savat Paneli ───────────────────
            if (cart.totalQuantity > 0)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Savatdagi tovarlar soni
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shopping_cart_rounded,
                                size: 15, color: Colors.white),
                            const Gap(5),
                            Text(
                              '${cart.totalQuantity}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(12),

                      // Jami to'lov
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Jami savat:",
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              formatSum(cart.totalSum),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Savatni tozalash
                      IconButton(
                        onPressed: () {
                          ref.read(cartProvider.notifier).clear();
                        },
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Color(0xFF94A3B8), size: 20),
                        tooltip: "Savatni tozalash",
                      ),

                      const Gap(4),

                      // Sotish tugmasi
                      ElevatedButton.icon(
                        onPressed: () async {
                          final receiptText =
                              await showModalBottomSheet<String>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const CartCheckoutSheet(),
                          );

                          if (receiptText != null && context.mounted) {
                            showDialog(
                              context: context,
                              builder: (_) => ReceiptPreviewDialog(
                                receiptText: receiptText,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text(
                          "Sotish",
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required WidgetRef ref,
    required String label,
    required String categoryKey,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        ref.read(shopCategoryProvider.notifier).select(categoryKey);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F172A)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF0F172A).withOpacity(0.12)
                  : Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}
