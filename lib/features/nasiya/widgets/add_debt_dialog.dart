// ============================================
// Arena — Qarz Yozish Modali (Super Mukammal)
// Mavjud mijozni tanlash yoki yangi mijozga qarz yozish
// Ma'lumotlar bazasiga (Debts, Customers) 100% ishonchli yozadi
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/database_providers.dart';
import '../providers/nasiya_providers.dart';
import 'add_customer_dialog.dart';

class AddDebtDialog extends ConsumerStatefulWidget {
  final Customer? customer;

  const AddDebtDialog({super.key, this.customer});

  @override
  ConsumerState<AddDebtDialog> createState() => _AddDebtDialogState();
}

class _AddDebtDialogState extends ConsumerState<AddDebtDialog> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController(text: "Qo'lda kiritilgan qarz");
  String? _selectedCustomerId;
  bool _isLoading = false;

  final _quickAmounts = [50000, 100000, 200000, 500000, 1000000];

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _selectedCustomerId = widget.customer!.id;
    }
  }

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
    final customerId = _selectedCustomerId ?? widget.customer?.id;

    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iltimos, qarzdor mijozni tanlang!'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iltimos, to\'g\'ri qarz summasini kiriting!'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final desc = _descController.text.trim().isEmpty
          ? "Qo'lda kiritilgan qarz"
          : _descController.text.trim();

      await ref.read(nasiyaControllerProvider).addDebt(
            customerId: customerId,
            amount: amount,
            description: desc,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${formatSum(amount)} qarz muvaffaqiyatli yozildi!"),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(appDatabaseProvider);
    final isPreSelected = widget.customer != null;

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
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.note_add_rounded,
                          color: Color(0xFFEF4444), size: 24),
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
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            isPreSelected
                                ? widget.customer!.name
                                : 'Mijozni tanlang va qarz summasini kiriting',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Gap(18),

                // Agar mijoz tanlanmagan bo'lsa - Mijoz tanlash yoki yangi qo'shish
                if (!isPreSelected) ...[
                  StreamBuilder<List<Customer>>(
                    stream: db.customersDao.watchAllCustomers(),
                    builder: (context, snapshot) {
                      final customers = snapshot.data ?? [];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: const Text(
                              'Qarzdor mijozni tanlang *',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B)),
                            ),
                            value: _selectedCustomerId,
                            items: customers.map((c) {
                              final tel = (c.phone != null && c.phone!.isNotEmpty)
                                  ? " • ${c.phone}"
                                  : "";
                              return DropdownMenuItem(
                                value: c.id,
                                child: Text(
                                  "${c.name}$tel",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() => _selectedCustomerId = val);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const Gap(6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        final created = await showDialog<bool>(
                          context: context,
                          builder: (_) => const AddCustomerDialog(),
                        );
                        if (created == true && mounted) {
                          // Yangi qo'shilgan mijozni yangilash
                        }
                      },
                      icon: const Icon(Icons.person_add_alt_1, size: 16),
                      label: const Text(
                        "+ Yangi mijoz qo'shish",
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                      ),
                    ),
                  ),
                  const Gap(10),
                ],

                // Qarz Summasi maydoni
                TextField(
                  controller: _amountController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFDC2626),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Qarz summasi *',
                    hintText: '0',
                    suffixText: "so'm",
                    suffixStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B)),
                    prefixIcon: const Icon(Icons.payments_outlined,
                        color: Color(0xFFDC2626), size: 22),
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

                const Gap(10),

                // Tezkor sum qo'shish chiplari
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _quickAmounts.map((val) {
                    final label = val >= 1000000
                        ? "+${val ~/ 1000000} mln"
                        : "+${val ~/ 1000}k";
                    return ActionChip(
                      label: Text(label),
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC2626),
                      ),
                      backgroundColor: const Color(0xFFFEF2F2),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      onPressed: () => _addQuickAmount(val),
                    );
                  }).toList(),
                ),

                const Gap(14),

                // Qarz Sababi / Izoh
                TextField(
                  controller: _descController,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    labelText: 'Qarz sababi / Izoh',
                    hintText: "Futbol, Bilyard, Do'kon yoki qo'lda qarz",
                    prefixIcon: const Icon(Icons.description_outlined,
                        color: Color(0xFF64748B), size: 20),
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
                        child: const Text('Bekor qilish',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
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
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_rounded, size: 18),
                                  Gap(6),
                                  Text(
                                    'Qarzni Saqlash',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
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
