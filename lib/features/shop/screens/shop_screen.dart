// ============================================
// Arena — Do'kon / Bar Asosiy Ekrani
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/database_providers.dart';
import '../providers/shop_providers.dart';
import '../widgets/add_product_dialog.dart';
import '../widgets/cart_checkout_sheet.dart';
import '../widgets/product_card.dart';
import '../widgets/shop_category_chips.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredProducts = ref.watch(filteredProductsProvider);
    final productsAsync = ref.watch(productsStreamProvider);
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: const Row(
          children: [
            Icon(Icons.storefront_outlined, color: AppColors.success, size: 24),
            Gap(10),
            Text(
              'Do\'kon / Bar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          // Tovar qo'shish
          IconButton(
            tooltip: 'Yangi tovar qo\'shish',
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddProductDialog(),
              );
            },
          ),
          // Sinxronizatsiya
          IconButton(
            tooltip: 'Sinxronizatsiya qilish',
            icon: const Icon(Icons.sync, color: AppColors.textSecondary),
            onPressed: () async {
              final sync = ref.read(syncServiceProvider);
              final res = await sync.syncAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      res.isSuccess
                          ? 'Sinxronizatsiya muvaffaqiyatli! (${res.pushed} push, ${res.pulled} pull)'
                          : (res.wasOffline
                              ? 'Offline rejim'
                              : 'Xatolik yuz berdi'),
                    ),
                    backgroundColor: res.isSuccess
                        ? AppColors.success
                        : AppColors.warning,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          const Gap(8),
        ],
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. Qidiruv paneli
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tovar nomi yoki shtrix-kod...',
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.textSecondary),
                      suffixIcon:
                          ref.watch(shopSearchQueryProvider).isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    ref
                                        .read(shopSearchQueryProvider.notifier)
                                        .clear();
                                  },
                                )
                              : const Icon(Icons.qr_code_scanner,
                                  color: AppColors.textSecondary),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    onChanged: (val) {
                      ref
                          .read(shopSearchQueryProvider.notifier)
                          .setQuery(val);
                    },
                  ),
                ),
              ),

              // 2. Toifalar filtri
              const SliverToBoxAdapter(
                child: ShopCategoryChips(),
              ),

              const SliverToBoxAdapter(child: Gap(16)),

              // 3. Tovarlar to'ri (Grid)
              productsAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (err, _) => SliverFillRemaining(
                  child: Center(
                    child: Text('Xatolik: $err',
                        style: const TextStyle(color: AppColors.danger)),
                  ),
                ),
                data: (_) {
                  if (filteredProducts.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 64, color: AppColors.textDisabled),
                            Gap(12),
                            Text(
                              'Bu toifada tovarlar topilmadi',
                              style:
                                  TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.crossAxisExtent;
                        int crossAxisCount = 2;
                        if (width > 1200) {
                          crossAxisCount = 5;
                        } else if (width > 900) {
                          crossAxisCount = 4;
                        } else if (width > 600) {
                          crossAxisCount = 3;
                        }

                        return SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            mainAxisExtent: 185,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final product = filteredProducts[index];
                              return ProductCard(
                                key: ValueKey(product.id),
                                product: product,
                              );
                            },
                            childCount: filteredProducts.length,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              // Savat paneli uchun joy qoldirish
              const SliverToBoxAdapter(child: Gap(90)),
            ],
          ),

          // 4. Pastki suzuvchi Savat paneli (agar tovar qo'shilgan bo'lsa)
          if (!cartState.isEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const CartCheckoutSheet(),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.35),
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
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${cartState.totalCount} ta',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Gap(12),
                          Text(
                            Formatters.currency(cartState.totalAmount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const Row(
                        children: [
                          Text(
                            'Savat / To\'lov',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Gap(6),
                          Icon(Icons.arrow_forward,
                              color: Colors.white, size: 18),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
