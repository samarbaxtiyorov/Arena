// ============================================
// Arena — SupabaseRemote
// Supabase bilan ishlash (upsert / fetch / snapshot)
// Har bir so'rov faol biznes hisobi (businessId & accountLogin)
// bo'yicha qat'iy izolyatsiya qilingan (Multi-tenant)
// ============================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';

class SupabaseRemote {
  final SupabaseClient? _customClient;
  final String businessId;
  final String accountLogin;

  SupabaseRemote({
    SupabaseClient? client,
    this.businessId = 'biz_arena_sport',
    this.accountLogin = '',
  }) : _customClient = client;

  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  // ── Bulutli To'liq Snapshot (JSONB Sync) ──────
  // Telefon va Kompyuter o'rtasida 100% to'liq sinxronizatsiya
  Future<void> pushSnapshot(Map<String, dynamic> snapshot) async {
    final login = accountLogin.trim().toLowerCase();
    if (login.isEmpty) return;

    final nowIso = DateTime.now().toUtc().toIso8601String();
    try {
      final headers = {
        'apikey': AppConstants.supabaseAnonKey,
        'Authorization': 'Bearer ${AppConstants.supabaseAnonKey}',
        'Content-Type': 'application/json',
      };
      final url = Uri.parse(
          '${AppConstants.supabaseUrl}/rest/v1/cloud_accounts?phone=ilike.${Uri.encodeComponent(login)}');
      await http.patch(
        url,
        headers: headers,
        body: jsonEncode({
          'data_snapshot': snapshot,
          'updated_at': nowIso,
        }),
      ).timeout(const Duration(seconds: 25));
    } catch (_) {
      try {
        await _client.from('cloud_accounts').update({
          'data_snapshot': snapshot,
          'updated_at': nowIso,
        }).ilike('phone', login);
      } catch (_) {}
    }
  }

  Future<Map<String, dynamic>?> fetchSnapshot() async {
    final login = accountLogin.trim().toLowerCase();
    if (login.isEmpty) return null;

    try {
      final headers = {
        'apikey': AppConstants.supabaseAnonKey,
        'Authorization': 'Bearer ${AppConstants.supabaseAnonKey}',
      };
      final url = Uri.parse(
          '${AppConstants.supabaseUrl}/rest/v1/cloud_accounts?phone=ilike.${Uri.encodeComponent(login)}&select=data_snapshot,updated_at&limit=1');
      final res = await http.get(url, headers: headers).timeout(const Duration(seconds: 25));
      if (res.statusCode == 200) {
        final list = List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
        if (list.isNotEmpty && list.first['data_snapshot'] != null) {
          final snap = list.first['data_snapshot'];
          if (snap is Map<String, dynamic>) return snap;
          if (snap is String) return jsonDecode(snap) as Map<String, dynamic>;
        }
      }
    } catch (_) {
      try {
        final res = await _client
            .from('cloud_accounts')
            .select('data_snapshot, updated_at')
            .ilike('phone', login)
            .maybeSingle();
        if (res != null && res['data_snapshot'] != null) {
          final snap = res['data_snapshot'];
          if (snap is Map<String, dynamic>) return snap;
          if (snap is String) return jsonDecode(snap) as Map<String, dynamic>;
        }
      } catch (_) {}
    }
    return null;
  }

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
    int limit = 500,
  }) async {
    var query = _client.from('sessions').select().eq('business_id', businessId);
    if (since != null) {
      query = query.gte('updated_at', since.toUtc().toIso8601String());
    }
    return await query.order('started_at', ascending: false).limit(limit);
  }

  // ── customers ────────────────────────────────
  Future<void> upsertCustomer(Map<String, dynamic> data) async {
    data['business_id'] = businessId;
    await _client.from('customers').upsert(data);
  }

  Future<List<Map<String, dynamic>>> fetchCustomers({int limit = 500}) async {
    return await _client
        .from('customers')
        .select()
        .eq('business_id', businessId)
        .order('name')
        .limit(limit);
  }

  // ── debts ────────────────────────────────────
  Future<void> upsertDebt(Map<String, dynamic> data) async {
    data['business_id'] = businessId;
    await _client.from('debts').upsert(data);
  }

  Future<List<Map<String, dynamic>>> fetchDebts({
    String? customerId,
    int limit = 500,
  }) async {
    var query = _client.from('debts').select().eq('business_id', businessId);
    if (customerId != null) {
      query = query.eq('customer_id', customerId);
    }
    return await query.order('created_at', ascending: false).limit(limit);
  }

  // ── products ─────────────────────────────────
  Future<void> upsertProduct(Map<String, dynamic> data) async {
    data['business_id'] = businessId;
    await _client.from('products').upsert(data);
  }

  Future<List<Map<String, dynamic>>> fetchProducts({int limit = 500}) async {
    return await _client
        .from('products')
        .select()
        .eq('business_id', businessId)
        .order('name')
        .limit(limit);
  }

  // ── Ulanish tekshiruvi (Foolproof Multi-platform) ──
  Future<bool> isConnected() async {
    final login = accountLogin.trim().toLowerCase();
    final urlStr = login.isNotEmpty
        ? '${AppConstants.supabaseUrl}/rest/v1/cloud_accounts?phone=ilike.${Uri.encodeComponent(login)}&select=id&limit=1'
        : '${AppConstants.supabaseUrl}/rest/v1/cloud_accounts?select=id&limit=1';
    try {
      final res = await http.get(Uri.parse(urlStr), headers: {
        'apikey': AppConstants.supabaseAnonKey,
        'Authorization': 'Bearer ${AppConstants.supabaseAnonKey}',
      }).timeout(const Duration(seconds: 15));
      if (res.statusCode >= 200 && res.statusCode < 300) return true;
    } catch (_) {}

    try {
      final res = await _client.from('cloud_accounts').select('id').limit(1);
      return res.isNotEmpty || true;
    } catch (_) {
      return false;
    }
  }
}
