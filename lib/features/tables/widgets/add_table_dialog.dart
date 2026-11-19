// ============================================
// Arena — Maydon / Stol Qo'shish va Tahrirlash Modali
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/local/app_database.dart';
import '../providers/tables_providers.dart';

class AddTableDialog extends ConsumerStatefulWidget {
  final ClubTable? tableToEdit;

  const AddTableDialog({super.key, this.tableToEdit});

  @override
  ConsumerState<AddTableDialog> createState() => _AddTableDialogState();
}

class _AddTableDialogState extends ConsumerState<AddTableDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late String _type;
  bool _isLoading = false;

  bool get _isEditing => widget.tableToEdit != null;

  final Map<String, int> _defaultPrices = {
    'football': AppConstants.footballPricePerHour,
    'billiard': AppConstants.billiardPricePerHour,
    'ps': AppConstants.playstationPerHour,
    'tennis': AppConstants.tennisPricePerHour,
    'other': 25000,
  };

  @override
  void initState() {
    super.initState();
    final edit = widget.tableToEdit;
    _nameController = TextEditingController(text: edit?.name ?? '');
    _type = edit?.type ?? 'football';
    _priceController = TextEditingController(
      text: edit != null
          ? edit.pricePerHour.toString()
          : (_defaultPrices[_type] ?? 100000).toString(),
    );
  }

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
      if (!_isEditing) {
        _priceController.text = (_defaultPrices[newType] ?? 25000).toString();
      }
    });
  }

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    final price = int.tryParse(_priceController.text.trim()) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iltimos, maydon yoki stol nomini kiriting!'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Soatlik narxni to\'g\'ri kiriting!'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        await ref.read(tablesControllerProvider).updateTable(
              tableId: widget.tableToEdit!.id,
              name: name,
              type: _type,
              pricePerHour: price,
            );
      } else {
        await ref.read(tablesControllerProvider).addTable(
              name: name,
              type: _type,
              pricePerHour: price,
            );
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
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
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isEditing ? Icons.edit_rounded : Icons.add_circle_outline,
                      color: const Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                  const Gap(14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? 'Maydonni Tahrirlash' : 'Yangi Maydon / Stol',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          _isEditing
                              ? widget.tableToEdit!.name
                              : 'Tizimga yangi o\'yin maydoni qo\'shish',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Gap(18),
              TextField(
                controller: _nameController,
                autofocus: !_isEditing,
                decoration: InputDecoration(
                  labelText: 'Nomi (masalan: Maydon 2, Bilyard 3)',
                  labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  prefixIcon: const Icon(Icons.drive_file_rename_outline, color: Color(0xFF2563EB)),
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
              DropdownButtonFormField<String>(
                value: _type,
                decoration: InputDecoration(
                  labelText: 'O\'yin / Sport turi',
                  labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFF2563EB)),
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
                dropdownColor: Colors.white,
                items: const [
                  DropdownMenuItem(
                    value: 'football',
                    child: Row(
                      children: [
                        Icon(Icons.sports_soccer_rounded, size: 20, color: Color(0xFF10B981)),
                        Gap(10),
                        Text('Futbol maydoni'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'billiard',
                    child: Row(
                      children: [
                        Icon(Icons.sports_baseball_outlined, size: 20, color: Color(0xFF2563EB)),
                        Gap(10),
                        Text('Bilyard stoli'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'ps',
                    child: Row(
                      children: [
                        Icon(Icons.sports_esports_rounded, size: 20, color: Color(0xFF8B5CF6)),
                        Gap(10),
                        Text('PlayStation zona'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'tennis',
                    child: Row(
                      children: [
                        Icon(Icons.sports_tennis_rounded, size: 20, color: Color(0xFFF59E0B)),
                        Gap(10),
                        Text('Stol tennisi'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Row(
                      children: [
                        Icon(Icons.games_rounded, size: 20, color: Color(0xFF64748B)),
                        Gap(10),
                        Text('Boshqa zona'),
                      ],
                    ),
                  ),
                ],
                onChanged: _onTypeChanged,
              ),
              const Gap(14),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Soatlik narxi (so\'m)',
                  labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFF10B981)),
                  suffixText: 'so\'m/soat',
                  suffixStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
              const Gap(22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Bekor qilish'),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _onSave,
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isEditing ? 'Saqlash' : 'Qo\'shish',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
