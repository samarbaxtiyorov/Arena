// ============================================
// Arena — Qarz Qo'shish Modali
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/local/app_database.dart';
import '../providers/nasiya_providers.dart';

class AddDebtDialog extends ConsumerStatefulWidget {
  final Customer customer;

  const AddDebtDialog({super.key, required this.customer});

  @override
  ConsumerState<AddDebtDialog> createState() => _AddDebtDialogState();
}

class _AddDebtDialogState extends ConsumerState<AddDebtDialog> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;

  final _quickAmounts = [10000, 20000, 50000, 100000, 200000];

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _addQuickAmount(int val) {
    final current = int.tryParse(_amountController.text.trim()) ?? 0;
    _amountController.text = (current + val).toString();
  }

  Future<void> _onSave() async {
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iltimos, to\'g\'ri qarz summasini kiriting!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(nasiyaControllerProvider).addDebt(
            customerId: widget.customer.id,
            amount: amount,
            description: _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
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
                      color: AppColors.danger.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long,
                        color: AppColors.danger, size: 24),
                  ),
                  const Gap(14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Qarz Yozish',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.customer.name,
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
              const Gap(20),
              TextField(
                controller: _amountController,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.danger,
                ),
                decoration: const InputDecoration(
                  labelText: 'Qarz summasi',
                  prefixIcon: Icon(Icons.attach_money, color: AppColors.danger),
                  suffixText: 'so\'m',
                ),
              ),
              const Gap(10),
              // Tezkor sum qo'shish chiplari
              Wrap(
                spacing: 6,
                children: _quickAmounts.map((val) {
                  return ActionChip(
                    backgroundColor: AppColors.surfaceAlt,
                    side: const BorderSide(color: AppColors.surfaceBorder),
                    label: Text('+${val ~/ 1000}k',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textPrimary)),
                    onPressed: () => _addQuickAmount(val),
                  );
                }).toList(),
              ),
              const Gap(14),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Sabab / Izoh',
                  hintText: 'Masalan: Bilyard 2 soat, kola',
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
                        backgroundColor: AppColors.danger,
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
                          : const Text('Qarzni Saqlash'),
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
