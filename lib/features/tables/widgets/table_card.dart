// ============================================
// Arena — Maydon/Stol Kartasi (Skrinshot 6 bilan 1:1)
// Stadion banneri (haqiqiy surat), LED taymer, ⏱/☕ ajratilgan hisob,
// [☕], [⚏ Bo'lish] va [✓ To'lov] tugmalari
// ============================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/session_billing_helper.dart';
import '../../../core/theme/ui_scale_provider.dart';
import '../../../data/local/app_database.dart';
import '../providers/tables_providers.dart';
import 'stadium_banner.dart';
import 'session_finish_dialog.dart';
import 'add_bar_to_session_sheet.dart';
import 'split_session_dialog.dart';

class TableCard extends ConsumerStatefulWidget {
  final ClubTable table;
  final Session? activeSession;
  final int index;

  const TableCard({
    super.key,
    required this.table,
    this.activeSession,
    this.index = 1,
  });

  @override
  ConsumerState<TableCard> createState() => _TableCardState();
}

class _TableCardState extends ConsumerState<TableCard> {
  Timer? _ticker;
  Duration _currentElapsed = Duration.zero;
  int _gameAmount = 0;
  int _barAmount = 0;
  int _totalAmount = 0;

  @override
  void initState() {
    super.initState();
    _updateCalculations();
    if (widget.activeSession != null && widget.activeSession!.status == 'active') {
      _startTicker();
    }
  }

  @override
  void didUpdateWidget(covariant TableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateCalculations();

    final wasActive = oldWidget.activeSession?.status == 'active';
    final isActive = widget.activeSession?.status == 'active';

    if (isActive && !wasActive) {
      _startTicker();
    } else if (!isActive && wasActive) {
      _stopTicker();
    }
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }

  void _startTicker() {
    _stopTicker();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(_updateCalculations);
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _updateCalculations() {
    final session = widget.activeSession;
    if (session == null) {
      _currentElapsed = Duration.zero;
      _gameAmount = 0;
      _barAmount = 0;
      _totalAmount = 0;
      return;
    }

    final now = DateTime.now();
    _currentElapsed = now.difference(session.startedAt);

    // O'yin summasi (boshlang'ich kamida 1 000 so'm)
    _gameAmount = SessionBillingHelper.calculateGameAmount(
      startedAt: session.startedAt,
      endedAt: now,
      pricePerHour: widget.table.pricePerHour,
    );

    // Bar summasi: sessiya buyurtmalaridan 100% aniq olish
    _barAmount = SessionBillingHelper.getBarTotal(session.notes);

    // Jami hisob = O'yin summasi + Bar summasi
    _totalAmount = _gameAmount + _barAmount;
  }

  String _formatTimer() {
    final hours = _currentElapsed.inHours.toString().padLeft(2, '0');
    final minutes = (_currentElapsed.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_currentElapsed.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.activeSession;
    final isBand = session != null && session.status == 'active';
    final controller = ref.read(tablesControllerProvider);
    final uiScale = ref.watch(uiScaleProvider);

    return Container(
      margin: EdgeInsets.only(bottom: uiScale == UiScale.small ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(uiScale == UiScale.small ? 20 : 24),
        border: Border.all(
          color: isBand
              ? const Color(0xFF10B981).withOpacity(0.4)
              : const Color(0xFFE2E8F0),
          width: isBand ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isBand
                ? const Color(0xFF10B981).withOpacity(0.06)
                : Colors.black.withOpacity(0.03),
            blurRadius: uiScale == UiScale.small ? 12 : 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(uiScale.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Yuqori qator: Raqam nishoni va Holat ─────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Dumaloq raqam (1, 2, ...)
                Container(
                  width: uiScale == UiScale.small ? 30 : 34,
                  height: uiScale == UiScale.small ? 30 : 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: uiScale == UiScale.small ? 13 : 15,
                      ),
                    ),
                  ),
                ),

                // Holat belgisi (Band / Bo'sh)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isBand
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isBand
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981),
                        ),
                      ),
                      const Gap(6),
                      Text(
                        isBand ? 'Band' : "Bo'sh",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isBand
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Gap(uiScale == UiScale.small ? 9 : 12),

            // ── 2. Stadion Haqiqiy Foto Banneri va LED taymer ──
            StadiumBanner(
              isLive: isBand,
              timerString: isBand ? _formatTimer() : "00:00:00",
              type: widget.table.type,
              tableIndex: widget.index,
              height: uiScale.bannerHeight,
            ),

            Gap(uiScale == UiScale.small ? 9 : 12),

            // ── 3. Agar Band bo'lsa: ⏱ va ☕ qismlari, Jami hisob ─
            if (isBand) ...[
              Row(
                children: [
                  // O'yin vaqt summasi
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 15,
                            color: Color(0xFF0F172A),
                          ),
                          const Gap(6),
                          Text(
                            formatSum(_gameAmount),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Gap(10),
                  // Bar summasi
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.local_cafe_rounded,
                            size: 15,
                            color: Color(0xFF2563EB),
                          ),
                          const Gap(6),
                          Text(
                            "+${formatSum(_barAmount)}",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(10),

              // Jami hisob qatori
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Jami hisob:",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    formatSum(_totalAmount),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const Gap(12),
            ],

            // ── 4. Maydon nomi va Soatlik narxi ────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.table.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Gap(2),
                    Text(
                      "${formatSum(widget.table.pricePerHour)}/soat",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (val) {
                    if (val == 'pause' && session != null) {
                      controller.pauseSession(session.id);
                    } else if (val == 'resume' && session != null) {
                      controller.resumeSession(session.id);
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (isBand)
                      const PopupMenuItem(
                        value: 'pause',
                        child: Text("Pauza qilish"),
                      ),
                    if (session != null && session.status == 'paused')
                      const PopupMenuItem(
                        value: 'resume',
                        child: Text("Davom ettirish"),
                      ),
                  ],
                ),
              ],
            ),

            const Gap(14),

            // ── 5. Amallar Qatori ──────────────────────────────
            if (isBand)
              Row(
                children: [
                  // [☕] Bar buyurtmasi tugmasi
                  InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => AddBarToSessionSheet(
                          session: session,
                          table: widget.table,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: uiScale == UiScale.small ? 42 : 48,
                      height: uiScale.buttonHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.local_cafe_rounded,
                          color: const Color(0xFF2563EB),
                          size: uiScale == UiScale.small ? 18 : 20,
                        ),
                      ),
                    ),
                  ),
                  const Gap(8),

                  // [⚏ Bo'lish] tugmasi
                  Expanded(
                    child: SizedBox(
                      height: uiScale.buttonHeight,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => SplitSessionDialog(
                              table: widget.table,
                              session: session,
                              currentGameAmount: _gameAmount,
                            ),
                          );
                        },
                        icon: const Icon(Icons.call_split_rounded, size: 16),
                        label: const Text(
                          "Bo'lish",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFEF3C7),
                          foregroundColor: const Color(0xFFB45309),
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                              vertical: uiScale == UiScale.small ? 6 : 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Gap(8),

                  // [✓ To'lov] tugmasi
                  Expanded(
                    child: SizedBox(
                      height: uiScale.buttonHeight,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => SessionFinishDialog(
                              session: session,
                              table: widget.table,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text(
                          "To'lov",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                              vertical: uiScale == UiScale.small ? 6 : 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              // Bo'sh bo'lganda: [▶ O'yinni boshlash]
              SizedBox(
                width: double.infinity,
                height: uiScale.buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    controller.startSession(widget.table.id);
                  },
                  icon: Icon(Icons.play_arrow_rounded,
                      size: uiScale == UiScale.small ? 18 : 20),
                  label: const Text(
                    "O'yinni boshlash",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
