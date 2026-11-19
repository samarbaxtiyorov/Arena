// ============================================
// Arena — Do'kon POS Asosiy Ekrani (Super VIP Zamonaviy POS)
// Tezkor qidiruv, shtrix-kod skaneri, toifalar,
// haqiqiy tovar suratlari va suzuvchi savat (Floating Cart)
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/database_providers.dart';
import '../../kassa/widgets/receipt_preview_dialog.dart';
import '../providers/shop_providers.dart';
import '../widgets/product_card.dart';
import '../widgets/cart_checkout_sheet.dart';
import '../widgets/add_product_dialog.dart';
import '../widgets/barcode_scan_dialog.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  Future<void> _handleScanBarcode(BuildContext context, WidgetRef ref) async {
    final scanned = await showDialog<String>(
      context: context,
      builder: (_) => const BarcodeScanDialog(),
    );

    if (scanned == null || scanned.isEmpty) return;

    final allProducts = ref.read(productsStreamProvider).value ?? [];
    Product? found;
    for (final p in allProducts) {
      if (p.barcode != null && p.barcode!.trim() == scanned.trim()) {
        found = p;
        break;
      }
    }

    if (found != null) {
      ref.read(cartProvider.notifier).addItem(found);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const Gap(8),
                Expanded(
                  child: Text("${found.name} savatga qo'shildi!"),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      ref.read(shopSearchQueryProvider.notifier).setQuery(scanned);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Shtrix-kod: $scanned. Tovar topilmadi."),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: "Qo'shish",
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const AddProductDialog(),
                );
              },
            ),
          ),
        );
      }
    }
  }

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
                // ── 1. Sarlavha Paneli (Arena POS, Yangi Tovar, Skaner, Sync) ─
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(
                      children: [
                        // Chapda: Logo va POS Sarlavhasi
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF0F172A).withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.storefront_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const Gap(10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Do'kon & Bar POS",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                "Jami: ${allProducts.length} xil mahsulot",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // O'ngda: Tezkor Amallar
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 1. Yangi Tovar qo'shish
                            InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => const AddProductDialog(),
                                );
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFFA7F3D0)),
                                ),
                                child: const Icon(
                                  Icons.add_box_rounded,
                                  color: Color(0xFF059669),
                                  size: 20,
                                ),
                              ),
                            ),
                            const Gap(8),

                            // 2. Skaner tugmasi
                            InkWell(
                              onTap: () => _handleScanBarcode(context, ref),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFFBFDBFE)),
                                ),
                                child: const Icon(
                                  Icons.qr_code_scanner_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 20,
                                ),
                              ),
                            ),
                            const Gap(8),

                            // 3. Sinxronizatsiya
                            InkWell(
                              onTap: () async {
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
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFFE2E8F0)),
                                ),
                                child: const Icon(
                                  Icons.sync_rounded,
                                  color: Color(0xFF64748B),
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── 2. Qidiruv Maydoni + Skaner ───────────────────
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
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(Icons.search_rounded,
                                color: Color(0xFF94A3B8), size: 20),
                          ),
                          Expanded(
                            child: TextField(
                              onChanged: (val) => ref
                                  .read(shopSearchQueryProvider.notifier)
                                  .setQuery(val),
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(
                                hintText: "Tovar nomi yoki shtrix-kod...",
                                hintStyle: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.normal,
                                ),
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _handleScanBarcode(context, ref),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.qr_code_scanner_rounded,
                                      size: 16, color: Color(0xFF2563EB)),
                                  Gap(4),
                                  Text(
                                    "Skaner",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: Gap(12)),

                // ── 3. Toifalar Chiplari ───────────────────────────
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildCategoryChip(
                          ref: ref,
                          emoji: "🏷️",
                          label: "Barchasi",
                          categoryKey: 'all',
                          isSelected: selectedCategory == 'all',
                        ),
                        const Gap(8),
                        _buildCategoryChip(
                          ref: ref,
                          emoji: "🥤",
                          label: "Ichimliklar",
                          categoryKey: 'drink',
                          isSelected: selectedCategory == 'drink',
                        ),
                        const Gap(8),
                        _buildCategoryChip(
                          ref: ref,
                          emoji: "⚡",
                          label: "Energetiklar",
                          categoryKey: 'energy',
                          isSelected: selectedCategory == 'energy',
                        ),
                        const Gap(8),
                        _buildCategoryChip(
                          ref: ref,
                          emoji: "🍫",
                          label: "Gazaklar",
                          categoryKey: 'snack',
                          isSelected: selectedCategory == 'snack',
                        ),
                        const Gap(8),
                        _buildCategoryChip(
                          ref: ref,
                          emoji: "☕",
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
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.storefront_outlined,
                                  size: 48,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              const Gap(14),
                              const Text(
                                "Mahsulotlar topilmadi",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const Gap(4),
                              const Text(
                                "Qidiruvni o'zgartiring yoki yangi tovar qo'shing",
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF64748B)),
                              ),
                              const Gap(16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => const AddProductDialog(),
                                  );
                                },
                                icon: const Icon(Icons.add_rounded),
                                label: const Text("Yangi tovar qo'shish"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
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
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.72,
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

            // ── 5. Pastki Floating Savat Paneli (Floating Checkout Bar) ──
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
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Savatdagi tovarlar soni belgisi
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shopping_cart_rounded,
                                size: 16, color: Colors.white),
                            const Gap(6),
                            Text(
                              '${cart.totalQuantity}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(12),

                      // Jami summa
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Jami to'lov:",
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
                                color: Color(0xFF34D399),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Savatni tozalash tugmasi
                      IconButton(
                        onPressed: () {
                          ref.read(cartProvider.notifier).clear();
                        },
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Color(0xFF94A3B8), size: 20),
                        tooltip: "Savatni tozalash",
                      ),

                      const Gap(4),

                      // To'lov / Sotish tugmasi
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
                              fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
    required String emoji,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                  ? const Color(0xFF0F172A).withOpacity(0.15)
                  : Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const Gap(6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
