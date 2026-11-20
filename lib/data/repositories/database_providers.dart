// ============================================
// Arena — Database & Sync Provayderlar (Riverpod)
// ============================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/providers/business_account_provider.dart';
import '../local/app_database.dart';
import '../remote/supabase_remote.dart';
import '../sync/sync_service.dart';

// Har bir faol biznes hisobi uchun alohida ajratilgan baza
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final businessState = ref.watch(businessAccountProvider);
  final activeId = businessState.activeAccount?.id ?? 'samar-arena';
  final db = AppDatabase.forAccount(activeId);
  ref.onDispose(db.close);
  return db;
});

// Supabase remote — har bir biznes hisobi uchun alohida scoped businessId
final supabaseRemoteProvider = Provider<SupabaseRemote>((ref) {
  final businessState = ref.watch(businessAccountProvider);
  final activeAccount = businessState.activeAccount;
  final cloudBizId = (activeAccount == null || activeAccount.id == 'samar-arena')
      ? 'biz_arena_sport'
      : activeAccount.id;
  return SupabaseRemote(businessId: cloudBizId);
});

// Sync xizmati
final syncServiceProvider = Provider<SyncService>((ref) {
  final businessState = ref.watch(businessAccountProvider);
  final db     = ref.watch(appDatabaseProvider);
  final remote = ref.watch(supabaseRemoteProvider);
  final isLoggedOut = businessState.isLoggedOut;

  final service = SyncService(db, remote, isLoggedOut: isLoggedOut);
  ref.onDispose(service.stopSync);
  return service;
});

// Sinxronizatsiya holati
enum SyncStatus { idle, syncing, success, error, offline }

class SyncStatusNotifier extends Notifier<SyncStatus> {
  @override
  SyncStatus build() => SyncStatus.idle;

  void setStatus(SyncStatus status) => state = status;
}

final syncStatusProvider = NotifierProvider<SyncStatusNotifier, SyncStatus>(
  SyncStatusNotifier.new,
);
