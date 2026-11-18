// ============================================
// Arena — Tovar Zaxirasini Oshirish (Prikhod)
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/local/app_database.dart';
import '../providers/shop_providers.dart';

class AddStockDialog extends ConsumerStatefulWidget {
  final Product product;

  const AddStockDialog({super.key, required this.product});

  @override
  ConsumerState<AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends ConsumerState<AddStockDialog> {
  final _qtyController = TextEditingController(text: '10');
  bool _isLoading = false;

  final _quickQuantities = [5, 10, 20, 50, 100];

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  void _addQuick(int qty) {
    final current = int.tryParse(_qtyController.text.trim()) ?? 0;
    _qtyController.text = (current + qty).toString();
  }

  Future<void> _onSave() async {
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iltimos, to\'g\'ri miqdorni kiriting!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(shopControllerProvider).addStock(
            productId: widget.product.id,
            quantity: qty,
          );

      if (mounted) Navigator.of(context).pop(true);
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_shopping_cart,
                        color: AppColors.success, size: 24),
                  ),
                  const Gap(14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kirim Qilish (Prikhod)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(16),

              // Joriy qoldiq
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Hozirgi qoldiq:',
                        style: TextStyle(color: AppColors.textSecondary)),
                    Text(
                      '${widget.product.stock} dona',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ),

              const Gap(16),

              TextField(
                controller: _qtyController,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
                decoration: const InputDecoration(
                  labelText: 'Kirim miqdori',
                  prefixIcon: Icon(Icons.inventory, color: AppColors.success),
                  suffixText: 'dona',
                ),
              ),

              const Gap(10),

              Wrap(
                spacing: 6,
                children: _quickQuantities.map((val) {
                  return ActionChip(
                    backgroundColor: AppColors.surfaceAlt,
                    side: const BorderSide(color: AppColors.surfaceBorder),
                    label: Text('+$val',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textPrimary)),
                    onPressed: () => _addQuick(val),
                  );
                }).toList(),
              ),

              const Gap(24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Bekor qilish'),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                      onPressed: _isLoading ? null : _onSave,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Qo\'shish'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
