// ============================================
// Arena — To'lov Qabul Qilish (Qarz Yopish) Modali
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/local/app_database.dart';
import '../providers/nasiya_providers.dart';

class MakePaymentDialog extends ConsumerStatefulWidget {
  final Customer customer;

  const MakePaymentDialog({super.key, required this.customer});

  @override
  ConsumerState<MakePaymentDialog> createState() => _MakePaymentDialogState();
}

class _MakePaymentDialogState extends ConsumerState<MakePaymentDialog> {
  late final TextEditingController _amountController;
  final _descController = TextEditingController();
  String _paymentMethod = 'cash'; // 'cash', 'card'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Standart holatda to'liq qarz summasini taklif qiladi
    _amountController = TextEditingController(
      text: widget.customer.totalDebt > 0
          ? widget.customer.totalDebt.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iltimos, to\'g\'ri to\'lov summasini kiriting!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(nasiyaControllerProvider).makePayment(
            customerId: widget.customer.id,
            amount: amount,
            paymentMethod: _paymentMethod,
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
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.payments_outlined,
                        color: AppColors.success, size: 24),
                  ),
                  const Gap(14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'To\'lov Qabul Qilish',
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
              const Gap(16),

              // Joriy qarz ko'rsatkichi
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
                    const Text('Joriy umumiy qarz:',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    Text(
                      Formatters.currency(widget.customer.totalDebt),
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              const Gap(16),

              // To'lov summasi kiritish
              TextField(
                controller: _amountController,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
                decoration: InputDecoration(
                  labelText: 'To\'lov summasi',
                  prefixIcon:
                      const Icon(Icons.attach_money, color: AppColors.success),
                  suffixText: 'so\'m',
                  suffixIcon: widget.customer.totalDebt > 0
                      ? TextButton(
                          onPressed: () {
                            _amountController.text =
                                widget.customer.totalDebt.toString();
                          },
                          child: const Text('Barchasi'),
                        )
                      : null,
                ),
              ),

              const Gap(14),

              // To'lov usuli
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('💵 Naqd pul')),
                      selected: _paymentMethod == 'cash',
                      selectedColor: AppColors.success.withOpacity(0.2),
                      side: BorderSide(
                        color: _paymentMethod == 'cash'
                            ? AppColors.success
                            : AppColors.surfaceBorder,
                      ),
                      onSelected: (_) => setState(() => _paymentMethod = 'cash'),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('💳 Karta')),
                      selected: _paymentMethod == 'card',
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      side: BorderSide(
                        color: _paymentMethod == 'card'
                            ? AppColors.primary
                            : AppColors.surfaceBorder,
                      ),
                      onSelected: (_) => setState(() => _paymentMethod = 'card'),
                    ),
                  ),
                ],
              ),

              const Gap(14),

              TextField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Izoh (ixtiyoriy)',
                  hintText: 'Qarz yopildi',
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
                          : const Text('To\'lovni Qabul Qilish'),
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
