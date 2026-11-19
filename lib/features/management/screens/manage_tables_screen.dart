// ============================================
// Arena — Maydonlar va Stollar Boshqaruv Sahifasi
// Yangi qo'shish, tahrirlash, o'chirish, narxlarni o'zgartirish
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/local/app_database.dart';
import '../../tables/providers/tables_providers.dart';
import '../../tables/widgets/add_table_dialog.dart';

class ManageTablesScreen extends ConsumerStatefulWidget {
  const ManageTablesScreen({super.key});

  @override
  ConsumerState<ManageTablesScreen> createState() => _ManageTablesScreenState();
}

class _ManageTablesScreenState extends ConsumerState<ManageTablesScreen> {
  String _selectedCategory = 'all';

  void _openAddOrEdit([ClubTable? table]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddTableDialog(tableToEdit: table),
    );
  }

  void _showQuickPriceDialog(ClubTable table) {
    final controller = TextEditingController(text: table.pricePerHour.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          "${table.name} — Tarifni o'zgartirish",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Yangi soatlik narxni kiriting:",
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const Gap(8),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF10B981),
              ),
              decoration: InputDecoration(
                suffixText: "so'm/soat",
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Bekor qilish"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final newPrice = int.tryParse(controller.text.trim()) ?? 0;
              if (newPrice > 0) {
                await ref.read(tablesControllerProvider).updateTable(
                      tableId: table.id,
                      name: table.name,
                      type: table.type,
                      pricePerHour: newPrice,
                    );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          "${table.name} tarifi ${formatSum(newPrice)}/soat ga o'zgartirildi!"),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text("Saqlash"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ClubTable table, bool isBusy) {
    if (isBusy) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFEF4444), size: 24),
              Gap(10),
              Expanded(
                child: Text(
                  "Maydon band!",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            "${table.name} da hozir o'yin davom etmoqda. Maydonni o'chirishdan oldin uning hisobini yakunlang!",
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
              ),
              child: const Text("Tushunarli"),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded,
                color: Color(0xFFEF4444), size: 24),
            const Gap(10),
            Expanded(
              child: Text(
                "${table.name} ni o'chirish",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          "Rostdan ham '${table.name}' maydonini tizimdan o'chirmoqchimisiz? Ushbu maydon asosiy ekrandan olib tashlanadi.",
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Bekor qilish"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              await ref.read(tablesControllerProvider).deleteTable(table.id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${table.name} muvaffaqiyatli o'chirildi!"),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text("Ha, o'chirish"),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'football':
        return Icons.sports_soccer_rounded;
      case 'billiard':
        return Icons.sports_baseball_outlined;
      case 'ps':
        return Icons.sports_esports_rounded;
      case 'tennis':
        return Icons.sports_tennis_rounded;
      default:
        return Icons.games_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'football':
        return const Color(0xFF10B981);
      case 'billiard':
        return const Color(0xFF2563EB);
      case 'ps':
        return const Color(0xFF8B5CF6);
      case 'tennis':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _getTypeName(String type) {
    switch (type.toLowerCase()) {
      case 'football':
        return 'Futbol maydoni';
      case 'billiard':
        return 'Bilyard stoli';
      case 'ps':
        return 'PlayStation zona';
      case 'tennis':
        return 'Stol tennisi';
      default:
        return 'O\'yin zonasi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(tablesStreamProvider);
    final activeSessionsAsync = ref.watch(activeSessionsStreamProvider);

    final allTables = tablesAsync.value ?? [];
    final activeSessions = activeSessionsAsync.value ?? [];

    final activeTableIds = activeSessions
        .where((s) => s.status == 'active')
        .map((s) => s.tableId)
        .toSet();

    final filteredTables = allTables.where((t) {
      if (_selectedCategory == 'all') return true;
      return t.type == _selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Maydonlar va Stollar",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              "Jami: ${allTables.length} ta zona mavjud",
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _openAddOrEdit(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                "Qo'shish",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Kategoriya Chiplari ────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildCategoryChip('all', "Barchasi (${allTables.length})"),
                  const Gap(8),
                  _buildCategoryChip('football', "Futbol"),
                  const Gap(8),
                  _buildCategoryChip('billiard', "Bilyard"),
                  const Gap(8),
                  _buildCategoryChip('ps', "PlayStation"),
                  const Gap(8),
                  _buildCategoryChip('tennis', "Tennis"),
                  const Gap(8),
                  _buildCategoryChip('other', "Boshqa"),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // ── Maydonlar Ro'yxati ─────────────────────────
          Expanded(
            child: filteredTables.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.sports_soccer_rounded,
                            size: 48,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const Gap(16),
                        const Text(
                          "Hozircha maydonlar yo'q",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const Gap(6),
                        const Text(
                          "Yangi maydon yoki stol qo'shish uchun yuqoridagi tugmani bosing",
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          textAlign: TextAlign.center,
                        ),
                        const Gap(16),
                        ElevatedButton.icon(
                          onPressed: () => _openAddOrEdit(),
                          icon: const Icon(Icons.add),
                          label: const Text("Yangi maydon qo'shish"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTables.length,
                    separatorBuilder: (_, _) => const Gap(12),
                    itemBuilder: (context, index) {
                      final table = filteredTables[index];
                      final isBusy = activeTableIds.contains(table.id);
                      final typeColor = _getTypeColor(table.type);
                      final typeIcon = _getTypeIcon(table.type);

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isBusy
                                ? const Color(0xFFEF4444).withOpacity(0.3)
                                : const Color(0xFFE2E8F0),
                            width: isBusy ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            // Yuqori qator: Ikonka, Nomi, Holati
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: typeColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(typeIcon, color: typeColor, size: 22),
                                ),
                                const Gap(12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            table.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const Gap(8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isBusy
                                                  ? const Color(0xFFFEE2E2)
                                                  : const Color(0xFFDCFCE7),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 5,
                                                  height: 5,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isBusy
                                                        ? const Color(0xFFEF4444)
                                                        : const Color(0xFF10B981),
                                                  ),
                                                ),
                                                const Gap(4),
                                                Text(
                                                  isBusy ? "Band" : "Bo'sh",
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    color: isBusy
                                                        ? const Color(0xFFEF4444)
                                                        : const Color(0xFF10B981),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Gap(2),
                                      Text(
                                        _getTypeName(table.type),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      formatSum(table.pricePerHour),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const Text(
                                      "soatiga",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const Gap(12),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            const Gap(10),

                            // Pastki boshqaruv tugmalari
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _openAddOrEdit(table),
                                    icon: const Icon(Icons.edit_outlined, size: 15),
                                    label: const Text(
                                      "Tahrirlash",
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF2563EB),
                                      side: const BorderSide(
                                          color: Color(0xFFBFDBFE)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const Gap(8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _showQuickPriceDialog(table),
                                    icon: const Icon(Icons.payments_outlined,
                                        size: 15),
                                    label: const Text(
                                      "Tarif",
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF10B981),
                                      side: const BorderSide(
                                          color: Color(0xFFA7F3D0)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const Gap(8),
                                InkWell(
                                  onTap: () => _confirmDelete(table, isBusy),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: const Color(0xFFFECACA)),
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Color(0xFFEF4444),
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String key, String title) {
    final isSelected = _selectedCategory == key;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = key),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
