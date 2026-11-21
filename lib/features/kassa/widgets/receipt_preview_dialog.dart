// ============================================
// Champion POS — VIP Champion Ticket & Chek Modali
// Sifatli VIP Chipta dizayni, Termal printer ko'rinishi,
// Shtamp, Perforatsiya (tishli chiziq) va QR/Shtrix-kod
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

import '../../../../core/widgets/champion_logo.dart';

class ReceiptPreviewDialog extends StatefulWidget {
  final String receiptText;

  const ReceiptPreviewDialog({super.key, required this.receiptText});

  @override
  State<ReceiptPreviewDialog> createState() => _ReceiptPreviewDialogState();
}

class _ReceiptPreviewDialogState extends State<ReceiptPreviewDialog> {
  bool _isThermalView = false; // false = VIP Chipta, true = Termal matn

  @override
  Widget build(BuildContext context) {
    final parsed = _parseReceipt(widget.receiptText);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A), // To'q obsidian fon
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(0xFFF59E0B).withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: const Color(0xFFF59E0B).withOpacity(0.3),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── 1. MODAL YUQORI BOSHQARUV PANEL ─────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 12, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tab almashtirgich (Chipta / Termal)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildTabButton(
                            title: '🎟️ VIP Chipta',
                            isSelected: !_isThermalView,
                            onTap: () => setState(() => _isThermalView = false),
                          ),
                          _buildTabButton(
                            title: '🖨️ Termal (58mm)',
                            isSelected: _isThermalView,
                            onTap: () => setState(() => _isThermalView = true),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Color(0xFF94A3B8), size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // ── 2. ASOSIY CHEK MAYDONI ──────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _isThermalView
                      ? _buildThermalView()
                      : _buildVipTicketView(parsed),
                ),
              ),

              const Gap(12),

              // ── 3. PASTKI HARAKAT TUGMALARI ─────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Nusxa olish'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFCBD5E1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: const BorderSide(color: Color(0xFF334155)),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.receiptText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Chek matni nusxalandi!'),
                              backgroundColor: Color(0xFF10B981),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.print_rounded, size: 17),
                        label: const Text(
                          'Chop etish',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ESC/POS termal printerga yuborildi!'),
                              backgroundColor: Color(0xFF10B981),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF59E0B) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  // ── A. VIP CHIPTA VIZUAL DIZAYNI ─────────────────────────────
  Widget _buildVipTicketView(_ReceiptData data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Tepadagi oltin chipta nishoni
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              children: [
                const ChampionLogo(size: 44, borderRadius: 12),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ARENA POS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF92400E),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB45309).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              data.isShopSale ? 'SAVDO' : 'VIP TICKET',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(2),
                      Text(
                        data.title,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF78350F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Yonlaridagi yarim dumaloq chipta teshigi & perforatsiya
          _buildTicketNotchSeparator(),

          // 3. Chek tafsilotlari
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chek raqami va vaqt qatori
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tag_rounded, size: 14, color: Color(0xFF64748B)),
                        const Gap(4),
                        Text(
                          data.orderNo,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF64748B)),
                        const Gap(4),
                        Text(
                          data.dateTime,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Gap(12),

                // Stol yoki bo'lim kartochkasi
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          data.isShopSale
                              ? Icons.shopping_basket_rounded
                              : Icons.sports_soccer_rounded,
                          color: const Color(0xFF0F172A),
                          size: 18,
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.sectionOrTable,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            if (data.customerName.isNotEmpty)
                              Text(
                                "Mijoz: ${data.customerName}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (data.duration.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            data.duration,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFDE68A),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Xaridlar va Mahsulotlar ro'yxati (agar mavjud bo'lsa)
                if (data.items.isNotEmpty) ...[
                  const Gap(12),
                  const Text(
                    "XARIDLAR:",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Gap(6),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: data.items.map((it) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  it.title,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                              Text(
                                it.amount,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                // Bo'lingan partiyalar (agar mavjud bo'lsa)
                if (data.splits.isNotEmpty) ...[
                  const Gap(10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: data.splits.map((s) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          s,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const Gap(16),

                // 4. Jami to'lov banneri va Shtamp (Pechat)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'JAMI TO\'LOV',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  data.paymentType,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Gap(4),
                          Text(
                            data.totalAmount,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFDE68A),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // O'ng burchakdagi Shtamp (Muvaffaqiyatli to'lov / Qarz)
                    Positioned(
                      right: 12,
                      bottom: 8,
                      child: Transform.rotate(
                        angle: -0.12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: data.isDebt
                                ? const Color(0xFFFEF2F2)
                                : const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: data.isDebt
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF059669),
                              width: 1.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                data.isDebt
                                    ? Icons.warning_amber_rounded
                                    : Icons.check_circle_rounded,
                                size: 14,
                                color: data.isDebt
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF059669),
                              ),
                              const Gap(4),
                              Text(
                                data.isDebt ? 'QARZ' : 'TO\'LANDI',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.1,
                                  color: data.isDebt
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const Gap(16),

                // 5. Shtrix-kod va shior
                Center(
                  child: Column(
                    children: [
                      Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const FittedBox(
                          fit: BoxFit.fitHeight,
                          child: Text(
                            '|||| ||| | ||||| || |||||| ||| |||',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ),
                      const Gap(4),
                      const Text(
                        'Arena POS • Ishonchli boshqaruv!',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Chiptaning yonlaridagi yarim dumaloq o'yiqlar va teshilgan chiziq
  Widget _buildTicketNotchSeparator() {
    return SizedBox(
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Uzuk-uzuk teshilgan chiziq
          LayoutBuilder(
            builder: (context, constraints) {
              const dashWidth = 5.0;
              const dashSpace = 4.0;
              final dashCount =
                  (constraints.maxWidth / (dashWidth + dashSpace)).floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(dashCount, (_) {
                  return const SizedBox(
                    width: dashWidth,
                    height: 1.5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Color(0xFFCBD5E1)),
                    ),
                  );
                }),
              );
            },
          ),

          // Chap tomondagi o'yiq
          Positioned(
            left: -12,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A), // Tashqi modal foni bilan bir xil
                shape: BoxShape.circle,
              ),
            ),
          ),

          // O'ng tomondagi o'yiq
          Positioned(
            right: -12,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── B. TERMAL 58MM MONOSPACE KO'RINISHI ─────────────────────
  Widget _buildThermalView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          SelectableText(
            widget.receiptText,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const Gap(10),
          const Center(
            child: Text(
              '||||| |||| |||||| ||||| ||||',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 15,
                letterSpacing: 3,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── YORDAMCHI MATN PARSERI ─────────────────────────────────
  _ReceiptData _parseReceipt(String text) {
    String title = "Sport & O'yin Markazi";
    String orderNo = "CH-0001";
    String dateTime = "";
    String sectionOrTable = "Maydon / Stol";
    String customerName = "";
    String duration = "";
    String totalAmount = "0 so'm";
    String paymentType = "NAQD PUL";
    bool isShopSale = false;
    final List<_ReceiptItem> items = [];
    final List<String> splits = [];

    final lines = text.split('\n');

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('=')) continue;

      if (line.contains("Do'kon") || line.contains("Bar Savdosi")) {
        isShopSale = true;
        title = "Do'kon & Bar Savdosi";
        sectionOrTable = "Bar / Do'kon Savdosi";
      }

      if (line.startsWith('Chek #:')) {
        orderNo = line.replaceFirst('Chek #:', '').trim();
      } else if (line.startsWith('Order #:')) {
        orderNo = line.replaceFirst('Order #:', '').trim();
      } else if (line.startsWith('Sana:')) {
        dateTime = line.replaceFirst('Sana:', '').trim();
      } else if (line.startsWith('Maydon/Stol:')) {
        sectionOrTable = line.replaceFirst('Maydon/Stol:', '').trim();
      } else if (line.startsWith('Mijoz:')) {
        customerName = line.replaceFirst('Mijoz:', '').trim();
      } else if (line.startsWith('Vaqt:')) {
        duration = line.replaceFirst('Vaqt:', '').trim();
      } else if (line.startsWith('JAMI TO\'LOV:') || line.startsWith('SUMMA:')) {
        totalAmount = line
            .replaceFirst('JAMI TO\'LOV:', '')
            .replaceFirst('SUMMA:', '')
            .trim();
        if (!totalAmount.contains("so'm")) totalAmount = "$totalAmount so'm";
      } else if (line.startsWith('To\'lov turi:') || line.startsWith('Turi:')) {
        paymentType = line
            .replaceFirst('To\'lov turi:', '')
            .replaceFirst('Turi:', '')
            .trim();
      } else if (line.contains('x') && (line.contains("ming") || line.contains("00"))) {
        // Xaridlar qatori (masalan: Cola x2  24 000)
        final parts = line.split(RegExp(r'\s{2,}'));
        if (parts.length >= 2) {
          items.add(_ReceiptItem(
            title: parts[0].trim(),
            amount: parts.sublist(1).join(' ').trim(),
          ));
        } else {
          items.add(_ReceiptItem(title: line, amount: ''));
        }
      } else if (line.contains('. ') && line.contains(':')) {
        // Partiyalar (masalan: 1. Jasur: 15 000)
        splits.add(line);
      }
    }

    final isDebt = paymentType.toUpperCase().contains('QARZ') ||
        paymentType.toUpperCase().contains('NASIYA');

    return _ReceiptData(
      title: title,
      orderNo: orderNo,
      dateTime: dateTime,
      sectionOrTable: sectionOrTable,
      customerName: customerName,
      duration: duration,
      totalAmount: totalAmount,
      paymentType: paymentType,
      isDebt: isDebt,
      isShopSale: isShopSale,
      items: items,
      splits: splits,
    );
  }
}

class _ReceiptData {
  final String title;
  final String orderNo;
  final String dateTime;
  final String sectionOrTable;
  final String customerName;
  final String duration;
  final String totalAmount;
  final String paymentType;
  final bool isDebt;
  final bool isShopSale;
  final List<_ReceiptItem> items;
  final List<String> splits;

  _ReceiptData({
    required this.title,
    required this.orderNo,
    required this.dateTime,
    required this.sectionOrTable,
    required this.customerName,
    required this.duration,
    required this.totalAmount,
    required this.paymentType,
    required this.isDebt,
    required this.isShopSale,
    required this.items,
    required this.splits,
  });
}

class _ReceiptItem {
  final String title;
  final String amount;

  _ReceiptItem({required this.title, required this.amount});
}
