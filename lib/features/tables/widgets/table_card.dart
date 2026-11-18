// ============================================
// Arena — Stol Kartasi (Aesthetic Dark Slate)
// ============================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/local/app_database.dart';
import '../providers/tables_providers.dart';
import 'session_finish_dialog.dart';

class TableCard extends ConsumerStatefulWidget {
  final ClubTable table;
  final Session? activeSession;

  const TableCard({
    super.key,
    required this.table,
    this.activeSession,
  });

  @override
  ConsumerState<TableCard> createState() => _TableCardState();
}

class _TableCardState extends ConsumerState<TableCard> {
  Timer? _ticker;
  Duration _currentElapsed = Duration.zero;
  int _currentAmount = 0;

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
      _currentAmount = 0;
      return;
    }

    final now = DateTime.now();
    _currentElapsed = now.difference(session.startedAt);

    final minutes = _currentElapsed.inMinutes > 0 ? _currentElapsed.inMinutes : 1;
    final ratePerMinute = widget.table.pricePerHour / 60.0;
    _currentAmount = (minutes * ratePerMinute).round();
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'billiard':
        return Icons.sports_baseball_outlined;
      case 'ps':
        return Icons.sports_esports_outlined;
      case 'football':
        return Icons.sports_soccer_outlined;
      case 'tennis':
        return Icons.sports_tennis_outlined;
      default:
        return Icons.table_restaurant_outlined;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'billiard':
        return 'Bilyard';
      case 'ps':
        return 'PlayStation';
      case 'football':
        return 'Futbol';
      case 'tennis':
        return 'Tennis';
      default:
        return 'Stol';
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.activeSession;
    final isActive = session != null && session.status == 'active';
    final isPaused = session != null && session.status == 'paused';
    final isIdle = session == null;

    final controller = ref.read(tablesControllerProvider);

    // Chegara va fon bezaklari
    Color borderColor;
    Color glowColor;
    if (isActive) {
      borderColor = AppColors.success.withOpacity(0.5);
      glowColor = AppColors.success.withOpacity(0.08);
    } else if (isPaused) {
      borderColor = AppColors.warning.withOpacity(0.5);
      glowColor = AppColors.warning.withOpacity(0.08);
    } else {
      borderColor = AppColors.surfaceBorder;
      glowColor = Colors.transparent;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isActive || isPaused ? 1.5 : 1),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: AppColors.success.withOpacity(0.12),
              blurRadius: 16,
              spreadRadius: 1,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: glowColor,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Yuqori qism: Ikonka, Nomi va Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Icon(
                      _getTypeIcon(widget.table.type),
                      color: isActive
                          ? AppColors.success
                          : (isPaused ? AppColors.warning : AppColors.primary),
                      size: 24,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.table.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(2),
                        Text(
                          '${_getTypeLabel(widget.table.type)} • ${Formatters.currency(widget.table.pricePerHour)}/soat',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  _StatusBadge(
                    status: isIdle ? 'idle' : (isActive ? 'active' : 'paused'),
                  ),
                ],
              ),

              const Gap(16),

              // O'rta qism: Jonli Taymer va Summa
              if (isActive || isPaused) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vaqt',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Gap(2),
                          Text(
                            Formatters.timerString(_currentElapsed),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: isActive
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Hisob',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Gap(2),
                          Text(
                            Formatters.currency(_currentAmount),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Bo'sh holat ko'rinishi
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceBorder.withOpacity(0.5)),
                  ),
                  child: const Center(
                    child: Text(
                      'Stol bo\'sh va tayyor',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textDisabled,
                      ),
                    ),
                  ),
                ),
              ],

              const Gap(16),

              // Pastki qism: Harakatlar (Amallar)
              if (isIdle)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow, size: 20),
                    label: const Text(
                      'Boshlash',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => controller.startSession(widget.table.id),
                  ),
                )
              else
                Row(
                  children: [
                    // Pauza / Davom etish
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              isActive ? AppColors.warning : AppColors.success,
                          side: BorderSide(
                            color: isActive
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        icon: Icon(
                          isActive ? Icons.pause : Icons.play_arrow,
                          size: 18,
                        ),
                        label: Text(
                          isActive ? 'Pauza' : 'Davom',
                          style: const TextStyle(fontSize: 13),
                        ),
                        onPressed: () {
                          if (isActive) {
                            controller.pauseSession(session.id);
                          } else {
                            controller.resumeSession(session.id);
                          }
                        },
                      ),
                    ),
                    const Gap(10),
                    // Yakunlash
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.stop_circle_outlined, size: 18),
                        label: const Text(
                          'Yakunlash',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => SessionFinishDialog(
                              table: widget.table,
                              session: session,
                            ),
                          );
                        },
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

class _StatusBadge extends StatelessWidget {
  final String status; // 'idle', 'active', 'paused'

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case 'active':
        bg = AppColors.success.withOpacity(0.18);
        fg = AppColors.success;
        label = 'BAND';
        icon = Icons.radio_button_checked;
        break;
      case 'paused':
        bg = AppColors.warning.withOpacity(0.18);
        fg = AppColors.warning;
        label = 'PAUZA';
        icon = Icons.pause_circle_outline;
        break;
      default:
        bg = AppColors.surfaceAlt;
        fg = AppColors.textSecondary;
        label = 'BO\'SH';
        icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const Gap(5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: fg,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
