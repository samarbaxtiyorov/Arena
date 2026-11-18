// ============================================
// Arena — Yangi Tovar Qo'shish Modali
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/shop_providers.dart';

class AddProductDialog extends ConsumerStatefulWidget {
  const AddProductDialog({super.key});

  @override
  ConsumerState<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<AddProductDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _barcodeController = TextEditingController();
  String _category = 'drink';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    final price = int.tryParse(_priceController.text.trim()) ?? 0;
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iltimos, tovar nomini kiriting!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iltimos, to\'g\'ri narx kiriting!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(shopControllerProvider).addProduct(
            name: name,
            price: price,
            stock: stock,
            category: _category,
            barcode: _barcodeController.text.trim().isEmpty
                ? null
                : _barcodeController.text.trim(),
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
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGlow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_box_outlined,
                          color: AppColors.primary, size: 24),
                    ),
                    const Gap(14),
                    const Text(
                      'Yangi Tovar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const Gap(20),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Tovar nomi *',
                    hintText: 'Coca-Cola 0.5L, Flash Up...',
                    prefixIcon: Icon(Icons.shopping_bag_outlined),
                  ),
                ),
                const Gap(14),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sotish narxi *',
                    prefixIcon: Icon(Icons.attach_money),
                    suffixText: 'so\'m',
                  ),
                ),
                const Gap(14),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                    labelText: 'Toifasi',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  dropdownColor: AppColors.surfaceAlt,
                  items: const [
                    DropdownMenuItem(value: 'drink', child: Text('🥤 Ichimliklar')),
                    DropdownMenuItem(value: 'energy', child: Text('⚡ Energetik')),
                    DropdownMenuItem(value: 'snack', child: Text('🍫 Yeguliklar')),
                    DropdownMenuItem(value: 'coffee', child: Text('☕ Kofe / Choy')),
                    DropdownMenuItem(value: 'other', child: Text('📦 Boshqa')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _category = val);
                  },
                ),
                const Gap(14),
                TextField(
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Boshlang\'ich qoldiq (dona)',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                ),
                const Gap(14),
                TextField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Shtrix-kod (ixtiyoriy)',
                    hintText: '4780001234567',
                    prefixIcon: Icon(Icons.qr_code_scanner),
                  ),
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
                            : const Text('Saqlash'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
