// ============================================
// Arena — Savat va To'lovni Yakunlash Modali (Super POS Dizayn)
// Tovarlarning haqiqiy suratlari, to'lov turlari,
// qarz/nasiya integratsiyasi va kassa cheki
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/product_asset_helper.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/database_providers.dart';
import '../providers/shop_providers.dart';

class CartCheckoutSheet extends ConsumerStatefulWidget {
  const CartCheckoutSheet({super.key});

  @override
  ConsumerState<CartCheckoutSheet> createState() => _CartCheckoutSheetState();
}

class _CartCheckoutSheetState extends ConsumerState<CartCheckoutSheet> {
  String _paymentType = 'cash'; // 'cash', 'card', 'debt'
  String? _selectedCustomerId;
  String? _selectedCustomerName;
  bool _isLoading = false;

  Future<void> _onCheckout(List<CartItem> items, int totalAmount) async {
    if (_paymentType == 'debt' && _selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iltimos, nasiya uchun mijozni tanlang!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(shopControllerProvider).checkout(
            items: items,
            paymentType: _paymentType,
            customerId: _selectedCustomerId,
          );

      final now = DateTime.now();
      final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(now);
      final buffer = StringBuffer();
      buffer.writeln('================================');
      buffer.writeln('           ARENA POS            ');
      buffer.writeln('     Do\'kon / Bar Savdosi       ');
      buffer.writeln('================================');
      buffer.writeln('Sana: $dateStr');
      if (_selectedCustomerName != null) {
        buffer.writeln('Mijoz: $_selectedCustomerName');
      }
      buffer.writeln('--------------------------------');
      for (final item in items) {
        final lineName = '${item.product.name} x${item.quantity}';
        final linePrice = formatSum(item.subtotal);
        final pad = 32 - lineName.length - linePrice.length;
        if (pad > 0) {
          buffer.writeln('$lineName${" " * pad}$linePrice');
        } else {
          buffer.writeln('$lineName $linePrice');
        }
      }
      buffer.writeln('--------------------------------');
      buffer.writeln('JAMI TO\'LOV: ${formatSum(totalAmount)}');
      final pTypeName = _paymentType == 'cash'
          ? 'NAQD PUL'
          : _paymentType == 'card'
              ? 'BANK KARTASI'
              : 'NASIYA / QARZ';
      buffer.writeln('To\'lov turi: $pTypeName');
      buffer.writeln('================================');
      buffer.writeln('     Xaridingiz uchun rahmat!   ');
      buffer.writeln('================================');

      final receiptText = buffer.toString();

      if (mounted) {
        Navigator.of(context).pop(receiptText);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Savdo muvaffaqiyatli amalga oshirildi!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final db = ref.watch(appDatabaseProvider);
    final items = cartState.itemsList;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tutqich
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              height: 4,
              width: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Sarlavha
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shopping_bag_rounded,
                          color: Color(0xFF2563EB), size: 20),
                    ),
                    const Gap(10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Savat (${cartState.totalCount} ta tovar)',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Jami: ${formatSum(cartState.totalSum)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (!cartState.isEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                    ),
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    label: const Text(
                      'Tozalash',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    onPressed: () {
                      ref.read(cartProvider.notifier).clear();
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Tovar elementlari ro'yxati
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(
                child: Text(
                  'Savat bo\'sh',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Gap(8),
                itemBuilder: (context, index) {
                  final it = items[index];
                  final imgPath =
                      ProductAssetHelper.getImageForProduct(it.product.name);

                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        // Rasm
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 48,
                            height: 48,
                            color: Colors.white,
                            child: Image.asset(
                              imgPath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.fastfood_rounded,
                                size: 24,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                        const Gap(10),

                        // Nomi va Narxi
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                it.product.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Gap(2),
                              Text(
                                '${formatSum(it.product.price)} x ${it.quantity} dona',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Miqdor boshqaruvi
                        Container(
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () => ref
                                    .read(cartProvider.notifier)
                                    .removeOne(it.product),
                                child: const SizedBox(
                                  width: 28,
                                  height: 30,
                                  child: Icon(Icons.remove,
                                      size: 14, color: Color(0xFFDC2626)),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  it.quantity.toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => ref
                                    .read(cartProvider.notifier)
                                    .addItem(it.product),
                                child: const SizedBox(
                                  width: 28,
                                  height: 30,
                                  child: Icon(Icons.add,
                                      size: 14, color: Color(0xFF059669)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(10),

                        // Subtotal
                        Text(
                          formatSum(it.subtotal),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // To'lov turi tanlash
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'To\'lov usulini tanlang:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const Gap(8),
                Row(
                  children: [
                    _buildPaymentChip(
                      id: 'cash',
                      label: 'Naqd pul',
                      icon: Icons.payments_rounded,
                      color: const Color(0xFF059669),
                    ),
                    const Gap(8),
                    _buildPaymentChip(
                      id: 'card',
                      label: 'Plastik karta',
                      icon: Icons.credit_card_rounded,
                      color: const Color(0xFF2563EB),
                    ),
                    const Gap(8),
                    _buildPaymentChip(
                      id: 'debt',
                      label: 'Nasiya / Qarz',
                      icon: Icons.assignment_ind_rounded,
                      color: const Color(0xFFD97706),
                    ),
                  ],
                ),

                // Qarz bo'lsa mijoz tanlash
                if (_paymentType == 'debt') ...[
                  const Gap(10),
                  StreamBuilder<List<Customer>>(
                    stream: db.customersDao.watchAllCustomers(),
                    builder: (context, snapshot) {
                      final customers = snapshot.data ?? [];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCD34D)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: const Text(
                              'Qarzdor mijozni tanlang...',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF92400E)),
                            ),
                            value: _selectedCustomerId,
                            items: customers.map((c) {
                              return DropdownMenuItem(
                                value: c.id,
                                child: Text(
                                  '${c.name} (${c.phone ?? "Tel yo'q"})',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A)),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              final cust =
                                  customers.firstWhere((c) => c.id == val);
                              setState(() {
                                _selectedCustomerId = val;
                                _selectedCustomerName = cust.name;
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),

          // Pastki To'lovni tasdiqlash paneli
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Jami to\'lov:',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        formatSum(cartState.totalSum),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: (_isLoading || items.isEmpty)
                        ? null
                        : () => _onCheckout(items, cartState.totalSum),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline_rounded,
                                  size: 18),
                              Gap(8),
                              Text(
                                'To\'lovni Tasdiqlash',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentChip({
    required String id,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _paymentType == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _paymentType = id),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.12) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? color : const Color(0xFF64748B), size: 18),
              const Gap(4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? color : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
