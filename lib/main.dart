import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/auth/auth_provider.dart';
import 'core/auth/providers/business_account_provider.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/ui_scale_provider.dart';
import 'core/router/app_router.dart';
import 'data/repositories/database_providers.dart';
import 'data/sync/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase initsializatsiyasi
  await Supabase.initialize(
    url:            AppConstants.supabaseUrl,
    publishableKey: AppConstants.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: ArenaApp(),
    ),
  );
}

class ArenaApp extends ConsumerStatefulWidget {
  const ArenaApp({super.key});

  @override
  ConsumerState<ArenaApp> createState() => _ArenaAppState();
}

class _ArenaAppState extends ConsumerState<ArenaApp>
    with WidgetsBindingObserver {
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resetInactivityTimer();

    // Ilovani ochganda davriy sinxronizatsiyani ishga tushirish
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final syncService = ref.read(syncServiceProvider);
      syncService.startPeriodicSync();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Ilovadan chiqib ketilganda yoki ekran o'chirilganda darhol xavfsizlik blokirovkasi
      _lockApp();
    }
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    // 1 daqiqa (60 soniya) tegilmasa avtomatik blokirovkaga tushadi
    _inactivityTimer = Timer(const Duration(minutes: 1), () {
      _lockApp();
    });
  }

  void _lockApp() {
    final business = ref.read(businessAccountProvider);
    final auth = ref.read(authProvider);
    if (business.hasActiveAccount && auth.isAuthenticated) {
      ref.read(authProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Har safar faol akkaunt almashganda yangi sync xizmatini ishga tushirish
    ref.listen<SyncService>(syncServiceProvider, (previous, next) {
      previous?.stopSync();
      next.startPeriodicSync();
    });

    final router = ref.watch(appRouterProvider);
    final uiScale = ref.watch(uiScaleProvider);

    return MaterialApp.router(
      title: 'Champion POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _resetInactivityTimer(),
          onPointerMove: (_) => _resetInactivityTimer(),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(uiScale.textScale),
            ),
            child: child!,
          ),
        );
      },
    );
  }
}
