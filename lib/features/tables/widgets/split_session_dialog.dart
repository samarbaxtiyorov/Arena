// ============================================
// Arena — Hisobni Bo'lish Dialogi ([⚏ Bo'lish])
// O'yinchilar o'rtasida to'lovni taqsimlash
// ============================================

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/local/app_database.dart';

class SplitSessionDialog extends StatefulWidget {
  final ClubTable table;
  final int totalAmount;

  const SplitSessionDialog({
    super.key,
    required this.table,
    required this.totalAmount,
  });

  @override
  State<SplitSessionDialog> createState() => _SplitSessionDialogState();
}

class _SplitSessionDialogState extends State<SplitSessionDialog> {
  int _playerCount = 2;

  @override
  Widget build(BuildContext context) {
    final perPlayer = (widget.totalAmount / _playerCount).round();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.call_split_rounded,
              color: Color(0xFFD97706),
              size: 20,
            ),
          ),
          const Gap(10),
          const Text(
            "Hisobni bo'lish",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.table.name,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Jami hisob:"),
              Text(
                formatSum(widget.totalAmount),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const Gap(16),
          const Text(
            "O'yinchilar soni:",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const Gap(8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [2, 3, 4, 5].map((count) {
              final isSel = _playerCount == count;
              return InkWell(
                onTap: () => setState(() => _playerCount = count),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "$count kishi",
                    style: TextStyle(
                      color: isSel ? Colors.white : const Color(0xFF475569),
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const Gap(20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Har bir o'yinchi:",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  formatSum(perPlayer),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Yopish"),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    "Har bir o'yinchi: ${formatSum(perPlayer)} dan qabul qilinadi."),
                backgroundColor: const Color(0xFF2563EB),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text("Tushunarli"),
        ),
      ],
    );
  }
}
