// ============================================
// Arena — Sessiyani Yakunlash Modali
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/database_providers.dart';
import '../providers/tables_providers.dart';

class SessionFinishDialog extends ConsumerStatefulWidget {
  final ClubTable table;
  final Session session;

  const SessionFinishDialog({
    super.key,
    required this.table,
    required this.session,
  });

  @override
  ConsumerState<SessionFinishDialog> createState() =>
      _SessionFinishDialogState();
}

class _SessionFinishDialogState extends ConsumerState<SessionFinishDialog> {
  late final TextEditingController _amountController;
  final _notesController = TextEditingController();

  String _paymentType = 'cash'; // 'cash', 'card', 'debt'
  String? _selectedCustomerId;
  late final Duration _duration;
  late final int _calculatedAmount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _duration = now.difference(widget.session.startedAt);

    // Narxni daqiqabay hisoblash
    final totalMinutes = _duration.inMinutes > 0 ? _duration.inMinutes : 1;
    final pricePerMinute = widget.table.pricePerHour / 60.0;
    _calculatedAmount = (totalMinutes * pricePerMinute).round();

    // Summani 500 yoki 1000 so'mga yaxlitlash
    final rounded = ((_calculatedAmount + 499) ~/ 500) * 500;
    _amountController = TextEditingController(text: rounded.toString());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _onFinish() async {
    final amount = int.tryParse(_amountController.text.trim()) ?? _calculatedAmount;

    if (_paymentType == 'debt' && _selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iltimos, nasiya uchun mijozni tanlang!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(tablesControllerProvider).finishSession(
            session: widget.session,
            table: widget.table,
            finalAmount: amount,
            paymentType: _paymentType,
            customerId: _selectedCustomerId,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
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
    final db = ref.watch(appDatabaseProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                        color: AppColors.primaryGlow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.check_circle_outline,
                          color: AppColors.primary, size: 24),
                    ),
                    const Gap(14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.table.name} — Yakunlash',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Boshlandi: ${Formatters.timeOnly(widget.session.startedAt)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                const Gap(20),

                // Vaqt va hisob kartasi
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('O\'ynalgan vaqt',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12)),
                          const Gap(4),
                          Text(
                            Formatters.timerString(_duration),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 36,
                        width: 1,
                        color: AppColors.surfaceBorder,
                      ),
                      Column(
                        children: [
                          const Text('Soatlik stavka',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12)),
                          const Gap(4),
                          Text(
                            Formatters.currency(widget.table.pricePerHour),
                            style: const TextStyle(
                              color: AppColors.info,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Gap(20),

                // To'lov summasi kiritish
                const Text(
                  'To\'lov summasi (so\'m):',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Gap(8),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.payments_outlined,
                        color: AppColors.success),
                    suffixText: 'so\'m',
                    hintText: 'Summa',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const Gap(20),

                // To'lov turi tanlash
                const Text(
                  'To\'lov usuli:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Gap(10),
                Row(
                  children: [
                    _PaymentTypeOption(
                      title: 'Naqd pul',
                      icon: Icons.money,
                      color: AppColors.success,
                      isSelected: _paymentType == 'cash',
                      onTap: () => setState(() => _paymentType = 'cash'),
                    ),
                    const Gap(8),
                    _PaymentTypeOption(
                      title: 'Karta',
                      icon: Icons.credit_card,
                      color: AppColors.primary,
                      isSelected: _paymentType == 'card',
                      onTap: () => setState(() => _paymentType = 'card'),
                    ),
                    const Gap(8),
                    _PaymentTypeOption(
                      title: 'Nasiya',
                      icon: Icons.book,
                      color: AppColors.warning,
                      isSelected: _paymentType == 'debt',
                      onTap: () => setState(() => _paymentType = 'debt'),
                    ),
                  ],
                ),

                // Agar nasiya tanlansa — mijoz tanlash
                if (_paymentType == 'debt') ...[
                  const Gap(16),
                  StreamBuilder<List<Customer>>(
                    stream: db.customersDao.watchAllCustomers(),
                    builder: (context, snapshot) {
                      final customers = snapshot.data ?? [];
                      return DropdownButtonFormField<String>(
                        value: _selectedCustomerId,
                        decoration: InputDecoration(
                          labelText: 'Mijozni tanlang (Nasiya)',
                          prefixIcon: const Icon(Icons.person_outline,
                              color: AppColors.warning),
                          filled: true,
                          fillColor: AppColors.surfaceAlt,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        dropdownColor: AppColors.surfaceAlt,
                        items: customers
                            .map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(
                                    '${c.name} (${Formatters.currency(c.totalDebt)})',
                                    style: const TextStyle(
                                        color: AppColors.textPrimary),
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedCustomerId = val),
                      );
                    },
                  ),
                ],

                const Gap(16),

                // Izoh
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    hintText: 'Izoh (ixtiyoriy)',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),

                const Gap(24),

                // Tugmalar
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _isLoading ? null : _onFinish,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Hisobni yopish',
                                style: TextStyle(
                                  fontSize: 16,
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
      ),
    );
  }
}

class _PaymentTypeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentTypeOption({
    required this.title,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppColors.surfaceBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? color : AppColors.textSecondary, size: 22),
              const Gap(6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
