// ============================================
// Arena — SyncService
// Offline → Supabase 2 tomonlama sinxronizatsiya
// Multi-tenant: har bir biznes ma'lumotlari faqat
// o'z business_id si doirasida sinxronlanadi
// Snapshot JSONB + Relational Sync (Telefon & Kompyuter)
// ============================================

import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

    // 0. Begona biznes ma'lumotlari keshini tozalash
    await cleanForeignDataIfNeeded();

    // Haqiqiy ulanishni to'g'ridan-to'g'ri Supabase endpointi orqali tekshiramiz (Linux/Android xavfsiz)
    final connected = await _remote.isConnected();
    if (!connected) return SyncResult.offline();

    _isSyncing = true;
    int pushed = 0;
    int pulled = 0;
    final errors = <String>[];

    try {
      // 1. BULUTLI SNAPSHOT BILAN 100% ISHONCHLI SINXRONIZATSIYA
      // Telefon va kompyuter o'rtasida to'liq ma'lumot almashinuvi
      final cloudSnapshot = await _remote.fetchSnapshot();

      final localTables = await _db.clubTablesDao.select(_db.clubTables).get();
      final localProducts = await _db.productsDao.select(_db.products).get();
      final localDebts = await _db.debtsDao.select(_db.debts).get();
      final localCustomers = await _db.customersDao.select(_db.customers).get();
      final localSessions = await _db.sessionsDao.select(_db.sessions).get();

      final hasLocalData = localTables.isNotEmpty ||
          localProducts.isNotEmpty ||
          localDebts.isNotEmpty ||
          localCustomers.isNotEmpty ||
          localSessions.isNotEmpty;

      if (!hasLocalData && cloudSnapshot != null && cloudSnapshot.isNotEmpty) {
        // Lokal bo'sh (kompyuterda yangi kirilgan) -> bulutdan to'liq yuklab tiklaymiz
        final count = await importSnapshot(cloudSnapshot);
        pulled += count;
      } else {
        // Agar bulutda ham snapshot bo'lsa, undan yetishmayotganlarni import qilamiz
        if (cloudSnapshot != null && cloudSnapshot.isNotEmpty) {
          final count = await importSnapshot(cloudSnapshot);
          pulled += count;
        }
        // So'ngra barcha yangi lokal holatni bulutga eksport qilib push qilamiz
        final snapshotToPush = await exportSnapshot();
        await _remote.pushSnapshot(snapshotToPush);
        pushed += localTables.length +
            localProducts.length +
            localDebts.length +
            localCustomers.length;
      }

      // 2. QO'SHIMCHA: Relational jadvallarni relationalErrors bilan push/pull qilish
      // Relational jadvallardagi integer schema xatolari asosiy snapshot sync ni buzmaydi
      final relationalErrors = <String>[];
      try { pushed += await _pushTables(relationalErrors); } catch (_) {}
      try { pushed += await _pushSessions(relationalErrors); } catch (_) {}
      try { pushed += await _pushCustomers(relationalErrors); } catch (_) {}
      try { pushed += await _pushDebts(relationalErrors); } catch (_) {}
      try { pushed += await _pushProducts(relationalErrors); } catch (_) {}

      try { pulled += await _pullTables(relationalErrors); } catch (_) {}
      try { pulled += await _pullCustomers(relationalErrors); } catch (_) {}
      try { pulled += await _pullDebts(relationalErrors); } catch (_) {}
      try { pulled += await _pullProducts(relationalErrors); } catch (_) {}

    } catch (e) {
      errors.add('syncAll error: $e');
    } finally {
      _isSyncing = false;
    }

    return SyncResult(pushed: pushed, pulled: pulled, errors: errors);
  }

  // ── SNAPSHOT EKSPORT (Lokal Bazadagi hamma ma'lumotlarni yig'ish) ──
  Future<Map<String, dynamic>> exportSnapshot() async {
    final tables = await _db.clubTablesDao.select(_db.clubTables).get();
    final products = await _db.productsDao.select(_db.products).get();
    final customers = await _db.customersDao.select(_db.customers).get();
    final debts = await _db.debtsDao.select(_db.debts).get();
    final sessions = await _db.sessionsDao.select(_db.sessions).get();
    final cashRecords = await _db.cashRecordsDao.select(_db.cashRecords).get();

    dynamic staffListJson;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawStaff = prefs.getString('arena_staff_members_${_db.accountId}');
      if (rawStaff != null && rawStaff.isNotEmpty) {
        staffListJson = jsonDecode(rawStaff);
      }
    } catch (_) {}

    return {
      'version': 1,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'business_id': _remote.businessId,
      'tables': tables.map(_tableToSnapshotMap).toList(),
      'products': products.map(_productToSnapshotMap).toList(),
      'customers': customers.map(_customerToSnapshotMap).toList(),
      'debts': debts.map(_debtToSnapshotMap).toList(),
      'sessions': sessions.map(_sessionToSnapshotMap).toList(),
      'cash_records': cashRecords.map(_cashRecordToSnapshotMap).toList(),
      'staff': staffListJson,
    };
  }

  // ── SNAPSHOT IMPORT (Bulutdagi snapshotni lokal bazaga to'liq tiklash) ──
  Future<int> importSnapshot(Map<String, dynamic> snapshot) async {
    int count = 0;

    // 1. Customers (Avval mijozlar tiklanadi, chunki qarzlar unga bog'liq)
    if (snapshot['customers'] is List) {
      for (final item in snapshot['customers'] as List) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final id = map['id']?.toString() ?? '';
          final name = map['name']?.toString() ?? '';
          if (id.isEmpty || name.isEmpty) continue;
          await _db.into(_db.customers).insertOnConflictUpdate(CustomersCompanion.insert(
            id: id,
            name: name,
            phone: Value(map['phone']?.toString()),
            notes: Value(map['notes']?.toString()),
            totalDebt: Value((map['total_debt'] as num?)?.toInt() ?? 0),
            isActive: Value(map['is_active'] as bool? ?? true),
            isSynced: const Value(true),
            createdAt: Value(DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now()),
            updatedAt: Value(DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now()),
          ));
          count++;
        }
      }
    }

    // 2. Debts (Qarzlar)
    if (snapshot['debts'] is List) {
      for (final item in snapshot['debts'] as List) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final id = map['id']?.toString() ?? '';
          final customerId = map['customer_id']?.toString() ?? '';
          if (id.isEmpty || customerId.isEmpty) continue;
          await _db.into(_db.debts).insertOnConflictUpdate(DebtsCompanion.insert(
            id: id,
            customerId: customerId,
            amount: (map['amount'] as num?)?.toInt() ?? 0,
            type: map['type']?.toString() ?? 'debt',
            description: Value(map['description']?.toString()),
            sessionId: Value(map['session_id']?.toString()),
            isSynced: const Value(true),
            createdAt: Value(DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now()),
            updatedAt: Value(DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now()),
          ));
          count++;
        }
      }
    }

    // 3. Tables (Maydonlar va Stollar)
    if (snapshot['tables'] is List) {
      for (final item in snapshot['tables'] as List) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final id = map['id']?.toString() ?? '';
          final name = map['name']?.toString() ?? '';
          if (id.isEmpty || name.isEmpty) continue;
          await _db.into(_db.clubTables).insertOnConflictUpdate(ClubTablesCompanion.insert(
            id: id,
            name: name,
            type: map['type']?.toString() ?? (map['kind']?.toString() ?? 'football'),
            pricePerHour: (map['price_per_hour'] as num?)?.toInt() ??
                ((map['hourly_rate'] as num?)?.toInt() ?? 100000),
            isActive: Value(map['is_active'] as bool? ?? true),
            sortOrder: Value((map['sort_order'] as num?)?.toInt() ?? 0),
            isSynced: const Value(true),
            createdAt: Value(DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now()),
            updatedAt: Value(DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now()),
          ));
          count++;
        }
      }
    }

    // 4. Products (Mahsulotlar va Bar)
    if (snapshot['products'] is List) {
      for (final item in snapshot['products'] as List) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final id = map['id']?.toString() ?? '';
          final name = map['name']?.toString() ?? '';
          if (id.isEmpty || name.isEmpty) continue;
          await _db.into(_db.products).insertOnConflictUpdate(ProductsCompanion.insert(
            id: id,
            name: name,
            barcode: Value(map['barcode']?.toString()),
            price: (map['price'] as num?)?.toInt() ??
                ((map['sale_price'] as num?)?.toInt() ?? 0),
            stock: Value((map['stock'] as num?)?.toInt() ??
                ((map['stock_quantity'] as num?)?.toInt() ?? 0)),
            category: Value(map['category']?.toString()),
            imageUrl: Value(map['image_url']?.toString()),
            isActive: Value(map['is_active'] as bool? ?? true),
            isSynced: const Value(true),
            createdAt: Value(DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now()),
            updatedAt: Value(DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now()),
          ));
          count++;
        }
      }
    }

    // 5. Sessions (Sessiyalar)
    if (snapshot['sessions'] is List) {
      for (final item in snapshot['sessions'] as List) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final id = map['id']?.toString() ?? '';
          final tableId = map['table_id']?.toString() ?? '';
          if (id.isEmpty || tableId.isEmpty) continue;
          final startedStr = map['started_at']?.toString();
          final endedStr = map['ended_at']?.toString();
          await _db.into(_db.sessions).insertOnConflictUpdate(SessionsCompanion.insert(
            id: id,
            tableId: tableId,
            startedAt: DateTime.tryParse(startedStr ?? '') ?? DateTime.now(),
            endedAt: Value(endedStr != null ? DateTime.tryParse(endedStr) : null),
            durationMin: Value((map['duration_min'] as num?)?.toInt() ?? 0),
            totalAmount: Value((map['total_amount'] as num?)?.toInt() ?? 0),
            status: Value(map['status']?.toString() ?? 'active'),
            customerId: Value(map['customer_id']?.toString()),
            paymentType: Value(map['payment_type']?.toString() ??
                (map['payment_method']?.toString() ?? 'cash')),
            notes: Value(map['notes']?.toString()),
            isSynced: const Value(true),
            createdAt: Value(DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now()),
            updatedAt: Value(DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now()),
          ));
          count++;
        }
      }
    }

    // 6. Cash Records (Kassa yozuvlari)
    if (snapshot['cash_records'] is List) {
      for (final item in snapshot['cash_records'] as List) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final id = map['id']?.toString() ?? '';
          if (id.isEmpty) continue;
          await _db.into(_db.cashRecords).insertOnConflictUpdate(CashRecordsCompanion.insert(
            id: id,
            amount: (map['amount'] as num?)?.toInt() ?? 0,
            type: map['type']?.toString() ?? 'income',
            category: Value(map['category']?.toString()),
            description: Value(map['description']?.toString()),
            sessionId: Value(map['session_id']?.toString()),
            recordedAt: Value(DateTime.tryParse(map['recorded_at']?.toString() ?? '') ?? DateTime.now()),
            isSynced: const Value(true),
            createdAt: Value(DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now()),
          ));
          count++;
        }
      }
    }

    // 7. Staff (Xodimlar va Kassirlar)
    if (snapshot['staff'] != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final staffStr = snapshot['staff'] is String
            ? snapshot['staff'] as String
            : jsonEncode(snapshot['staff']);
        await prefs.setString('arena_staff_members_${_db.accountId}', staffStr);
      } catch (_) {}
    }

    return count;
  }

  // ── Snapshot yordamchi serializatorlar ───────────
  Map<String, dynamic> _tableToSnapshotMap(ClubTable t) => {
    'id': t.id,
    'name': t.name,
    'type': t.type,
    'price_per_hour': t.pricePerHour,
    'is_active': t.isActive,
    'sort_order': t.sortOrder,
    'created_at': t.createdAt.toIso8601String(),
    'updated_at': t.updatedAt.toIso8601String(),
  };

  Map<String, dynamic> _productToSnapshotMap(Product p) => {
    'id': p.id,
    'name': p.name,
    'barcode': p.barcode,
    'price': p.price,
    'stock': p.stock,
    'category': p.category,
    'image_url': p.imageUrl,
    'is_active': p.isActive,
    'created_at': p.createdAt.toIso8601String(),
    'updated_at': p.updatedAt.toIso8601String(),
  };

  Map<String, dynamic> _customerToSnapshotMap(Customer c) => {
    'id': c.id,
    'name': c.name,
    'phone': c.phone,
    'notes': c.notes,
    'total_debt': c.totalDebt,
    'is_active': c.isActive,
    'created_at': c.createdAt.toIso8601String(),
    'updated_at': c.updatedAt.toIso8601String(),
  };

  Map<String, dynamic> _debtToSnapshotMap(Debt d) => {
    'id': d.id,
    'customer_id': d.customerId,
    'amount': d.amount,
    'type': d.type,
    'description': d.description,
    'session_id': d.sessionId,
    'created_at': d.createdAt.toIso8601String(),
    'updated_at': d.updatedAt.toIso8601String(),
  };

  Map<String, dynamic> _sessionToSnapshotMap(Session s) => {
    'id': s.id,
    'table_id': s.tableId,
    'started_at': s.startedAt.toIso8601String(),
    'ended_at': s.endedAt?.toIso8601String(),
    'duration_min': s.durationMin,
    'total_amount': s.totalAmount,
    'status': s.status,
    'customer_id': s.customerId,
    'payment_type': s.paymentType,
    'notes': s.notes,
    'created_at': s.createdAt.toIso8601String(),
    'updated_at': s.updatedAt.toIso8601String(),
  };

  Map<String, dynamic> _cashRecordToSnapshotMap(CashRecord c) => {
    'id': c.id,
    'amount': c.amount,
    'type': c.type,
    'category': c.category,
    'description': c.description,
    'session_id': c.sessionId,
    'recorded_at': c.recordedAt.toIso8601String(),
    'created_at': c.createdAt.toIso8601String(),
  };

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
