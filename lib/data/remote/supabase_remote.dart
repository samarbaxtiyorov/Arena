// ============================================
// Arena — SupabaseRemote
// Supabase bilan ishlash (upsert / fetch)
// Har bir so'rov faol biznes hisobi (businessId)
// bo'yicha qat'iy izolyatsiya qilingan (Multi-tenant)
// ============================================

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRemote {
  final SupabaseClient? _customClient;
  final String businessId;

  SupabaseRemote({SupabaseClient? client, this.businessId = 'biz_arena_sport'})
      : _customClient = client;

  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  // ── club_tables ──────────────────────────────
  Future<void> upsertTable(Map<String, dynamic> data) async {
    data['business_id'] = businessId;
    await _client.from('club_tables').upsert(data);
  }

  Future<List<Map<String, dynamic>>> fetchTables() async {
    return await _client
        .from('club_tables')
        .select()
        .eq('business_id', businessId)
        .order('sort_order');
  }

  // ── sessions ─────────────────────────────────
  Future<void> upsertSession(Map<String, dynamic> data) async {
    data['business_id'] = businessId;
    await _client.from('sessions').upsert(data);
  }

  Future<List<Map<String, dynamic>>> fetchSessions({
    DateTime? since,
  }) async {
    var query = _client.from('sessions').select().eq('business_id', businessId);
    if (since != null) {
      query = query.gte('updated_at', since.toIso8601String());
    }
    return await query.order('started_at', ascending: false);
  }

  // ── customers ────────────────────────────────
  Future<void> upsertCustomer(Map<String, dynamic> data) async {
    data['business_id'] = businessId;
    await _client.from('customers').upsert(data);
  }

  Future<List<Map<String, dynamic>>> fetchCustomers() async {
    return await _client
        .from('customers')
        .select()
        .eq('business_id', businessId)
        .order('name');
  }

  // ── debts ────────────────────────────────────
  Future<void> upsertDebt(Map<String, dynamic> data) async {
    data['business_id'] = businessId;
    await _client.from('debts').upsert(data);
  }

  Future<List<Map<String, dynamic>>> fetchDebts({
    String? customerId,
  }) async {
    var query = _client.from('debts').select().eq('business_id', businessId);
    if (customerId != null) {
      query = query.eq('customer_id', customerId);
    }
    return await query.order('created_at', ascending: false);
  }

  // ── products ─────────────────────────────────
  Future<void> upsertProduct(Map<String, dynamic> data) async {
    data['business_id'] = businessId;
    await _client.from('products').upsert(data);
  }

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    return await _client
        .from('products')
        .select()
        .eq('business_id', businessId)
        .order('name');
  }

  // ── Ulanish tekshiruvi ───────────────────────
  Future<bool> isConnected() async {
    try {
      await _client.from('customers').select('id').limit(1);
      return true;
    } catch (_) {
      return false;
    }
  }
}
