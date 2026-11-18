// ============================================
// Arena — Yangi Stol / Zona Qo'shish Modali
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/tables_providers.dart';

class AddTableDialog extends ConsumerStatefulWidget {
  const AddTableDialog({super.key});

  @override
  ConsumerState<AddTableDialog> createState() => _AddTableDialogState();
}

class _AddTableDialogState extends ConsumerState<AddTableDialog> {
  final _nameController = TextEditingController();
  final _priceController =
      TextEditingController(text: AppConstants.billiardPricePerHour.toString());
  String _type = 'billiard';
  bool _isLoading = false;

  final Map<String, int> _defaultPrices = {
    'billiard': AppConstants.billiardPricePerHour,
    'ps': AppConstants.playstationPerHour,
    'football': AppConstants.footballPricePerHour,
    'tennis': AppConstants.tennisPricePerHour,
    'other': 20000,
  };

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _onTypeChanged(String? newType) {
    if (newType == null) return;
    setState(() {
      _type = newType;
      _priceController.text = (_defaultPrices[newType] ?? 20000).toString();
    });
  }

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    final price = int.tryParse(_priceController.text.trim()) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iltimos, stol nomini kiriting!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Soatlik narxni to\'g\'ri kiriting!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(tablesControllerProvider).addTable(
            name: name,
            type: _type,
            pricePerHour: price,
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
                    child: const Icon(Icons.add_circle_outline,
                        color: AppColors.primary, size: 24),
                  ),
                  const Gap(14),
                  const Text(
                    'Yangi Stol / Zona',
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
                  labelText: 'Nomi (masalan: Bilyard 3, PS 4)',
                  prefixIcon: Icon(Icons.tag),
                ),
              ),
              const Gap(14),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Stol / O\'yin turi',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                dropdownColor: AppColors.surfaceAlt,
                items: const [
                  DropdownMenuItem(value: 'billiard', child: Text('🎱 Bilyard')),
                  DropdownMenuItem(value: 'ps', child: Text('🎮 PlayStation')),
                  DropdownMenuItem(value: 'football', child: Text('⚽ Futbol')),
                  DropdownMenuItem(value: 'tennis', child: Text('🎾 Tennis')),
                  DropdownMenuItem(value: 'other', child: Text('🕹️ Boshqa')),
                ],
                onChanged: _onTypeChanged,
              ),
              const Gap(14),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '1 soat narxi',
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: 'so\'m',
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
