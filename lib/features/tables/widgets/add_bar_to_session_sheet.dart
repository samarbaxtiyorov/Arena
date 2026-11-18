// ============================================
// Arena — Stolga Bar Buyurtmasi Qo'shish Varag'i
// Maydon kartasidagi [☕] tugmasi
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:drift/drift.dart' show Value;

import '../../../core/utils/formatters.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/database_providers.dart';
import '../../shop/providers/shop_providers.dart';

class AddBarToSessionSheet extends ConsumerStatefulWidget {
  final Session session;
  final ClubTable table;

  const AddBarToSessionSheet({
    super.key,
    required this.session,
    required this.table,
  });

  @override
  ConsumerState<AddBarToSessionSheet> createState() =>
      _AddBarToSessionSheetState();
}

class _AddBarToSessionSheetState extends ConsumerState<AddBarToSessionSheet> {
  final Map<String, int> _selectedQuantities = {};

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);
    final products = productsAsync.value ?? [];

    int totalBarSum = 0;
    for (final p in products) {
      final qty = _selectedQuantities[p.id] ?? 0;
      totalBarSum += qty * p.price;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${widget.table.name} — Bardan qo'shish",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Text(
                    "Ichimlik yoki yeguliklarni tanlang",
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_cafe_rounded,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
            ],
          ),
          const Gap(16),

          // Mahsulotlar ro'yxati
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: products.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final product = products[index];
                final qty = _selectedQuantities[product.id] ?? 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.fastfood_outlined,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              formatSum(product.price),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Miqdor boshqaruvi
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Color(0xFF94A3B8)),
                            onPressed: qty > 0
                                ? () {
                                    setState(() {
                                      _selectedQuantities[product.id] = qty - 1;
                                    });
                                  }
                                : null,
                          ),
                          Text(
                            '$qty',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle,
                                color: Color(0xFF2563EB)),
                            onPressed: () {
                              setState(() {
                                _selectedQuantities[product.id] = qty + 1;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const Gap(16),

          // Tasdiqlash tugmasi
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: totalBarSum > 0
                  ? () async {
                      final db = ref.read(appDatabaseProvider);
                      // String summary yasash
                      final items = <String>[];
                      for (final p in products) {
                        final qty = _selectedQuantities[p.id] ?? 0;
                        if (qty > 0) {
                          items.add("${p.name} x$qty (${formatSum(p.price * qty)})");
                          // Ombor qoldig'ini kamaytirish
                          await db.productsDao.decreaseStock(p.id, qty);
                        }
                      }

                      final currentNotes = widget.session.notes ?? '';
                      final barSummary = "Bar: ${items.join(', ')}";
                      final newNotes = currentNotes.isEmpty
                          ? barSummary
                          : "$currentNotes | $barSummary";

                      final newTotal = widget.session.totalAmount + totalBarSum;

                      // Sessiyani yangilash
                      await (db.update(db.sessions)
                            ..where((s) => s.id.equals(widget.session.id)))
                          .write(SessionsCompanion(
                        totalAmount: Value(newTotal),
                        notes: Value(newNotes),
                        updatedAt: Value(DateTime.now()),
                        isSynced: const Value(false),
                      ));

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "+${formatSum(totalBarSum)} stol hisobiga qo'shildi!"),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                totalBarSum > 0
                    ? "Qo'shish: ${formatSum(totalBarSum)}"
                    : "Mahsulot tanlang",
                style: const TextStyle(
                  fontSize: 15,
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
