// ============================================
// Arena — Obuna va Litsenziya Sahifasi
// Har bir stol/maydon uchun 100 000 so'm/oy
// TezCheck.uz (Click, Payme, Uzum) to'lov integratsiyasi
// Litsenziya cheklovi va ruxsat berilgan stollar nazorati
// ============================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/providers/business_account_provider.dart';
import '../../../core/services/tezcheck_payment_service.dart';
import '../../../core/utils/formatters.dart';
import '../../tables/providers/tables_providers.dart';
import '../models/subscription_model.dart';
import '../providers/subscription_provider.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  int _selectedMonths = 1; // 1, 3, 6, 12
  int? _customTablesCount;
  bool _isCreatingBill = false;

  @override
  Widget build(BuildContext context) {
    final sub = ref.watch(subscriptionProvider);
    final businessState = ref.watch(businessAccountProvider);
    final activeVenue = businessState.activeAccount;

    // Hozirgi mavjud stollar soni
    final tablesAsync = ref.watch(tablesStreamProvider);
    final existingTablesCount = tablesAsync.value?.length ?? 1;
    final minTables = existingTablesCount > 0 ? existingTablesCount : 1;

    // Litsenziyalanayotgan stollar soni (mavjud stollardan kam bo'lolmaydi)
    final selectedTables = _customTablesCount ??
        (sub.licensedTablesCount > minTables ? sub.licensedTablesCount : minTables);

    // Tanlangan muddat narxi
    final finalCost = SubscriptionNotifier.calculateAmount(
      tablesCount: selectedTables,
      months: _selectedMonths,
    );

    final dateFormat = DateFormat('dd.MM.yyyy');
    final expiryStr = dateFormat.format(sub.expiryDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Obuna va Litsenziya",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Hozirgi Litsenziya Holati Kartasi ──────────
            _buildCurrentStatusCard(sub, expiryStr, minTables),

            const Gap(16),

            // ── 2. Stollar Soni Nazorati va Tarif Formulari ───
            _buildTablesSelectorCard(minTables, selectedTables),

            const Gap(20),

            // ── 3. Muddatni Tanlash Kartalari (1, 3, 6, 12 oy) 
            const Text(
              "LITSENZIYA MUDDATINI TANLANG:",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const Gap(10),

            _buildPlanOption(
              months: 1,
              title: "1 Oylik Standart",
              tablesCount: selectedTables,
              discountText: null,
              isBest: false,
            ),
            const Gap(10),
            _buildPlanOption(
              months: 3,
              title: "3 Oylik Reja",
              tablesCount: selectedTables,
              discountText: "5% CHEGIRMA",
              isBest: false,
            ),
            const Gap(10),
            _buildPlanOption(
              months: 6,
              title: "6 Oylik Mavsumiy",
              tablesCount: selectedTables,
              discountText: "10% CHEGIRMA",
              isBest: false,
            ),
            const Gap(10),
            _buildPlanOption(
              months: 12,
              title: "1 Yillik VIP Obuna",
              tablesCount: selectedTables,
              discountText: "20% SUPER CHEGIRMA",
              isBest: true,
            ),

            const Gap(20),

            // ── 4. To'lov Tizimi (TezCheck.uz) Rekviziti ──────
            _buildTezCheckInfoCard(),

            const Gap(24),

            // ── 5. To'lash Tugmasi ────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreatingBill
                    ? null
                    : () => _initiatePayment(
                          amountSom: finalCost,
                          months: _selectedMonths,
                          tablesToLicense: selectedTables,
                          venueName: activeVenue?.venueName ?? 'Arena Majmuasi',
                          venueId: activeVenue?.id ?? 'default',
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isCreatingBill
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          Gap(12),
                          Text("To'lov havolasi ochilmoqda...", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.payment_rounded, size: 20),
                          const Gap(10),
                          Text(
                            "To'lash: ${formatSum(finalCost)}",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
              ),
            ),

            const Gap(24),
          ],
        ),
      ),
    );
  }

  // ── 1. Hozirgi Litsenziya Holati ───────────────────────────
  Widget _buildCurrentStatusCard(
      SubscriptionModel sub, String expiryStr, int existingTables) {
    final isExpired = sub.isExpired;
    final days = sub.daysRemaining;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExpired
              ? [const Color(0xFF7F1D1D), const Color(0xFF991B1B), const Color(0xFFDC2626)]
              : [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.verified_rounded, color: Color(0xFFFBBF24), size: 20),
                  ),
                  const Gap(10),
                  const Text(
                    "ARENA POS LITSENZIYASI",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isExpired
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981).withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isExpired ? Colors.white70 : const Color(0xFF34D399),
                  ),
                ),
                child: Text(
                  isExpired ? "MUDDATI O'TGAN" : "FAOL",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const Gap(18),
          Text(
            isExpired ? "Litsenziya muddati tugagan" : "$days kun qoldi",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Gap(4),
          Text(
            "Amal qilish muddati: $expiryStr gacha",
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(16),
          const Divider(color: Colors.white24, height: 1),
          const Gap(14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Litsenziyada ruxsat: ${sub.licensedTablesCount} ta stol",
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Text(
                "Hozir mavjud: $existingTables ta",
                style: const TextStyle(
                  color: Color(0xFF67E8F9),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 2. Stollar Soni Nazorati va Tarif Formulari ───
  Widget _buildTablesSelectorCard(int minTables, int selectedTables) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Litsenziyalanadigan Stollar Soni:",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  Gap(2),
                  Text(
                    "Har bir stol uchun 100 000 so'm/oy",
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              // Counter: [ - ] 5 ta [ + ]
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_rounded, size: 18),
                      onPressed: selectedTables > minTables
                          ? () {
                              setState(() {
                                _customTablesCount = selectedTables - 1;
                              });
                            }
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        "$selectedTables ta",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF2563EB)),
                      onPressed: () {
                        setState(() {
                          _customTablesCount = selectedTables + 1;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF2563EB)),
                const Gap(6),
                Expanded(
                  child: Text(
                    "Sizda hozir $minTables ta stol bor. Dasturda faqat to'langan $selectedTables tagacha stol ishlaydi.",
                    style: const TextStyle(fontSize: 11, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Tarif Rejalari Kartasi (Overlap bug 100% tuzatildi) ──
  Widget _buildPlanOption({
    required int months,
    required String title,
    required int tablesCount,
    required String? discountText,
    required bool isBest,
  }) {
    final isSelected = _selectedMonths == months;
    final cost = SubscriptionNotifier.calculateAmount(tablesCount: tablesCount, months: months);
    final regularCost = tablesCount * 100000 * months;
    final saved = regularCost - cost;

    return InkWell(
      onTap: () => setState(() => _selectedMonths = months),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
              size: 22,
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF0F172A),
                    ),
                  ),
                  const Gap(4),
                  if (discountText != null) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isBest ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            discountText,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isBest ? const Color(0xFFB45309) : const Color(0xFF047857),
                            ),
                          ),
                        ),
                        if (saved > 0) ...[
                          const Gap(6),
                          Expanded(
                            child: Text(
                              "Tejash: ${formatSum(saved)}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ] else ...[
                    Text(
                      "$months oylik to'liq litsenziya",
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ],
              ),
            ),
            const Gap(8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatSum(cost),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
                  ),
                ),
                if (saved > 0)
                  Text(
                    formatSum(regularCost),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 4. TezCheck To'lov Tizimi Rekviziti ─────────────────────
  Widget _buildTezCheckInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 24),
          ),
          const Gap(12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TezCheck.uz Rasmiy To'lov Tizimi",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                Gap(2),
                Text(
                  "Click, Payme, Uzum Bank va xalqaro kartalar orqali xavfsiz qabul qilinadi.",
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. To'lovni Boshlash va Modal Chiqarish ────────────────
  Future<void> _initiatePayment({
    required int amountSom,
    required int months,
    required int tablesToLicense,
    required String venueName,
    required String venueId,
  }) async {
    setState(() => _isCreatingBill = true);

    try {
      final paymentService = ref.read(tezCheckPaymentServiceProvider);
      final orderRef = 'arena-sub-$venueId-${DateTime.now().millisecondsSinceEpoch}';
      final title = "Arena POS $months oy / $tablesToLicense ta stol ($venueName)";

      final result = await paymentService.createSubscriptionBill(
        amountSom: amountSom,
        title: title,
        externalReference: orderRef,
      );

      if (!mounted) return;

      if (result != null) {
        _showPaymentModal(
          result: result,
          months: months,
          amountSom: amountSom,
          tablesToLicense: tablesToLicense,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("TezCheck serveri bilan bog'lanib bo'lmadi. Internetni tekshiring!"),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Xatolik: $e"),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingBill = false);
      }
    }
  }

  void _showPaymentModal({
    required TezCheckBillResult result,
    required int months,
    required int amountSom,
    required int tablesToLicense,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TezCheckPaymentModal(
        result: result,
        months: months,
        amountSom: amountSom,
        tablesToLicense: tablesToLicense,
        onSuccess: () {
          Navigator.pop(ctx);
          setState(() {});
        },
      ),
    );
  }
}

// ── To'lov Oynasi Modali ─────────────────────────────────────
class _TezCheckPaymentModal extends ConsumerStatefulWidget {
  final TezCheckBillResult result;
  final int months;
  final int amountSom;
  final int tablesToLicense;
  final VoidCallback onSuccess;

  const _TezCheckPaymentModal({
    required this.result,
    required this.months,
    required this.amountSom,
    required this.tablesToLicense,
    required this.onSuccess,
  });

  @override
  ConsumerState<_TezCheckPaymentModal> createState() => _TezCheckPaymentModalState();
}

class _TezCheckPaymentModalState extends ConsumerState<_TezCheckPaymentModal> {
  bool _isChecking = false;
  Timer? _autoCheckTimer;

  @override
  void initState() {
    super.initState();
    // Har 5 soniyada to'lovni avtomatik tekshirish
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkStatus(showSnack: false);
    });
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus({bool showSnack = true}) async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    try {
      final paymentService = ref.read(tezCheckPaymentServiceProvider);
      final status = await paymentService.checkBillStatus(widget.result.billId);

      if (!mounted) return;

      if (status.isPaid) {
        _autoCheckTimer?.cancel();

        // Litsenziyani uzaytirish va ruxsat berilgan stollar sonini qayd etish!
        await ref.read(subscriptionProvider.notifier).extendSubscription(
              months: widget.months,
              paidAmount: widget.amountSom,
              reference: widget.result.reference,
              licensedTablesCount: widget.tablesToLicense,
            );

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (c) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
                  Gap(10),
                  Text("To'lov Tasdiqlandi!", style: TextStyle(fontWeight: FontWeight.w900)),
                ],
              ),
              content: Text(
                "Tabriklaymiz! Sizning Arena POS litsenziyangiz ${widget.months} oyga (${widget.tablesToLicense} ta stol uchun) muvaffaqiyatli uzaytirildi. Barcha modullar cheklovlarsiz ishlaydi.",
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(c);
                    widget.onSuccess();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Ajoyib"),
                ),
              ],
            ),
          );
        }
      } else if (showSnack) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("To'lov hali amalga oshirilmagan (Holati: ${status.state})"),
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _openPaymentUrl() async {
    final rawUrl = widget.result.paymentUrl.trim();
    debugPrint("🌐 [TezCheck] Ochilayotgan havola: $rawUrl");
    final uri = Uri.parse(rawUrl);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint("❌ [TezCheck] Brauzer xatosi: $e");
      // Agar brauzer ochilmasa, havolani darhol clipboardga nusxalab beramiz va xabar qilamiz
      Clipboard.setData(ClipboardData(text: rawUrl));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("To'lov havolasi nusxalandi! Iltimos, brauzerda oching."),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "TezCheck To'lov Oynasi",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.result.reference,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
          const Gap(16),

          // Summa va Stollar soni bloki
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${widget.tablesToLicense} ta stol uchun to'lov:",
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const Gap(2),
                    Text(
                      formatSum(widget.amountSom),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${widget.months} oylik",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
                  ),
                ),
              ],
            ),
          ),

          const Gap(18),

          // Katta to'lash tugmasi (Click / Payme / Uzum)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openPaymentUrl,
              icon: const Icon(Icons.open_in_browser_rounded, size: 20),
              label: const Text(
                "Click / Payme / Uzum orqali To'lash",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          const Gap(10),

          // Havolani nusxa olish
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.result.paymentUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("To'lov havolasi nusxalandi!"),
                    duration: Duration(seconds: 2),
                    backgroundColor: Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text("To'lov havolasini nusxalash", style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF475569),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const Gap(14),

          // To'lovni tekshirish tugmasi
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _isChecking ? null : () => _checkStatus(showSnack: true),
              icon: _isChecking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                _isChecking ? "Tekshirilmoqda..." : "To'lovni Tekshirish (Tasdiqlash)",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
              ),
            ),
          ),

          const Gap(10),
        ],
      ),
    );
  }
}
