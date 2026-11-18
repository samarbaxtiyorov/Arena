// ============================================
// Arena — Boshqa Kirim Yozish Modali
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/kassa_providers.dart';

class AddIncomeDialog extends ConsumerStatefulWidget {
  const AddIncomeDialog({super.key});

  @override
  ConsumerState<AddIncomeDialog> createState() => _AddIncomeDialogState();
}

class _AddIncomeDialogState extends ConsumerState<AddIncomeDialog> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String _category = 'other_income';
  bool _isLoading = false;

  final _quickAmounts = [20000, 50000, 100000, 200000, 500000];

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _addQuick(int val) {
    final cur = int.tryParse(_amountController.text.trim()) ?? 0;
    _amountController.text = (cur + val).toString();
  }

  Future<void> _onSave() async {
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    final desc = _descController.text.trim();

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iltimos, to\'g\'ri kirim summasini kiriting!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iltimos, kirim sababini yozing!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(kassaControllerProvider).addIncome(
            amount: amount,
            category: _category,
            description: desc,
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
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_downward,
                        color: AppColors.success, size: 24),
                  ),
                  const Gap(14),
                  const Text(
                    'Kassaga Kirim Qilish',
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
                controller: _amountController,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
                decoration: const InputDecoration(
                  labelText: 'Kirim summasi',
                  prefixIcon: Icon(Icons.attach_money, color: AppColors.success),
                  suffixText: 'so\'m',
                ),
              ),
              const Gap(10),
              Wrap(
                spacing: 6,
                children: _quickAmounts.map((val) {
                  return ActionChip(
                    backgroundColor: AppColors.surfaceAlt,
                    side: const BorderSide(color: AppColors.surfaceBorder),
                    label: Text('+${val ~/ 1000}k',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textPrimary)),
                    onPressed: () => _addQuick(val),
                  );
                }).toList(),
              ),
              const Gap(14),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Kirim toifasi',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                dropdownColor: AppColors.surfaceAlt,
                items: const [
                  DropdownMenuItem(value: 'other_income', child: Text('💰 Boshqa tushum')),
                  DropdownMenuItem(value: 'sponsor', child: Text('🤝 Homiylik / Sarmoya')),
                  DropdownMenuItem(value: 'prepayment', child: Text('🏷️ Oldindan to\'lov (Zakalat)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const Gap(14),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Sababi / Izoh *',
                  hintText: 'Turnir badali, zakalat...',
                  prefixIcon: Icon(Icons.notes_outlined),
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
                          : const Text('Kirimni Saqlash'),
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
