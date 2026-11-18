// ============================================
// Arena — Do'kon Toifalari Filtrlari
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/shop_providers.dart';

class ShopCategoryChips extends ConsumerWidget {
  const ShopCategoryChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(shopCategoryProvider);
    final productsAsync = ref.watch(productsStreamProvider);
    final products = productsAsync.value ?? [];

    final categories = [
      {'key': 'all', 'label': 'Barchasi', 'icon': '🛒'},
      {'key': 'drink', 'label': 'Ichimliklar', 'icon': '🥤'},
      {'key': 'energy', 'label': 'Energetik', 'icon': '⚡'},
      {'key': 'snack', 'label': 'Yeguliklar', 'icon': '🍫'},
      {'key': 'coffee', 'label': 'Kofe/Choy', 'icon': '☕'},
      {'key': 'other', 'label': 'Boshqa', 'icon': '📦'},
    ];

    int getCount(String key) {
      if (key == 'all') return products.length;
      return products.where((p) => p.category == key).length;
    }

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const Gap(8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final key = cat['key']!;
          final isSelected = selectedCategory == key;
          final count = getCount(key);

          return InkWell(
            onTap: () => ref.read(shopCategoryProvider.notifier).select(key),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surfaceBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat['icon']!, style: const TextStyle(fontSize: 14)),
                  const Gap(6),
                  Text(
                    cat['label']!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                  const Gap(6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.2)
                          : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
