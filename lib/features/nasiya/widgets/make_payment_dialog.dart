// ============================================
// Arena — Qarz To'lash / So'ndirish Modali
// Ma'lumotlar bazasiga (Debts, Customers, CashRecords) 100% to'liq yozadi
// Arxiv va Kassa bilan uzviy integratsiyalashgan
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/local/app_database.dart';
import '../../management/providers/business_settings_provider.dart';
import '../../management/widgets/customer_payment_card_view.dart';
import '../providers/nasiya_providers.dart';

class MakePaymentDialog extends ConsumerStatefulWidget {
  final Customer customer;
  final int? initialAmount;

  const MakePaymentDialog({
    super.key,
    required this.customer,
    this.initialAmount,
  });

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
    final defaultSum = widget.initialAmount ??
        (widget.customer.totalDebt > 0 ? widget.customer.totalDebt : 0);
    _amountController = TextEditingController(
      text: defaultSum > 0 ? defaultSum.toString() : '',
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
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final desc = _descController.text.trim().isEmpty
          ? "Qarz to'lovi"
          : _descController.text.trim();

      await ref.read(nasiyaControllerProvider).makePayment(
            customerId: widget.customer.id,
            amount: amount,
            paymentMethod: _paymentMethod,
            description: desc,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "${widget.customer.name} dan ${formatSum(amount)} to'lov qabul qilindi!"),
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
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
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.payments_rounded,
                        color: Color(0xFF059669), size: 24),
                  ),
                  const Gap(14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Qarz To\'lash',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          widget.customer.name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
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
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Joriy umumiy qarz:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      formatSum(widget.customer.totalDebt),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),

              const Gap(14),

              // To'lov summasi maydoni
              TextField(
                controller: _amountController,
                autofocus: true,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF059669),
                ),
                decoration: InputDecoration(
                  labelText: 'To\'lov summasi *',
                  hintText: '0',
                  suffixText: "so'm",
                  suffixStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B)),
                  prefixIcon: const Icon(Icons.attach_money,
                      color: Color(0xFF059669), size: 22),
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

              // Ortiqcha to'lov ogohlantirishi
              if ((int.tryParse(_amountController.text.trim()) ?? 0) > widget.customer.totalDebt && widget.customer.totalDebt > 0) ...[
                const Gap(8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 16),
                      const Gap(6),
                      Expanded(
                        child: Text(
                          "Diqqat: To'lov qarzdan ortiq (${formatSum((int.tryParse(_amountController.text.trim()) ?? 0) - widget.customer.totalDebt)} avans bo'lib qoladi)",
                          style: const TextStyle(fontSize: 11, color: Color(0xFFB45309), fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Gap(14),

              // To'lov usuli: Naqd yoki Karta
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _paymentMethod = 'cash'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _paymentMethod == 'cash'
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _paymentMethod == 'cash'
                                ? const Color(0xFF059669)
                                : const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payments_rounded,
                                size: 16,
                                color: _paymentMethod == 'cash'
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF64748B)),
                            const Gap(6),
                            Text(
                              "Naqd pul",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _paymentMethod == 'cash'
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _paymentMethod = 'card'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _paymentMethod == 'card'
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _paymentMethod == 'card'
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.credit_card_rounded,
                                size: 16,
                                color: _paymentMethod == 'card'
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF64748B)),
                            const Gap(6),
                            Text(
                              "Plastik karta",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _paymentMethod == 'card'
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Plastik karta tanlanganda mijozga ko'rsatiladigan to'lov kartasi
              if (_paymentMethod == 'card') ...[
                const Gap(12),
                Consumer(
                  builder: (context, ref, _) {
                    final settings = ref.watch(businessSettingsProvider);
                    return CustomerPaymentCardView(settings: settings, compact: true);
                  },
                ),
              ],

              const Gap(14),

              // Izoh
              TextField(
                controller: _descController,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Izoh (ixtiyoriy)',
                  hintText: "Qarz so'ndirildi",
                  prefixIcon: const Icon(Icons.notes_rounded,
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

              // Bekor qilish va To'lovni tasdiqlash
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
                        backgroundColor: const Color(0xFF059669),
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
                                const Icon(Icons.check_circle_outline_rounded,
                                    size: 18),
                                const Gap(6),
                                Text(
                                  _paymentMethod == 'card'
                                      ? "To'lov qabul qilindi"
                                      : 'To\'lovni Qabul Qilish',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
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
    );
  }
}
