// ============================================
// Arena — SupabaseRemote
// Supabase bilan ishlash (upsert / fetch)
// ============================================

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRemote {
  final SupabaseClient _client = Supabase.instance.client;

  // ── club_tables ──────────────────────────────
  Future<void> upsertTable(Map<String, dynamic> data) async {
    await _client.from('club_tables').upsert(data);
  }

  Future<List<Map<String, dynamic>>> fetchTables() async {
    return await _client
        .from('club_tables')
        .select()
        .order('sort_order');
  }

  // ── sessions ─────────────────────────────────
  Future<void> upsertSession(Map<String, dynamic> data) async {
    await _client.from('sessions').upsert(data);
  }

  Future<List<Map<String, dynamic>>> fetchSessions({
    DateTime? since,
  }) async {
    var query = _client.from('sessions').select();
    if (since != null) {
      query = query.gte('updated_at', since.toIso8601String());
    }
    return await query.order('started_at', ascending: false);
  }

  // ── customers ────────────────────────────────
  Future<void> upsertCustomer(Map<String, dynamic> data) async {
    await _client.from('customers').upsert(data);
  }

  Future<List<Map<String, dynamic>>> fetchCustomers() async {
    return await _client
        .from('customers')
        .select()
        .order('name');
  }

  // ── debts ────────────────────────────────────
  Future<void> upsertDebt(Map<String, dynamic> data) async {
    await _client.from('debts').upsert(data);
  }

  Future<List<Map<String, dynamic>>> fetchDebts({
    String? customerId,
  }) async {
    var query = _client.from('debts').select();
    if (customerId != null) {
      query = query.eq('customer_id', customerId);
    }
    return await query.order('created_at', ascending: false);
  }

  // ── products ─────────────────────────────────
  Future<void> upsertProduct(Map<String, dynamic> data) async {
    await _client.from('products').upsert(data);
  }

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    return await _client.from('products').select().order('name');
  }

  // ── Ulanish tekshiruvi ───────────────────────
  Future<bool> isConnected() async {
    try {
      await _client.from('club_tables').select('id').limit(1);
      return true;
    } catch (_) {
      return false;
    }
  }
}
