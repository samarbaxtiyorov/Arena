// ============================================
// Arena — Maydonlar va Stollar Boshqaruv Sahifasi
// Ko'zga yoqimli, zamonaviy va haqiqiy suratlar bilan bezatilgan
// Yangi qo'shish, tahrirlash, o'chirish va narxlarni tezkor o'zgartirish
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
    final controller =
        TextEditingController(text: table.pricePerHour.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.payments_outlined,
                  color: Color(0xFF059669), size: 22),
            ),
            const Gap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    table.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    "Soatlik tarifni o'zgartirish",
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Yangi soatlik narxni kiriting:",
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const Gap(10),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF059669),
              ),
              decoration: InputDecoration(
                suffixText: "so'm/soat",
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
            const Gap(12),
            Wrap(
              spacing: 8,
              children: [30000, 40000, 50000, 70000, 100000].map((price) {
                return ActionChip(
                  label: Text("${price ~/ 1000}k"),
                  labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB)),
                  backgroundColor: const Color(0xFFEFF6FF),
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  onPressed: () {
                    controller.text = price.toString();
                  },
                );
              }).toList(),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                if (ctx.mounted) Navigator.pop(ctx);
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444), size: 24),
            ),
            const Gap(10),
            const Expanded(
              child: Text(
                "Maydonni o'chirish",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          "Rostdan ham \"${table.name}\" maydonini o'chirmoqchimisiz? Uni qayta tiklab bo'lmaydi.",
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
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${table.name} o'chirildi!"),
                    backgroundColor: const Color(0xFFEF4444),
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

  String _getImageForType(String type) {
    switch (type.toLowerCase()) {
      case 'football':
        return 'assets/images/football_pitch.jpg';
      case 'billiard':
        return 'assets/images/billiard_table.jpg';
      case 'ps':
        return 'assets/images/playstation_room.jpg';
      case 'tennis':
        return 'assets/images/table_tennis.jpg';
      default:
        return 'assets/images/billiard_active.jpg';
    }
  }

  String _getTypeName(String type) {
    switch (type.toLowerCase()) {
      case 'football':
        return '⚽ Futbol maydoni';
      case 'billiard':
        return '🎱 Bilyard stoli';
      case 'ps':
        return '🎮 PlayStation';
      case 'tennis':
        return '🏓 Stol tennisi';
      default:
        return '🎯 O\'yin zonasi';
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

    final busyCount =
        allTables.where((t) => activeTableIds.contains(t.id)).length;
    final freeCount = allTables.length - busyCount;

    final filteredTables = allTables.where((t) {
      if (_selectedCategory == 'all') return true;
      return t.type.toLowerCase() == _selectedCategory.toLowerCase();
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
              "Jami: ${allTables.length} ta zona • $busyCount band, $freeCount bo'sh",
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
                "Yangi Maydon",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
          // ── Statistika Kartalari ───────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                _buildStatCard(
                  title: "Jami Zonalar",
                  value: "${allTables.length} ta",
                  color: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                  icon: Icons.sports_soccer_rounded,
                ),
                const Gap(8),
                _buildStatCard(
                  title: "Bo'sh (Tayyor)",
                  value: "$freeCount ta",
                  color: const Color(0xFF059669),
                  bgColor: const Color(0xFFECFDF5),
                  icon: Icons.check_circle_outline_rounded,
                ),
                const Gap(8),
                _buildStatCard(
                  title: "Band (O'yinda)",
                  value: "$busyCount ta",
                  color: busyCount > 0
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF64748B),
                  bgColor: busyCount > 0
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFF1F5F9),
                  icon: Icons.timer_outlined,
                ),
              ],
            ),
          ),

          // ── Kategoriya Chiplari ────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildCategoryChip('all', "Barchasi (${allTables.length})"),
                  const Gap(8),
                  _buildCategoryChip('football', "⚽ Futbol"),
                  const Gap(8),
                  _buildCategoryChip('billiard', "🎱 Bilyard"),
                  const Gap(8),
                  _buildCategoryChip('ps', "🎮 PlayStation"),
                  const Gap(8),
                  _buildCategoryChip('tennis', "🏓 Tennis"),
                  const Gap(8),
                  _buildCategoryChip('other', "🎯 Boshqa"),
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
                          style:
                              TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
                    separatorBuilder: (_, _) => const Gap(14),
                    itemBuilder: (context, index) {
                      final table = filteredTables[index];
                      final isBusy = activeTableIds.contains(table.id);
                      final imagePath = _getImageForType(table.type);

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isBusy
                                ? const Color(0xFFFCA5A5)
                                : const Color(0xFFE2E8F0),
                            width: isBusy ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Maydonning Haqiqiy Surati va Banner Qismi
                              SizedBox(
                                height: 110,
                                width: double.infinity,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                      imagePath,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        color: const Color(0xFF1E293B),
                                        child: const Center(
                                          child: Icon(Icons.sports_soccer,
                                              color: Colors.white24, size: 40),
                                        ),
                                      ),
                                    ),
                                    // Qoraytirish gradienti
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.2),
                                            Colors.black.withOpacity(0.75),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Chapda: Maydon turi
                                    Positioned(
                                      top: 10,
                                      left: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.55),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.white24),
                                        ),
                                        child: Text(
                                          _getTypeName(table.type),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // O'ngda: Holat (Band / Bo'sh)
                                    Positioned(
                                      top: 10,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 9, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isBusy
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFF10B981),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isBusy
                                                      ? const Color(0xFFEF4444)
                                                      : const Color(0xFF10B981))
                                                  .withOpacity(0.4),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const Gap(5),
                                            Text(
                                              isBusy ? "BAND" : "BO'SH",
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Pastki qismda maydon nomi va narxi
                                    Positioned(
                                      bottom: 10,
                                      left: 12,
                                      right: 12,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              table.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                shadows: [
                                                Shadow(
                                                  blurRadius: 6,
                                                  color: Colors.black54,
                                                ),
                                              ],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0F172A)
                                                  .withOpacity(0.85),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color:
                                                      const Color(0xFF34D399),
                                                  width: 1),
                                            ),
                                            child: Text(
                                              "${formatSum(table.pricePerHour)}/soat",
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF34D399),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Pastki Boshqaruv Tugmalari
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 10, 12, 12),
                                child: Row(
                                  children: [
                                    // Tahrirlash tugmasi
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _openAddOrEdit(table),
                                        icon: const Icon(Icons.edit_outlined,
                                            size: 15),
                                        label: const Text(
                                          "Tahrirlash",
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFF2563EB),
                                          side: const BorderSide(
                                              color: Color(0xFFBFDBFE)),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Gap(8),
                                    // Tarifni o'zgartirish tugmasi
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _showQuickPriceDialog(table),
                                        icon: const Icon(
                                            Icons.payments_outlined,
                                            size: 15),
                                        label: const Text(
                                          "Tarif",
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFF059669),
                                          side: const BorderSide(
                                              color: Color(0xFFA7F3D0)),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Gap(8),
                                    // O'chirish tugmasi
                                    InkWell(
                                      onTap: () => _confirmDelete(table, isBusy),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.all(9),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF2F2),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: const Color(0xFFFECACA)),
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Color(0xFFEF4444),
                                          size: 19,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 14),
                const Gap(4),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Gap(4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
