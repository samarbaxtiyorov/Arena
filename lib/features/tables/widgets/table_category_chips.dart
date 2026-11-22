// ============================================
// Arena — Toifalar bo'yicha Filter Chiplar (Skrinshot 6 bilan 1:1)
// [✓ Barchasi 6], [⚽ Futbol 2], [🎱 Bilyard 4], [🎮 PlayStation]
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../providers/tables_providers.dart';

class TableCategoryChips extends ConsumerWidget {
  const TableCategoryChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(tableCategoryProvider);
    final tablesAsync = ref.watch(tablesStreamProvider);
    final tables = tablesAsync.value ?? [];

    final existingTypes = tables.map((t) => t.type.toLowerCase()).toSet();

    const knownIcons = {
      'football': '⚽',
      'billiard': '🎱',
      'ps': '🎮',
      'playstation': '🎮',
      'tennis': '🎾',
      'table_tennis': '🏓',
      'bowling': '🎳',
      'karaoke': '🎤',
    };
    const knownLabels = {
      'football': 'Futbol',
      'billiard': 'Bilyard',
      'ps': 'PlayStation',
      'playstation': 'PlayStation',
      'tennis': 'Tennis',
      'table_tennis': 'Stol tennisi',
      'bowling': 'Bouling',
      'karaoke': 'Karaoke',
    };

    final allPresets = [
      {'key': 'football', 'label': 'Futbol', 'icon': '⚽'},
      {'key': 'billiard', 'label': 'Bilyard', 'icon': '🎱'},
      {'key': 'ps', 'label': 'PlayStation', 'icon': '🎮'},
      {'key': 'tennis', 'label': 'Tennis', 'icon': '🎾'},
    ];

    // Faqat klubda mavjud bo'lgan toifalarni ko'rsatamiz (mavjud bo'lmaganlari chiqmaydi)
    final categories = <Map<String, String>>[
      {'key': 'all', 'label': 'Barchasi', 'icon': ''},
    ];

    for (final preset in allPresets) {
      if (existingTypes.contains(preset['key'])) {
        categories.add(preset);
      }
    }
    for (final type in existingTypes) {
      if (!categories.any((c) => c['key'] == type)) {
        categories.add({
          'key': type,
          'label': knownLabels[type] ??
              (type.isNotEmpty
                  ? type[0].toUpperCase() + type.substring(1)
                  : type),
          'icon': knownIcons[type] ?? '🏟',
        });
      }
    }

    if (categories.isNotEmpty && !categories.any((c) => c['key'] == selectedCategory)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(tableCategoryProvider.notifier).select('all');
      });
    }

    int getCount(String key) {
      if (key == 'all') return tables.length;
      return tables.where((t) => t.type == key).length;
    }

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const Gap(8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final key = cat['key']!;
          final icon = cat['icon']!;
          final label = cat['label']!;
          final isSelected = selectedCategory == key;
          final count = getCount(key);

          return InkWell(
            onTap: () =>
                ref.read(tableCategoryProvider.notifier).select(key),
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected && key == 'all') ...[
                    const Icon(Icons.check, size: 16, color: Colors.white),
                    const Gap(6),
                  ] else if (icon.isNotEmpty) ...[
                    Text(icon, style: const TextStyle(fontSize: 14)),
                    const Gap(6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  const Gap(6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.22)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF64748B),
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
