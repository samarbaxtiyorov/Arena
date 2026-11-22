// ============================================
// Arena — Bo'lish / Partiya Hisobi Modali ([⚏ Bo'lish])
// Summa tayyor, qisqa izoh (Samar / Bobur), saqlab qo'yish
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:drift/drift.dart' show Value;

import '../../../core/utils/formatters.dart';
import '../../../core/utils/session_billing_helper.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/database_providers.dart';

class SplitSessionDialog extends ConsumerStatefulWidget {
  final ClubTable table;
  final Session session;
  final int currentGameAmount;

  const SplitSessionDialog({
    super.key,
    required this.table,
    required this.session,
    required this.currentGameAmount,
  });

  @override
  ConsumerState<SplitSessionDialog> createState() => _SplitSessionDialogState();
}

class _SplitSessionDialogState extends ConsumerState<SplitSessionDialog> {
  late final TextEditingController _amountController;
  final _nameController = TextEditingController();
  late String? _currentNotes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentNotes = widget.session.notes;

    // Oldingi partiyalardan qolgan joriy oraliq summasi
    final prevSplitTotal =
        SessionBillingHelper.getTotalSplitAmount(_currentNotes);
    final remainingAmount = widget.currentGameAmount > prevSplitTotal
        ? widget.currentGameAmount - prevSplitTotal
        : 0;

    _amountController = TextEditingController(
      text: remainingAmount > 0 ? remainingAmount.toString() : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveSplit() async {
    final name = _nameController.text.trim();
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Iltimos, o'yinchi ismini yozing (masalan: Samar yoki Bobur)!"),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Summa 0 dan katta bo'lishi kerak!"),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final db = ref.read(appDatabaseProvider);
      final newNotes = SessionBillingHelper.addSplit(
        currentNotes: _currentNotes,
        name: name,
        amount: amount,
      );

      await (db.update(db.sessions)
            ..where((s) => s.id.equals(widget.session.id)))
          .write(SessionsCompanion(
        notes: Value(newNotes),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ));

      _currentNotes = newNotes;

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const Gap(8),
                Expanded(
                  child: Text(
                    "$name uchun ${formatSum(amount)} hisobga saqlandi!",
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
            content: Text("Xatolik: $e"),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteSplit(int index) async {
    try {
      final db = ref.read(appDatabaseProvider);
      final newNotes = SessionBillingHelper.deleteSplit(
        currentNotes: _currentNotes,
        index: index,
      );

      await (db.update(db.sessions)
            ..where((s) => s.id.equals(widget.session.id)))
          .write(SessionsCompanion(
        notes: Value(newNotes),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ));

      setState(() {
        _currentNotes = newNotes;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Joriy sessiyadagi barcha saqlangan bo'lishlar
    final splits = SessionBillingHelper.getSplits(_currentNotes);
    final totalSplits = SessionBillingHelper.getTotalSplitAmount(_currentNotes);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Sarlavha ─────────────────────────────────
              Row(
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
                      size: 22,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${widget.table.name} — Bo'lish",
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const Gap(2),
                        const Text(
                          "Yutqazgan o'yinchi hisobini saqlash",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const Gap(16),

              // ── 1. Summa tayyor maydoni ──────────────────
              const Text(
                "Partiya summasi (tayyor):",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Gap(6),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
                ),
                decoration: InputDecoration(
                  hintText: "Summani kiriting (masalan: 10000)",
                  hintStyle:
                      const TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
                  prefixIcon: const Icon(Icons.payments_outlined,
                      color: Color(0xFF2563EB), size: 22),
                  suffixText: "so'm",
                  suffixStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
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
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),

              const Gap(14),

              // ── 2. Qisqa Izoh maydoni (Samar / Bobur) ──────
              const Text(
                "Kim to'laydi (Izoh):",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Gap(6),
              TextField(
                controller: _nameController,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: "Masalan: Samar yoki Bobur",
                  hintStyle:
                      const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.person_outline,
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),

              const Gap(16),

              // ── 3. Saqlab qo'yish tugmasi ─────────────────
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveSplit,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.bookmark_add_rounded, size: 20),
                  label: Text(
                    _isSaving ? "Saqlanmoqda..." : "Saqlab qo'yish",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              // ── 4. Oldin saqlangan bo'lishlar (agar bor bo'lsa) ──
              if (splits.isNotEmpty) ...[
                const Gap(18),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const Gap(12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Saqlangan partiyalar:",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      "Jami: ${formatSum(totalSplits)}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: splits.length,
                  separatorBuilder: (_, _) => const Gap(6),
                  itemBuilder: (context, index) {
                    final item = splits[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0xFFCBD5E1),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "${index + 1}",
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                          const Gap(8),
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Text(
                            formatSum(item.amount),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const Gap(4),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Color(0xFFEF4444)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _deleteSplit(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
