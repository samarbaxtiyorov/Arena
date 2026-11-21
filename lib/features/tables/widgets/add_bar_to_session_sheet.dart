// ============================================
// Arena — Stolga Bar Buyurtmasi Qo'shish Varag'i
// Maydon kartasidagi [☕] tugmasi
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:drift/drift.dart' show Value;

import '../../../core/utils/formatters.dart';
import '../../../core/utils/session_billing_helper.dart';
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
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);
    final allProducts = productsAsync.value ?? [];

    final products = allProducts.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    int totalBarSum = 0;
    for (final p in allProducts) {
      final qty = _selectedQuantities[p.id] ?? 0;
      totalBarSum += qty * p.price;
    }

    final existingBarItems =
        SessionBillingHelper.getBarItemsSummary(widget.session.notes);
    final existingBarSum =
        SessionBillingHelper.getBarTotal(widget.session.notes);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
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
          const Gap(14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
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
                    const Gap(2),
                    const Text(
                      "Ichimlik yoki yeguliklarni hisobga kiriting",
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_cafe_rounded,
                  color: Color(0xFFD97706),
                  size: 22,
                ),
              ),
            ],
          ),

          // Oldingi buyurtmalar bo'lsa ko'rsatamiz
          if (existingBarSum > 0) ...[
            const Gap(12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded,
                      size: 16, color: Color(0xFF64748B)),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      "Oldingi buyurtmalar (${formatSum(existingBarSum)}): ${existingBarItems.join(', ')}",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Gap(12),

          // Qidiruv maydoni
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: "Mahsulot qidirish...",
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          const Gap(12),

          // Mahsulotlar ro'yxati
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.38,
            ),
            child: products.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        "Mahsulotlar topilmadi",
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: products.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final qty = _selectedQuantities[product.id] ?? 0;
                      final isOutOfStock = product.stock <= 0;
                      final canAddMore = !isOutOfStock && qty < product.stock;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isOutOfStock
                                    ? const Color(0xFFFEE2E2)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.fastfood_outlined,
                                color: isOutOfStock
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF64748B),
                                size: 18,
                              ),
                            ),
                            const Gap(12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isOutOfStock
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF0F172A),
                                      decoration: isOutOfStock
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        formatSum(product.price),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isOutOfStock
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFFD97706),
                                        ),
                                      ),
                                      const Gap(8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isOutOfStock
                                              ? const Color(0xFFFEF2F2)
                                              : (product.stock <= 5
                                                  ? const Color(0xFFFFFBEB)
                                                  : const Color(0xFFF1F5F9)),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isOutOfStock
                                              ? "Tugagan (0 dona)"
                                              : "Qoldiq: ${product.stock} dona",
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: isOutOfStock
                                                ? const Color(0xFFEF4444)
                                                : (product.stock <= 5
                                                    ? const Color(0xFFD97706)
                                                    : const Color(0xFF64748B)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Miqdor boshqaruvi
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      color: Color(0xFF94A3B8), size: 22),
                                  onPressed: qty > 0
                                      ? () {
                                          setState(() {
                                            _selectedQuantities[product.id] =
                                                qty - 1;
                                          });
                                        }
                                      : null,
                                ),
                                Container(
                                  constraints: const BoxConstraints(minWidth: 24),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$qty',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: qty > 0
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.add_circle,
                                    color: canAddMore
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFFCBD5E1),
                                    size: 22,
                                  ),
                                  onPressed: canAddMore
                                      ? () {
                                          setState(() {
                                            _selectedQuantities[product.id] =
                                                qty + 1;
                                          });
                                        }
                                      : null,
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
                      // Ombor tekshiruvi: zaxirada yetarli ekanligini qayta tekshirish
                      for (final p in allProducts) {
                        final qty = _selectedQuantities[p.id] ?? 0;
                        if (qty > 0 && qty > p.stock) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${p.name} dan omborda yetarli emas (mavjud: ${p.stock} dona)!"),
                              backgroundColor: const Color(0xFFEF4444),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                      }

                      final db = ref.read(appDatabaseProvider);
                      // String summary yasash
                      final items = <String>[];
                      for (final p in allProducts) {
                        final qty = _selectedQuantities[p.id] ?? 0;
                        if (qty > 0) {
                          items.add(
                              "${p.name} x$qty (${formatSum(p.price * qty)})");
                          // Ombor qoldig'ini kamaytirish
                          await db.productsDao.decreaseStock(p.id, qty);
                        }
                      }

                      final newNotes = SessionBillingHelper.composeNotesWithBar(
                        currentNotes: widget.session.notes,
                        newItemsSummary: items,
                        addedBarSum: totalBarSum,
                      );

                      final currentBarTotal =
                          SessionBillingHelper.getBarTotal(newNotes);
                      final gameAmt =
                          SessionBillingHelper.calculateGameAmount(
                        startedAt: widget.session.startedAt,
                        pricePerHour: widget.table.pricePerHour,
                      );
                      final newTotal = gameAmt + currentBarTotal;

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
                                "+${formatSum(totalBarSum)} bar buyurtmasi stol hisobiga qo'shildi!"),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
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
                elevation: 0,
              ),
              child: Text(
                totalBarSum > 0
                    ? "Hisobga qo'shish: +${formatSum(totalBarSum)}"
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
