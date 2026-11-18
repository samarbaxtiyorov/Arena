// ============================================
// Arena — Database & Sync Provayderlar (Riverpod)
// ============================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/app_database.dart';
import '../remote/supabase_remote.dart';
import '../sync/sync_service.dart';

// Singleton baza
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// Supabase remote
final supabaseRemoteProvider = Provider<SupabaseRemote>((ref) {
  return SupabaseRemote();
});

// Sync xizmati
final syncServiceProvider = Provider<SyncService>((ref) {
  final db     = ref.watch(appDatabaseProvider);
  final remote = ref.watch(supabaseRemoteProvider);
  final service = SyncService(db, remote);
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
