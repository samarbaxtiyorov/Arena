// ============================================
// Arena — SyncService
// Offline → Supabase 2 tomonlama sinxronizatsiya
// Multi-tenant: har bir biznes ma'lumotlari faqat
// o'z business_id si doirasida sinxronlanadi
// ============================================

import 'dart:async';
import 'package:drift/drift.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../local/app_database.dart';
import '../remote/supabase_remote.dart';

class SyncService {
  final AppDatabase    _db;
  final SupabaseRemote _remote;
  final bool           isLoggedOut;

  Timer? _timer;
  bool   _isSyncing = false;

  SyncService(this._db, this._remote, {this.isLoggedOut = false});

  // Davriy sinxronizatsiyani boshlash
  void startPeriodicSync({Duration interval = const Duration(minutes: 2)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => syncAll());
    // Darhol bir marta
    syncAll();
  }

  void stopSync() => _timer?.cancel();

  // ── Begona biznes ma'lumotlarini tozalash ────
  Future<void> cleanForeignDataIfNeeded() async {
    // Agar bu boshqa yangi/mustaqil biznes hisobi bo'lsa (masalan Jasmina),
    // lekin avvalgi cheklovsiz sinxronizatsiyada biz_arena_sport demo qarzlari
    // uning SQLite bazasiga tushib qolgan bo'lsa, ularni tozalab tashlaymiz
    if (_remote.businessId != 'biz_arena_sport') {
      const foreignCustomerIds = {
        'cust_001',
        'customer-412b9442-b89a-47b6-aa0f-2d5cd79a4951',
        'customer-63158f5b-a3f1-455f-8459-c284898b7d21',
        'customer-84d2bd8c-6439-4add-a8d9-a9e7d362850d',
        'customer-3f049772-6e85-4949-962d-013f837a410f',
        'customer-e0b3b8c7-a3e7-4a20-a817-768b4ae821fc',
        'customer-d905bd42-660a-4b41-a509-3b90d5445ba2',
        'customer-3a11d464-91d5-4daa-952d-1673209d5492',
        'customer-87939912-8080-46b8-a583-4c822d9bcad8',
        'customer-e949cf36-b0ca-45b3-9d5b-cf7afe6be1c2',
        'customer-0fd43124-e6db-4e55-aff4-1248e28f9d37',
      };

      for (final cId in foreignCustomerIds) {
        await (_db.delete(_db.debts)..where((tbl) => tbl.customerId.equals(cId))).go();
        await (_db.delete(_db.customers)..where((tbl) => tbl.id.equals(cId))).go();
      }

      // Yetim qolgan qarzlarni tozalash (agar customer_id mavjud bo'lmasa)
      try {
        final allCustomers = await _db.customersDao.select(_db.customers).get();
        final validCustomerIds = allCustomers.map((c) => c.id).toSet();
        final allDebts = await _db.debtsDao.select(_db.debts).get();
        for (final d in allDebts) {
          if (!validCustomerIds.contains(d.customerId)) {
            await (_db.delete(_db.debts)..where((tbl) => tbl.id.equals(d.id))).go();
          }
        }
      } catch (_) {}
    }
  }

  // ── To'liq sinxronizatsiya ───────────────────
  Future<SyncResult> syncAll() async {
    if (isLoggedOut) return SyncResult.skipped();
    if (_isSyncing) return SyncResult.skipped();

    // 0. Begona biznes ma'lumotlari keshini tozalash (hatto oflayn bo'lsa ham lokal bazadan tozalaydi)
    await cleanForeignDataIfNeeded();

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

      // 2. SUPABASE → LOCAL (pull — faqat shu business_id ga tegishli ma'lumotlar)
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
        final createdStr = row['created_at'] as String?;
        final updatedStr = row['updated_at'] as String?;
        final createdAt = createdStr != null ? DateTime.tryParse(createdStr)?.toLocal() : null;
        final updatedAt = updatedStr != null ? DateTime.tryParse(updatedStr)?.toLocal() : null;

        await _db.clubTablesDao.insertTable(ClubTablesCompanion.insert(
          id: row['id'] as String,
          name: row['name'] as String,
          type: row['kind'] as String? ?? (row['type'] as String? ?? 'billiard'),
          pricePerHour: (row['hourly_rate'] as num?)?.toInt() ??
              ((row['price_per_hour'] as num?)?.toInt() ?? 15000),
          isActive: Value(row['is_active'] as bool? ?? true),
          sortOrder: Value((row['sort_order'] as num?)?.toInt() ?? 0),
          isSynced: const Value(true),
          createdAt: Value(createdAt ?? DateTime.now()),
          updatedAt: Value(updatedAt ?? createdAt ?? DateTime.now()),
        ));
      }
      return rows.length;
    } catch (e) {
      errors.add('pull tables: $e');
      return 0;
    }
  }

  // ── PULL: customers (Supabase → SQLite) ──────
  Future<int> _pullCustomers(List<String> errors) async {
    try {
      final rows = await _remote.fetchCustomers();
      for (final row in rows) {
        final noteValue = row['note'] as String? ?? row['notes'] as String?;
        final createdStr = row['created_at'] as String?;
        final updatedStr = row['updated_at'] as String?;
        final createdAt = createdStr != null ? DateTime.tryParse(createdStr)?.toLocal() : null;
        final updatedAt = updatedStr != null ? DateTime.tryParse(updatedStr)?.toLocal() : null;

        await _db.customersDao.insertCustomer(CustomersCompanion.insert(
          id:        row['id'] as String,
          name:      row['name'] as String,
          phone:     Value(row['phone'] as String?),
          notes:     Value(noteValue),
          totalDebt: Value((row['total_debt'] as num?)?.toInt() ?? 0),
          isActive:  const Value(true),
          isSynced:  const Value(true),
          createdAt: Value(createdAt ?? DateTime.now()),
          updatedAt: Value(updatedAt ?? createdAt ?? DateTime.now()),
        ));
      }
      return rows.length;
    } catch (e) {
      errors.add('pull customers: $e');
      return 0;
    }
  }

  // ── PULL: debts (Supabase → SQLite) ──────────
  Future<int> _pullDebts(List<String> errors) async {
    try {
      final rows = await _remote.fetchDebts();
      for (final row in rows) {
        final rawAmount = (row['amount'] as num?)?.toInt() ??
            ((row['remaining_amount'] as num?)?.toInt() ?? 0);
        final createdStr = row['created_at'] as String?;
        final updatedStr = row['updated_at'] as String?;
        final createdAt = createdStr != null ? DateTime.tryParse(createdStr)?.toLocal() : null;
        final updatedAt = updatedStr != null ? DateTime.tryParse(updatedStr)?.toLocal() : null;

        await _db.debtsDao.insertDebt(DebtsCompanion.insert(
          id: row['id'] as String,
          customerId: row['customer_id'] as String,
          amount: rawAmount,
          type: rawAmount < 0 ? 'payment' : 'debt',
          description: Value(row['description'] as String?),
          sessionId: const Value(null),
          isSynced: const Value(true),
          createdAt: Value(createdAt ?? DateTime.now()),
          updatedAt: Value(updatedAt ?? createdAt ?? DateTime.now()),
        ));
      }
      return rows.length;
    } catch (e) {
      errors.add('pull debts: $e');
      return 0;
    }
  }

  // ── PULL: products (Supabase → SQLite) ───────
  Future<int> _pullProducts(List<String> errors) async {
    try {
      final rows = await _remote.fetchProducts();
      for (final row in rows) {
        final priceVal = (row['sale_price'] as num?)?.toInt() ??
            ((row['price'] as num?)?.toInt() ?? 0);
        final stockVal = (row['stock_quantity'] as num?)?.toInt() ??
            ((row['stock'] as num?)?.toInt() ?? 0);
        final createdStr = row['created_at'] as String?;
        final updatedStr = row['updated_at'] as String?;
        final createdAt = createdStr != null ? DateTime.tryParse(createdStr)?.toLocal() : null;
        final updatedAt = updatedStr != null ? DateTime.tryParse(updatedStr)?.toLocal() : null;

        await _db.productsDao.insertProduct(ProductsCompanion.insert(
          id:       row['id'] as String,
          name:     row['name'] as String,
          barcode:  Value(row['barcode'] as String?),
          price:    priceVal,
          stock:    Value(stockVal),
          category: Value(row['category'] as String?),
          isActive: Value(row['is_active'] as bool? ?? true),
          isSynced: const Value(true),
          createdAt: Value(createdAt ?? DateTime.now()),
          updatedAt: Value(updatedAt ?? createdAt ?? DateTime.now()),
        ));
      }
      return rows.length;
    } catch (e) {
      errors.add('pull products: $e');
      return 0;
    }
  }

  // ── Map converterlar (Supabase multi-tenant sxemasiga to'liq moslangan) ──

  Map<String, dynamic> _tableToMap(ClubTable t) => {
    'id':          t.id,
    'business_id': _remote.businessId,
    'name':        t.name,
    'kind':        t.type,
    'hourly_rate': t.pricePerHour,
    'is_active':   t.isActive,
    'sort_order':  t.sortOrder,
    'created_at':  t.createdAt.toUtc().toIso8601String(),
  };

  Map<String, dynamic> _sessionToMap(Session s) => {
    'id':               s.id,
    'business_id':      _remote.businessId,
    'table_id':         s.tableId,
    'started_at':       s.startedAt.toUtc().toIso8601String(),
    'ended_at':         s.endedAt?.toUtc().toIso8601String(),
    'duration_seconds': s.durationMin * 60,
    'total_amount':     s.totalAmount,
    'status':           s.status,
    'customer_id':      s.customerId,
    'payment_method':   s.paymentType,
    'created_at':       s.createdAt.toUtc().toIso8601String(),
  };

  Map<String, dynamic> _customerToMap(Customer c) => {
    'id':          c.id,
    'business_id': _remote.businessId,
    'name':        c.name,
    'phone':       c.phone,
    'note':        c.notes,
    'total_debt':  c.totalDebt,
    'created_at':  c.createdAt.toUtc().toIso8601String(),
    'updated_at':  c.updatedAt.toUtc().toIso8601String(),
  };

  Future<Map<String, dynamic>> _debtToMap(Debt d) async {
    final customer = await _db.customersDao.getCustomerById(d.customerId);
    return {
      'id':               d.id,
      'business_id':      _remote.businessId,
      'customer_id':      d.customerId,
      'customer_name':    customer?.name,
      'customer_phone':   customer?.phone,
      'amount':           d.amount,
      'remaining_amount': d.amount,
      'description':      d.description,
      'created_at':       d.createdAt.toUtc().toIso8601String(),
      'updated_at':       d.updatedAt.toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> _productToMap(Product p) => {
    'id':             p.id,
    'business_id':    _remote.businessId,
    'name':           p.name,
    'sale_price':     p.price,
    'stock_quantity': p.stock,
    'category':       p.category,
    'is_active':      p.isActive,
    'created_at':     p.createdAt.toUtc().toIso8601String(),
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
