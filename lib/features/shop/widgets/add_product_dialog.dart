// ============================================
// Arena — Tovar Qo'shish va Tahrirlash Modali
// Shtrix-kod skaneri va to'liq ombor ma'lumotlari bilan
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/local/app_database.dart';
import '../providers/shop_providers.dart';
import 'barcode_scan_dialog.dart';

class AddProductDialog extends ConsumerStatefulWidget {
  final Product? productToEdit;

  const AddProductDialog({super.key, this.productToEdit});

  @override
  ConsumerState<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<AddProductDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _barcodeController;
  late String _category;
  bool _isLoading = false;

  bool get _isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _priceController =
        TextEditingController(text: p != null ? p.price.toString() : '');
    _stockController =
        TextEditingController(text: p != null ? p.stock.toString() : '0');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _category = p?.category ?? 'drink';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final scanned = await showDialog<String>(
      context: context,
      builder: (_) => const BarcodeScanDialog(),
    );
    if (scanned != null && scanned.isNotEmpty) {
      setState(() {
        _barcodeController.text = scanned;
      });
    }
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

    if (stock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zaxira miqdori manfiy bo\'lishi mumkin emas!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final barcodeVal = _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim();

      if (_isEditing) {
        await ref.read(shopControllerProvider).updateProduct(
              id: widget.productToEdit!.id,
              name: name,
              price: price,
              stock: stock,
              category: _category,
              barcode: barcodeVal,
            );
      } else {
        await ref.read(shopControllerProvider).addProduct(
              name: name,
              price: price,
              stock: stock,
              category: _category,
              barcode: barcodeVal,
            );
      }

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sarlavha
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isEditing
                            ? const Color(0xFFEFF6FF)
                            : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isEditing
                            ? Icons.edit_note_rounded
                            : Icons.add_box_rounded,
                        color: _isEditing
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF059669),
                        size: 26,
                      ),
                    ),
                    const Gap(14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing
                                ? 'Tovarni Tahrirlash'
                                : 'Yangi Tovar Qo\'shish',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            _isEditing
                                ? 'Ma\'lumotlarni o\'zgartiring va saqlang'
                                : 'Omborga yangi tovar kartasini kiriting',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Gap(20),

                // Tovar nomi
                TextField(
                  controller: _nameController,
                  autofocus: !_isEditing,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Tovar nomi *',
                    hintText: 'Masalan: Coca-Cola 0.5L, Lays Paprika...',
                    labelStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.shopping_bag_outlined,
                        size: 20, color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),

                const Gap(14),

                // Narx va Toifa qatori
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sotish narxi
                    Expanded(
                      flex: 6,
                      child: TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          labelText: 'Sotish narxi *',
                          suffixText: "so'm",
                          suffixStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                          labelStyle: const TextStyle(fontSize: 13),
                          prefixIcon: const Icon(Icons.payments_outlined,
                              size: 20, color: Color(0xFF059669)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                    ),
                    const Gap(10),
                    // Toifasi
                    Expanded(
                      flex: 5,
                      child: DropdownButtonFormField<String>(
                        value: _category,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          labelText: 'Toifasi',
                          labelStyle: const TextStyle(fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 14),
                        ),
                        dropdownColor: Colors.white,
                        items: const [
                          DropdownMenuItem(
                              value: 'drink', child: Text('🥤 Ichimlik')),
                          DropdownMenuItem(
                              value: 'energy', child: Text('⚡ Energetik')),
                          DropdownMenuItem(
                              value: 'snack', child: Text('🍫 Yegulik')),
                          DropdownMenuItem(
                              value: 'coffee', child: Text('☕ Choy/Kofe')),
                          DropdownMenuItem(
                              value: 'other', child: Text('📦 Boshqa')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _category = val);
                        },
                      ),
                    ),
                  ],
                ),

                const Gap(14),

                // Qoldiq (Zaxira)
                TextField(
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    labelText: _isEditing
                        ? 'Ombor qoldig\'i (dona)'
                        : 'Boshlang\'ich qoldiq (dona)',
                    hintText: '0',
                    labelStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.inventory_2_outlined,
                        size: 20, color: Color(0xFF2563EB)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),

                const Gap(14),

                // Shtrix-kod maydoni va [📷 Skaner] tugmachasi
                TextField(
                  controller: _barcodeController,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: 1.2,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Shtrix-kod',
                    hintText: '4780001234567...',
                    labelStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.qr_code_2_rounded,
                        size: 22, color: Color(0xFF475569)),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: TextButton.icon(
                        onPressed: _scanBarcode,
                        icon: const Icon(Icons.qr_code_scanner_rounded,
                            size: 18, color: Color(0xFF2563EB)),
                        label: const Text(
                          'Skaner',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFEFF6FF),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),

                const Gap(24),

                // Bekor qilish va Saqlash tugmalari
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Bekor qilish',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isEditing
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isEditing
                                        ? Icons.check_rounded
                                        : Icons.save_rounded,
                                    size: 18,
                                  ),
                                  const Gap(8),
                                  Text(
                                    _isEditing
                                        ? 'O\'zgarishlarni Saqlash'
                                        : 'Omborga Saqlash',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
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
