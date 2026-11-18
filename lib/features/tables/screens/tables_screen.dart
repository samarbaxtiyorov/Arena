// ============================================
// Arena — Zallar & Stollar Asosiy Ekrani
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/database_providers.dart';
import '../providers/tables_providers.dart';
import '../widgets/table_card.dart';
import '../widgets/table_category_chips.dart';
import '../widgets/add_table_dialog.dart';

class TablesScreen extends ConsumerWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredTables = ref.watch(filteredTablesProvider);
    final activeSessionsAsync = ref.watch(activeSessionsStreamProvider);
    final allTablesAsync = ref.watch(tablesStreamProvider);
    final db = ref.watch(appDatabaseProvider);

    final activeSessions = activeSessionsAsync.value ?? [];
    final allTables = allTablesAsync.value ?? [];

    final activeCount = activeSessions.where((s) => s.status == 'active').length;
    final idleCount = (allTables.length - activeSessions.length).clamp(0, 999);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'ARENA',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
            ),
            const Gap(10),
            const Text(
              'Zallar & Stollar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          // Sinxronizatsiya tugmasi
          Consumer(
            builder: (context, ref, _) {
              return IconButton(
                tooltip: 'Sinxronizatsiya qilish',
                icon: const Icon(Icons.sync, color: AppColors.textSecondary),
                onPressed: () async {
                  final sync = ref.read(syncServiceProvider);
                  final res = await sync.syncAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          res.isSuccess
                              ? 'Sinxronizatsiya muvaffaqiyatli! (${res.pushed} push, ${res.pulled} pull)'
                              : (res.wasOffline ? 'Offline rejim' : 'Xatolik yuz berdi'),
                        ),
                        backgroundColor: res.isSuccess
                            ? AppColors.success
                            : AppColors.warning,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              );
            },
          ),
          const Gap(8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Statistika qatori
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  // Band stollar
                  _StatBadge(
                    icon: Icons.radio_button_checked,
                    color: AppColors.success,
                    label: 'Band',
                    value: '$activeCount ta',
                  ),
                  const Gap(10),
                  // Bo'sh stollar
                  _StatBadge(
                    icon: Icons.check_circle_outline,
                    color: AppColors.textSecondary,
                    label: 'Bo\'sh',
                    value: '$idleCount ta',
                  ),
                  const Gap(10),
                  // Bugungi kassa
                  Expanded(
                    child: StreamBuilder<List<CashRecord>>(
                      stream: db.cashRecordsDao.watchTodayRecords(),
                      builder: (context, snapshot) {
                        final records = snapshot.data ?? [];
                        final todayTotal = records.fold(0, (sum, r) => sum + r.amount);
                        return _StatBadge(
                          icon: Icons.account_balance_wallet_outlined,
                          color: AppColors.info,
                          label: 'Bugungi kassa',
                          value: Formatters.currency(todayTotal),
                          isExpanded: true,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Toifalar filtri
          const SliverToBoxAdapter(
            child: TableCategoryChips(),
          ),

          const SliverToBoxAdapter(child: Gap(16)),

          // 3. Stollar to'ri (Grid)
          allTablesAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(
                child: Text('Xatolik: $err',
                    style: const TextStyle(color: AppColors.danger)),
              ),
            ),
            data: (_) {
              if (filteredTables.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.table_restaurant_outlined,
                            size: 64, color: AppColors.textDisabled),
                        Gap(12),
                        Text(
                          'Bu toifada stollar topilmadi',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.crossAxisExtent;
                    int crossAxisCount = 1;
                    if (width > 1200) {
                      crossAxisCount = 4;
                    } else if (width > 850) {
                      crossAxisCount = 3;
                    } else if (width > 550) {
                      crossAxisCount = 2;
                    }

                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        mainAxisExtent: 220,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final table = filteredTables[index];
                          // Shu stolga tegishli faol sessiya
                          final session = activeSessions
                              .where((s) => s.tableId == table.id)
                              .firstOrNull;

                          return TableCard(
                            key: ValueKey(table.id),
                            table: table,
                            activeSession: session,
                          );
                        },
                        childCount: filteredTables.length,
                      ),
                    );
                  },
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: Gap(80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Stol qo\'shish'),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddTableDialog(),
          );
        },
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool isExpanded;

  const _StatBadge({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const Gap(8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Gap(1),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
