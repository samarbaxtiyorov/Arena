// ============================================
// Arena — SyncService
// Offline → Supabase 2 tomonlama sinxronizatsiya
// ============================================

import 'dart:async';
import 'package:drift/drift.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../local/app_database.dart';
import '../remote/supabase_remote.dart';

class SyncService {
  final AppDatabase    _db;
  final SupabaseRemote _remote;

  Timer? _timer;
  bool   _isSyncing = false;

  SyncService(this._db, this._remote);

  // Davriy sinxronizatsiyani boshlash
  void startPeriodicSync({Duration interval = const Duration(minutes: 2)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => syncAll());
    // Darhol bir marta
    syncAll();
  }

  void stopSync() => _timer?.cancel();

  // ── To'liq sinxronizatsiya ───────────────────
  Future<SyncResult> syncAll() async {
    if (_isSyncing) return SyncResult.skipped();

    // Internet bor-yo'qligini tekshir
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      return SyncResult.offline();
    }

    final connected = await _remote.isConnected();
    if (!connected) return SyncResult.offline();

    _isSyncing = true;
    int pushed = 0;
    int pulled = 0;
    final errors = <String>[];

    try {
      // 1. LOCAL → SUPABASE (push)
      pushed += await _pushTables(errors);
      pushed += await _pushSessions(errors);
      pushed += await _pushCustomers(errors);
      pushed += await _pushDebts(errors);
      pushed += await _pushProducts(errors);

      // 2. SUPABASE → LOCAL (pull — tables, customers, debts, products)
      pulled += await _pullTables(errors);
      pulled += await _pullCustomers(errors);
      pulled += await _pullDebts(errors);
      pulled += await _pullProducts(errors);

    } finally {
      _isSyncing = false;
    }

    return SyncResult(pushed: pushed, pulled: pulled, errors: errors);
  }

  // ── PUSH: club_tables ────────────────────────
  Future<int> _pushTables(List<String> errors) async {
    final unsynced = await _db.clubTablesDao.getUnsynced();
    int count = 0;
    for (final row in unsynced) {
      try {
        await _remote.upsertTable(_tableToMap(row));
        await _db.clubTablesDao.markSynced(row.id);
        count++;
      } catch (e) {
        errors.add('table ${row.id}: $e');
      }
    }
    return count;
  }

  // ── PUSH: sessions ───────────────────────────
  Future<int> _pushSessions(List<String> errors) async {
    final unsynced = await _db.sessionsDao.getUnsynced();
    int count = 0;
    for (final row in unsynced) {
      try {
        await _remote.upsertSession(_sessionToMap(row));
        await _db.sessionsDao.markSynced(row.id);
        count++;
      } catch (e) {
        errors.add('session ${row.id}: $e');
      }
    }
    return count;
  }

  // ── PUSH: customers ──────────────────────────
  Future<int> _pushCustomers(List<String> errors) async {
    final unsynced = await _db.customersDao.getUnsynced();
    int count = 0;
    for (final row in unsynced) {
      try {
        await _remote.upsertCustomer(_customerToMap(row));
        await _db.customersDao.markSynced(row.id);
        count++;
      } catch (e) {
        errors.add('customer ${row.id}: $e');
      }
    }
    return count;
  }

  // ── PUSH: debts ──────────────────────────────
  Future<int> _pushDebts(List<String> errors) async {
    final unsynced = await _db.debtsDao.getUnsynced();
    int count = 0;
    for (final row in unsynced) {
      try {
        final map = await _debtToMap(row);
        await _remote.upsertDebt(map);
        await _db.debtsDao.markSynced(row.id);
        count++;
      } catch (e) {
        errors.add('debt ${row.id}: $e');
      }
    }
    return count;
  }

  // ── PUSH: products ───────────────────────────
  Future<int> _pushProducts(List<String> errors) async {
    final unsynced = await _db.productsDao.getUnsynced();
    int count = 0;
    for (final row in unsynced) {
      try {
        await _remote.upsertProduct(_productToMap(row));
        await _db.productsDao.markSynced(row.id);
        count++;
      } catch (e) {
        errors.add('product ${row.id}: $e');
      }
    }
    return count;
  }

  // ── PULL: club_tables (Supabase → SQLite) ────
  Future<int> _pullTables(List<String> errors) async {
    try {
      final rows = await _remote.fetchTables();
      for (final row in rows) {
        await _db.clubTablesDao.insertTable(ClubTablesCompanion.insert(
          id: row['id'] as String,
          name: row['name'] as String,
          type: row['kind'] as String? ?? (row['type'] as String? ?? 'billiard'),
          pricePerHour: (row['hourly_rate'] as num?)?.toInt() ??
              ((row['price_per_hour'] as num?)?.toInt() ?? 15000),
          isActive: Value(row['is_active'] as bool? ?? true),
          sortOrder: Value((row['sort_order'] as num?)?.toInt() ?? 0),
          isSynced: const Value(true),
          createdAt: Value(DateTime.parse(row['created_at'] as String)),
          updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
        ));
      }
      return rows.length;
    } catch (e) {
      errors.add('pull tables: $e');
      return 0;
    }
  }

  // ── PULL: customers (Supabase → SQLite) ──────
  // Supabase ustunlari: note ('notes' emas), is_active YO'Q
  Future<int> _pullCustomers(List<String> errors) async {
    try {
      final rows = await _remote.fetchCustomers();
      for (final row in rows) {
        final noteValue = row['note'] as String? ?? row['notes'] as String?;
        await _db.customersDao.insertCustomer(CustomersCompanion.insert(
          id:        row['id'] as String,
          name:      row['name'] as String,
          phone:     Value(row['phone'] as String?),
          notes:     Value(noteValue),
          totalDebt: Value((row['total_debt'] as num?)?.toInt() ?? 0),
          isActive:  const Value(true), // Supabase'da yo'q, lokal aktiv
          isSynced:  const Value(true),
          createdAt: Value(DateTime.parse(row['created_at'] as String)),
          updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
        ));
      }
      return rows.length;
    } catch (e) {
      errors.add('pull customers: $e');
      return 0;
    }
  }

  // ── PULL: debts (Supabase → SQLite) ──────────
  // Supabase ustunlari: remaining_amount, customer_name, customer_phone
  // session_id va type YO'Q
  Future<int> _pullDebts(List<String> errors) async {
    try {
      final rows = await _remote.fetchDebts();
      for (final row in rows) {
        final rawAmount = (row['amount'] as num?)?.toInt() ??
            ((row['remaining_amount'] as num?)?.toInt() ?? 0);
        await _db.debtsDao.insertDebt(DebtsCompanion.insert(
          id: row['id'] as String,
          customerId: row['customer_id'] as String,
          amount: rawAmount,
          type: rawAmount < 0 ? 'payment' : 'debt',
          description: Value(row['description'] as String?),
          sessionId: const Value(null),
          isSynced: const Value(true),
          createdAt: Value(DateTime.parse(row['created_at'] as String)),
          updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
        ));
      }
      return rows.length;
    } catch (e) {
      errors.add('pull debts: $e');
      return 0;
    }
  }

  // ── PULL: products (Supabase → SQLite) ───────
  // Supabase ustunlari: sale_price ('price' emas), stock_quantity ('stock' emas)
  Future<int> _pullProducts(List<String> errors) async {
    try {
      final rows = await _remote.fetchProducts();
      for (final row in rows) {
        final priceVal = (row['sale_price'] as num?)?.toInt() ??
            ((row['price'] as num?)?.toInt() ?? 0);
        final stockVal = (row['stock_quantity'] as num?)?.toInt() ??
            ((row['stock'] as num?)?.toInt() ?? 0);

        await _db.productsDao.insertProduct(ProductsCompanion.insert(
          id:       row['id'] as String,
          name:     row['name'] as String,
          barcode:  Value(row['barcode'] as String?),
          price:    priceVal,
          stock:    Value(stockVal),
          category: Value(row['category'] as String?),
          isActive: Value(row['is_active'] as bool? ?? true),
          isSynced: const Value(true),
          createdAt: Value(DateTime.parse(row['created_at'] as String)),
          updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
        ));
      }
      return rows.length;
    } catch (e) {
      errors.add('pull products: $e');
      return 0;
    }
  }

  // ── Map converterlar (Supabase sxemasiga to'liq moslangan) ──

  // club_tables: price_per_hour emas -> hourly_rate, type emas -> kind
  Map<String, dynamic> _tableToMap(ClubTable t) => {
    'id':          t.id,
    'name':        t.name,
    'kind':        t.type,
    'hourly_rate': t.pricePerHour,
    'is_active':   t.isActive,
    'sort_order':  t.sortOrder,
    'created_at':  t.createdAt.toIso8601String(),
    'updated_at':  t.updatedAt.toIso8601String(),
  };

  Map<String, dynamic> _sessionToMap(Session s) => {
    'id':           s.id,
    'table_id':     s.tableId,
    'started_at':   s.startedAt.toIso8601String(),
    'ended_at':     s.endedAt?.toIso8601String(),
    'duration_min': s.durationMin,
    'total_amount': s.totalAmount,
    'status':       s.status,
    'customer_id':  s.customerId,
    'payment_type': s.paymentType,
    'notes':        s.notes,
    'created_at':   s.createdAt.toIso8601String(),
    'updated_at':   s.updatedAt.toIso8601String(),
  };

  // customers: notes emas -> note, is_active YO'Q
  Map<String, dynamic> _customerToMap(Customer c) => {
    'id':         c.id,
    'name':       c.name,
    'phone':      c.phone,
    'note':       c.notes,
    'total_debt': c.totalDebt,
    'created_at': c.createdAt.toIso8601String(),
    'updated_at': c.updatedAt.toIso8601String(),
  };

  // debts: session_id va type YO'Q; remaining_amount, customer_name, customer_phone bor
  Future<Map<String, dynamic>> _debtToMap(Debt d) async {
    final customer = await _db.customersDao.getCustomerById(d.customerId);
    return {
      'id':               d.id,
      'customer_id':      d.customerId,
      'customer_name':    customer?.name,
      'customer_phone':   customer?.phone,
      'amount':           d.amount,
      'remaining_amount': d.amount,
      'description':      d.description,
      'created_at':       d.createdAt.toIso8601String(),
      'updated_at':       d.updatedAt.toIso8601String(),
    };
  }

  // products: price emas -> sale_price, stock emas -> stock_quantity
  Map<String, dynamic> _productToMap(Product p) => {
    'id':             p.id,
    'name':           p.name,
    'barcode':        p.barcode,
    'sale_price':     p.price,
    'stock_quantity': p.stock,
    'category':       p.category,
    'is_active':      p.isActive,
    'created_at':     p.createdAt.toIso8601String(),
    'updated_at':     p.updatedAt.toIso8601String(),
  };
}

// Sinxronizatsiya natijasi
class SyncResult {
  final int    pushed;
  final int    pulled;
  final List<String> errors;
  final bool   wasSkipped;
  final bool   wasOffline;

  SyncResult({
    this.pushed = 0,
    this.pulled = 0,
    this.errors = const [],
    this.wasSkipped = false,
    this.wasOffline = false,
  });

  factory SyncResult.skipped() => SyncResult(wasSkipped: true);
  factory SyncResult.offline() => SyncResult(wasOffline: true);

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccess => !wasSkipped && !wasOffline && !hasErrors;

  @override
  String toString() {
    if (wasOffline) return 'SyncResult: offline';
    if (wasSkipped) return 'SyncResult: skipped';
    return 'SyncResult: pushed=$pushed, pulled=$pulled, errors=${errors.length}';
  }
}
