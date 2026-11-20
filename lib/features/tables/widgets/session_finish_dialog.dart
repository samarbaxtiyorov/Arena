// ============================================
// Arena — Sessiyani Yakunlash va To'lov Modali
// Zamonaviy POS chek ko'rinishi, daqiqabay vaqt,
// Bar mahsulotlarini 100% to'g'ri hisoblash
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/session_billing_helper.dart';
import '../../../core/utils/receipt_generator.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/database_providers.dart';
import '../../kassa/widgets/receipt_preview_dialog.dart';
import '../../management/providers/business_settings_provider.dart';
import '../../management/widgets/customer_payment_card_view.dart';
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
  String? _selectedCustomerName;
  late final Duration _duration;
  late final int _gameAmount;
  late final int _barAmount;
  late final int _exactTotal;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _duration = now.difference(widget.session.startedAt);

    // 1. O'yin summasini hisoblash (boshlang'ich kamida 1 000 so'm)
    _gameAmount = SessionBillingHelper.calculateGameAmount(
      startedAt: widget.session.startedAt,
      endedAt: now,
      pricePerHour: widget.table.pricePerHour,
    );

    // 2. Bar buyurtmalarini hisoblash
    _barAmount = SessionBillingHelper.getBarTotal(widget.session.notes);

    // 3. Jami hisob
    _exactTotal = _gameAmount + _barAmount;

    // 500 so'mga chiroyli yaxlitlangan standart to'lov
    final roundedTotal = ((_exactTotal + 499) ~/ 500) * 500;
    _amountController = TextEditingController(text: roundedTotal.toString());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _setAmount(int amount) {
    setState(() {
      _amountController.text = amount.toString();
    });
  }

  void _showReceiptPreview() {
    final amount =
        int.tryParse(_amountController.text.trim()) ?? _exactTotal;
    final finalNotes = SessionBillingHelper.finalizeNotes(
      originalNotes: widget.session.notes,
      extraUserNote: _notesController.text.trim(),
    );
    final receiptText = ReceiptGenerator.forTableSession(
      table: widget.table,
      session: widget.session,
      finalAmount: amount,
      paymentType: _paymentType,
      customerName: _selectedCustomerName,
      customNotes: finalNotes,
    );
    showDialog(
      context: context,
      builder: (_) => ReceiptPreviewDialog(receiptText: receiptText),
    );
  }

  Future<void> _onFinish() async {
    final amount =
        int.tryParse(_amountController.text.trim()) ?? _exactTotal;

    if (_paymentType == 'debt' && _selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iltimos, nasiyaga yozish uchun mijozni tanlang!'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final finalNotes = SessionBillingHelper.finalizeNotes(
        originalNotes: widget.session.notes,
        extraUserNote: _notesController.text.trim(),
      );

      await ref.read(tablesControllerProvider).finishSession(
            session: widget.session,
            table: widget.table,
            finalAmount: amount,
            paymentType: _paymentType,
            customerId: _selectedCustomerId,
            notes: finalNotes.isEmpty ? null : finalNotes,
          );

      final receiptText = ReceiptGenerator.forTableSession(
        table: widget.table,
        session: widget.session,
        finalAmount: amount,
        paymentType: _paymentType,
        customerName: _selectedCustomerName,
        customNotes: finalNotes,
      );

      if (mounted) {
        Navigator.of(context).pop(receiptText);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const Gap(8),
                Expanded(
                  child: Text(
                    "${widget.table.name} to'lovi qabul qilindi: ${formatSum(amount)}!",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik yuz berdi: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) {
      return "$h soat $m daq $s sek";
    }
    return "$m daqiqa $s soniya";
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(appDatabaseProvider);
    final barItems =
        SessionBillingHelper.getBarItemsSummary(widget.session.notes);
    final splits =
        SessionBillingHelper.getSplits(widget.session.notes);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Sarlavha Qatori ────────────────────────
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${widget.table.name} — Hisobni Yakunlash",
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const Gap(2),
                        Text(
                          "Boshlandi: ${Formatters.timeOnly(widget.session.startedAt)} • ${_formatDuration(_duration)}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: _showReceiptPreview,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              size: 16, color: Color(0xFF2563EB)),
                          Gap(4),
                          Text(
                            "Chekni olish",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Gap(4),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const Gap(16),

              // ── 2. Chek / Hisob-Kitob Tafsilotlari ─────────
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    // O'yin vaqti qatori
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const Gap(10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "O'yin vaqti to'lovi",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                "${widget.table.pricePerHour ~/ 1000} ming/soat • ${_formatDuration(_duration)}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatSum(_gameAmount),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),

                    // Bar buyurtmalari (agar mavjud bo'lsa)
                    if (_barAmount > 0) ...[
                      const Gap(10),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const Gap(10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.local_cafe_rounded,
                              size: 16,
                              color: Color(0xFFD97706),
                            ),
                          ),
                          const Gap(10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      "Bardan buyurtmalar",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const Gap(6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        "${barItems.length} xil",
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFD97706),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Gap(4),
                                Text(
                                  barItems.join(', '),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "+${formatSum(_barAmount)}",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Partiyalar / O'yinchilar bo'yicha taqsimot
                    if (splits.isNotEmpty) ...[
                      const Gap(10),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const Gap(10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.call_split_rounded,
                                  size: 14,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                              const Gap(8),
                              const Text(
                                "O'yinchilar bo'yicha hisob:",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const Gap(6),
                          ...splits.map((s) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "• ${s.name}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                    Text(
                                      formatSum(s.amount),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ],

                    const Gap(12),
                    const Divider(height: 1, color: Color(0xFFCBD5E1)),
                    const Gap(10),

                    // Jami aniq hisob
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Haqiqiy jami hisob:",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          formatSum(_exactTotal),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Gap(16),

              // ── 3. To'lov Summasi (Tahrirlanadigan) ────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "To'lov summasi:",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  InkWell(
                    onTap: () => _setAmount(_exactTotal),
                    child: const Text(
                      "Asl holatga qaytarish",
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF10B981),
                  letterSpacing: 0.5,
                ),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.payments_rounded,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                  suffixText: "so'm",
                  suffixStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),

              const Gap(10),

              // Tezkor chegirma / yaxlitlash tugmalari
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _QuickAmountChip(
                      label: "Aniq: ${formatSum(_exactTotal)}",
                      onTap: () => _setAmount(_exactTotal),
                    ),
                    const Gap(6),
                    _QuickAmountChip(
                      label:
                          "Yaxlit: ${formatSum(((_exactTotal + 499) ~/ 500) * 500)}",
                      onTap: () =>
                          _setAmount(((_exactTotal + 499) ~/ 500) * 500),
                    ),
                    if (_exactTotal >= 10000) ...[
                      const Gap(6),
                      _QuickAmountChip(
                        label: "-5 000 chegirma",
                        onTap: () => _setAmount(_exactTotal - 5000),
                      ),
                    ],
                    if (_exactTotal >= 20000) ...[
                      const Gap(6),
                      _QuickAmountChip(
                        label: "-10 000 chegirma",
                        onTap: () => _setAmount(_exactTotal - 10000),
                      ),
                    ],
                  ],
                ),
              ),

              const Gap(16),

              // ── 4. To'lov Usuli ───────────────────────────
              const Text(
                "To'lov turi:",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Gap(8),
              Row(
                children: [
                  _ModernPaymentOption(
                    title: "Naqd pul",
                    icon: Icons.payments_outlined,
                    color: const Color(0xFF10B981),
                    isSelected: _paymentType == 'cash',
                    onTap: () => setState(() => _paymentType = 'cash'),
                  ),
                  const Gap(8),
                  _ModernPaymentOption(
                    title: "Karta",
                    icon: Icons.credit_card_rounded,
                    color: const Color(0xFF2563EB),
                    isSelected: _paymentType == 'card',
                    onTap: () => setState(() => _paymentType = 'card'),
                  ),
                  const Gap(8),
                  _ModernPaymentOption(
                    title: "Nasiyaga",
                    icon: Icons.book_outlined,
                    color: const Color(0xFFD97706),
                    isSelected: _paymentType == 'debt',
                    onTap: () => setState(() => _paymentType = 'debt'),
                  ),
                ],
              ),

              // Agar karta tanlansa: Mijozga ko'rsatiladigan to'lov kartasi
              if (_paymentType == 'card') ...[
                const Gap(14),
                Consumer(
                  builder: (context, ref, _) {
                    final settings = ref.watch(businessSettingsProvider);
                    return CustomerPaymentCardView(settings: settings, compact: true);
                  },
                ),
              ],

              // Agar nasiya tanlansa: Mijoz tanlash
              if (_paymentType == 'debt') ...[
                const Gap(14),
                StreamBuilder<List<Customer>>(
                  stream: db.customersDao.watchAllCustomers(),
                  builder: (context, snapshot) {
                    final customers = snapshot.data ?? [];
                    return DropdownButtonFormField<String>(
                      value: _selectedCustomerId,
                      decoration: InputDecoration(
                        labelText: 'Nasiya egasi (Mijozni tanlang)',
                        labelStyle: const TextStyle(
                            fontSize: 13, color: Color(0xFFD97706)),
                        prefixIcon: const Icon(Icons.person_rounded,
                            color: Color(0xFFD97706)),
                        filled: true,
                        fillColor: const Color(0xFFFFFBEB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFFDE68A)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFFDE68A)),
                        ),
                      ),
                      dropdownColor: Colors.white,
                      items: customers
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(
                                  '${c.name} (${c.totalDebt > 0 ? "Qarzi: ${formatSum(c.totalDebt)}" : "Qarzi yo'q"})',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCustomerId = val;
                          final match = customers
                              .where((c) => c.id == val)
                              .firstOrNull;
                          _selectedCustomerName = match?.name;
                        });
                      },
                    );
                  },
                ),
              ],

              const Gap(14),

              // Izoh maydoni
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: "Qo'shimcha izoh (ixtiyoriy)",
                  hintStyle:
                      const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.edit_note_rounded,
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),

              const Gap(20),

              // ── 5. Tasdiqlash Tugmalari ───────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      child: const Text(
                        'Bekor qilish',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _onFinish,
                      icon: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_rounded, size: 20),
                      label: Text(
                        _isLoading
                            ? "Saqlanmoqda..."
                            : (_paymentType == 'card'
                                ? "To'lov qabul qilindi"
                                : "To'lovni tasdiqlash"),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
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

class _QuickAmountChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickAmountChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

class _ModernPaymentOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModernPaymentOption({
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
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? color : const Color(0xFF64748B),
                size: 22,
              ),
              const Gap(6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? color : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
