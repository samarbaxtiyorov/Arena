// ============================================
// Arena — Do'kon POS Asosiy Ekrani (Skrinshot 7 bilan 1:1)
// Qidiruv + QR tugmasi, Kategoriya chiplari, 2-ustunli tovarlar
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
      ref.read(cartProvider.notifier).add(found);
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
    final cart = ref.watch(cartProvider);
    final selectedCategory = ref.watch(shopCategoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // ── Sarlavha Qatori (Do'kon POS, QR, Sync) ─────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 48), // Balans uchun bo'sh joy
                        const Text(
                          "Do'kon POS",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.qr_code_scanner_rounded,
                                color: Color(0xFF2563EB),
                                size: 24,
                              ),
                              onPressed: () => _handleScanBarcode(context, ref),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.sync_rounded,
                                color: Color(0xFF2563EB),
                                size: 24,
                              ),
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
                      ],
                    ),
                  ),
                ),

                // ── Qidiruv Maydoni + QR Tugmasi ───────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              onChanged: (val) => ref
                                  .read(shopSearchQueryProvider.notifier)
                                  .setQuery(val),
                              style: const TextStyle(fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: "Nomi yoki shtrix-kodi...",
                                hintStyle: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Color(0xFF94A3B8),
                                  size: 20,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const Gap(10),
                        // QR Skaner Ko'k tugmasi
                        InkWell(
                          onTap: () => _handleScanBarcode(context, ref),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFBFDBFE),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner_rounded,
                              color: Color(0xFF2563EB),
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: Gap(12)),

                // ── Kategoriya Chiplari ───────────────────────────
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
                          label: "Yegulik va gazaklar",
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

                // ── 2-Ustunli Mahsulotlar To'ri (Grid) ─────────────
                filteredProducts.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.storefront_outlined,
                                size: 48,
                                color: Color(0xFF94A3B8),
                              ),
                              const Gap(12),
                              const Text(
                                "Mahsulotlar topilmadi",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const Gap(16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => const AddProductDialog(),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text("Yangi tovar qo'shish"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
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

            // ── Pastki Savat / Checkout Bar ────────────────────
            if (cart.totalQuantity > 0)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${cart.totalQuantity}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Gap(12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Jami savat:",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
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
                        ],
                      ),
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
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDBEAFE) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFDBEAFE)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, size: 16, color: Color(0xFF2563EB)),
              const Gap(6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
