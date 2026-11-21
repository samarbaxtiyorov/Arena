// ============================================
// Arena — Yangi Mijoz Qo'shish Modali
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/nasiya_providers.dart';

class AddCustomerDialog extends ConsumerStatefulWidget {
  const AddCustomerDialog({super.key});

  @override
  ConsumerState<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends ConsumerState<AddCustomerDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _debtController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _debtController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iltimos, mijoz ismini kiriting!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final initialDebt = int.tryParse(_debtController.text.trim()) ?? 0;

    setState(() => _isLoading = true);

    try {
      final customer = await ref.read(nasiyaControllerProvider).addCustomer(
            name: name,
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            initialDebt: initialDebt,
          );

      if (mounted) Navigator.of(context).pop(customer);
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
                    child: const Icon(Icons.person_add_alt_1,
                        color: AppColors.primary, size: 24),
                  ),
                  const Gap(14),
                  const Text(
                    'Yangi Mijoz',
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
                  labelText: 'Ism va familiya *',
                  hintText: 'Masalan: Ruslan aka',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const Gap(14),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefon raqam',
                  hintText: '+998 90 123 45 67',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const Gap(14),
              TextField(
                controller: _debtController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Boshlang\'ich qarz (ixtiyoriy)',
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: 'so\'m',
                ),
              ),
              const Gap(14),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Izoh / Manzil',
                  hintText: 'Qo\'shimcha ma\'lumot',
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
    );
  }
}
