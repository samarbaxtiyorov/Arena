// ============================================
// Arena — Savat va To'lovni Yakunlash Modali
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
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
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Sarlavha
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined,
                        color: AppColors.primary, size: 24),
                    const Gap(10),
                    Text(
                      'Savat (${cartState.totalCount} ta tovar)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (!cartState.isEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    label: const Text('Tozalash'),
                    onPressed: () {
                      ref.read(cartProvider.notifier).clear();
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ),

          const Divider(color: AppColors.surfaceBorder, height: 1),

          // Tovar elementlari ro'yxati
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(
                child: Text(
                  'Savat bo\'sh',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Gap(10),
                itemBuilder: (context, index) {
                  final it = items[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                it.product.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Gap(2),
                              Text(
                                '${Formatters.currency(it.product.price)} x ${it.quantity} ta',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Miqdor boshqaruvi
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16),
                              color: AppColors.danger,
                              onPressed: () {
                                ref
                                    .read(cartProvider.notifier)
                                    .removeOne(it.product);
                              },
                            ),
                            Text(
                              it.quantity.toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16),
                              color: AppColors.success,
                              onPressed: () {
                                ref
                                    .read(cartProvider.notifier)
                                    .add(it.product);
                              },
                            ),
                          ],
                        ),
                        const Gap(10),
                        Text(
                          Formatters.currency(it.subtotal),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          if (!cartState.isEmpty) ...[
            const Divider(color: AppColors.surfaceBorder, height: 1),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Jami summa
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Jami to\'lov:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        Formatters.currency(cartState.totalAmount),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),

                  const Gap(16),

                  // To'lov turi
                  Row(
                    children: [
                      _PaymentChip(
                        label: '💵 Naqd',
                        isSelected: _paymentType == 'cash',
                        color: AppColors.success,
                        onTap: () => setState(() => _paymentType = 'cash'),
                      ),
                      const Gap(8),
                      _PaymentChip(
                        label: '💳 Karta',
                        isSelected: _paymentType == 'card',
                        color: AppColors.primary,
                        onTap: () => setState(() => _paymentType = 'card'),
                      ),
                      const Gap(8),
                      _PaymentChip(
                        label: '📒 Nasiya',
                        isSelected: _paymentType == 'debt',
                        color: AppColors.warning,
                        onTap: () => setState(() => _paymentType = 'debt'),
                      ),
                    ],
                  ),

                  // Agar nasiya tanlansa — mijoz tanlash
                  if (_paymentType == 'debt') ...[
                    const Gap(14),
                    StreamBuilder<List<Customer>>(
                      stream: db.customersDao.watchAllCustomers(),
                      builder: (context, snapshot) {
                        final customers = snapshot.data ?? [];
                        return DropdownButtonFormField<String>(
                          value: _selectedCustomerId,
                          decoration: InputDecoration(
                            labelText: 'Mijozni tanlang (Nasiya)',
                            prefixIcon: const Icon(Icons.person_outline,
                                color: AppColors.warning),
                            filled: true,
                            fillColor: AppColors.surfaceAlt,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          dropdownColor: AppColors.surfaceAlt,
                          items: customers
                              .map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(
                                      '${c.name} (${Formatters.currency(c.totalDebt)})',
                                      style: const TextStyle(
                                          color: AppColors.textPrimary),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedCustomerId = val;
                              final match = customers
                                  .where((c) => c.id == val)
                                  .firstOrNull;
                              _selectedCustomerName = match?.name;
                            });
                          },
                        );
                      },
                    ),
                  ],

                  const Gap(20),

                  // To'lov tugmasi
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () => _onCheckout(items, cartState.totalAmount),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Sotish (${Formatters.currency(cartState.totalAmount)})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _PaymentChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.18) : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppColors.surfaceBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
