// ============================================
// Arena — Nasiya Daftari Riverpod Providers
// ============================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/app_database.dart';
import '../../../data/repositories/database_providers.dart';

// Barcha mijozlar oqimi
final customersStreamProvider = StreamProvider<List<Customer>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.customersDao.watchAllCustomers();
});

// Qidiruv matni
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String q) => state = q;
  void clear() => state = '';
}

final customerSearchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

// Qarz filtri: 'all', 'debtors', 'cleared'
enum DebtFilter { all, debtors, cleared }

class DebtFilterNotifier extends Notifier<DebtFilter> {
  @override
  DebtFilter build() => DebtFilter.all;

  void select(DebtFilter filter) => state = filter;
}

final debtFilterProvider =
    NotifierProvider<DebtFilterNotifier, DebtFilter>(DebtFilterNotifier.new);

// Filtrlangan mijozlar ro'yxati
final filteredCustomersProvider = Provider<List<Customer>>((ref) {
  final customersAsync = ref.watch(customersStreamProvider);
  final query = ref.watch(customerSearchQueryProvider).toLowerCase().trim();
  final filter = ref.watch(debtFilterProvider);

  return customersAsync.maybeWhen(
    data: (list) {
      return list.where((c) {
        // Qidiruv filtri
        final matchesQuery = query.isEmpty ||
            c.name.toLowerCase().contains(query) ||
            (c.phone != null && c.phone!.contains(query));

        if (!matchesQuery) return false;

        // Qarz holati filtri
        switch (filter) {
          case DebtFilter.debtors:
            return c.totalDebt > 0;
          case DebtFilter.cleared:
            return c.totalDebt <= 0;
          case DebtFilter.all:
            return true;
        }
      }).toList();
    },
    orElse: () => [],
  );
});

// Nasiya umumiy statistikasi
class NasiyaStats {
  final int totalDebt;
  final int debtorsCount;
  final int totalCustomers;

  const NasiyaStats({
    required this.totalDebt,
    required this.debtorsCount,
    required this.totalCustomers,
  });
}

final nasiyaStatsProvider = Provider<NasiyaStats>((ref) {
  final customersAsync = ref.watch(customersStreamProvider);
  final list = customersAsync.value ?? [];

  int sumDebt = 0;
  int debtors = 0;

  for (final c in list) {
    if (c.totalDebt > 0) {
      sumDebt += c.totalDebt;
      debtors++;
    }
  }

  return NasiyaStats(
    totalDebt: sumDebt,
    debtorsCount: debtors,
    totalCustomers: list.length,
  );
});

// Muayyan mijoz bo'yicha qarz tarixi oqimi
final customerDebtsProvider =
    StreamProvider.family<List<Debt>, String>((ref, customerId) {
  final db = ref.watch(appDatabaseProvider);
  return db.debtsDao.watchDebtsForCustomer(customerId);
});

// Nasiya boshqaruv Controller
class NasiyaController {
  final AppDatabase _db;
  final Ref _ref;
  static const _uuid = Uuid();

  NasiyaController(this._db, this._ref);

  // Yangi mijoz qo'shish
  Future<Customer> addCustomer({
    required String name,
    String? phone,
    String? notes,
    int initialDebt = 0,
  }) async {
    final now = DateTime.now();
    final customerId = _uuid.v4();

    final customer = CustomersCompanion.insert(
      id: customerId,
      name: name,
      phone: Value(phone),
      notes: Value(notes),
      totalDebt: Value(initialDebt),
      isActive: const Value(true),
      createdAt: Value(now),
      updatedAt: Value(now),
      isSynced: const Value(false),
    );

    await _db.customersDao.insertCustomer(customer);

    // Agar boshlang'ich qarz kiritilgan bo'lsa
    if (initialDebt > 0) {
      await _db.debtsDao.insertDebt(DebtsCompanion.insert(
        id: _uuid.v4(),
        customerId: customerId,
        amount: initialDebt,
        type: 'debt',
        description: const Value('Boshlang\'ich qarz balansi'),
        createdAt: Value(now),
        updatedAt: Value(now),
        isSynced: const Value(false),
      ));
    }

    _triggerSync();
    return (await _db.customersDao.getCustomerById(customerId))!;
  }

  // Qarz qo'shish
  Future<void> addDebt({
    required String customerId,
    required int amount,
    String? description,
    String? sessionId,
  }) async {
    final now = DateTime.now();
    await _db.debtsDao.insertDebt(DebtsCompanion.insert(
      id: _uuid.v4(),
      customerId: customerId,
      amount: amount,
      type: 'debt',
      description: Value(description ?? 'Qarz yozildi'),
      sessionId: Value(sessionId),
      createdAt: Value(now),
      updatedAt: Value(now),
      isSynced: const Value(false),
    ));

    // Qayta hisoblash
    final newTotal = await _db.debtsDao.calculateTotalDebt(customerId);
    await _db.customersDao.updateTotalDebt(customerId, newTotal);

    _triggerSync();
  }

  // To'lov qabul qilish (Qarz yopish)
  Future<void> makePayment({
    required String customerId,
    required int amount,
    String? description,
    String paymentMethod = 'cash', // 'cash' yoki 'card'
  }) async {
    final now = DateTime.now();
    final debtId = _uuid.v4();

    // 1. Debts jadvaliga manfiy qiymat yoki to'lov yozuvi
    await _db.debtsDao.insertDebt(DebtsCompanion.insert(
      id: debtId,
      customerId: customerId,
      amount: -amount, // manfiy summa qarzni kamaytiradi
      type: 'payment',
      description: Value(description ?? 'Qarz to\'lovi ($paymentMethod)'),
      createdAt: Value(now),
      updatedAt: Value(now),
      isSynced: const Value(false),
    ));

    // 2. Kassaga kirim qilish
    final customer = await _db.customersDao.getCustomerById(customerId);
    await _db.cashRecordsDao.insertRecord(CashRecordsCompanion.insert(
      id: _uuid.v4(),
      amount: amount,
      type: 'income',
      category: const Value('debt_payment'),
      description: Value(
          'Qarz to\'lovi: ${customer?.name ?? 'Mijoz'} ($paymentMethod)'),
      createdAt: Value(now),
      recordedAt: Value(now),
      isSynced: const Value(false),
    ));

    // 3. Mijoz qarzini qayta hisoblash
    final newTotal = await _db.debtsDao.calculateTotalDebt(customerId);
    await _db.customersDao.updateTotalDebt(customerId, newTotal);

    _triggerSync();
  }

  void _triggerSync() {
    try {
      final sync = _ref.read(syncServiceProvider);
      sync.syncAll();
    } catch (_) {}
  }
}

final nasiyaControllerProvider = Provider<NasiyaController>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return NasiyaController(db, ref);
});
