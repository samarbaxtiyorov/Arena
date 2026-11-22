import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/auth/auth_provider.dart';
import 'core/auth/providers/business_account_provider.dart';
import 'core/config/app_mode.dart';
import 'core/constants/app_constants.dart';
import 'core/services/lan_pos_server.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/ui_scale_provider.dart';
import 'core/router/app_router.dart';
import 'data/repositories/database_providers.dart';
import 'data/sync/sync_service.dart';

Future<void> main([List<String> args = const []]) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase initsializatsiyasi
  await Supabase.initialize(
    url:            AppConstants.supabaseUrl,
    publishableKey: AppConstants.supabaseAnonKey,
  );

  // SharedPreferences'ni dastur startida darhol yuklash (0-ms holat)
  final prefs = await SharedPreferences.getInstance();
  BusinessAccountNotifier.initialPrefs = prefs;

  final isBoss = args.contains('--boss') || args.contains('-b');
  final mode = isBoss ? AppMode.boss : AppMode.pos;

  runApp(
    ProviderScope(
      overrides: [
        appModeProvider.overrideWith(isBoss ? BossModeNotifier.new : AppModeNotifier.new),
      ],
      child: ArenaApp(initialMode: mode),
    ),
  );
}

class ArenaApp extends ConsumerStatefulWidget {
  final AppMode initialMode;
  const ArenaApp({super.key, this.initialMode = AppMode.pos});

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

    // Dastur rejimini (POS yoki BOSS) initsializatsiya qilish
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(appModeProvider.notifier).setMode(widget.initialMode);
      final syncService = ref.read(syncServiceProvider);
      syncService.startPeriodicSync();

      // Agar kassa (POS) rejimida bo'lsa, lokal LAN serverni ishga tushirish (port 8080)
      if (widget.initialMode == AppMode.pos) {
        ref.read(lanPosServerProvider.notifier).startServer();
      }
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
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      // Ilovadan chiqib ketilganda yoki ekran o'chirilganda darhol xavfsizlik blokirovkasi (Bank ilovalari kabi)
      _lockApp();
    }
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    // 3 daqiqa tegilmasa avtomatik blokirovkaga tushadi
    _inactivityTimer = Timer(const Duration(minutes: 3), () {
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
    final appMode = ref.watch(appModeProvider);

    return MaterialApp.router(
      title: appMode == AppMode.pos ? 'Arena POS — Kassa Tizimi' : 'Arena Boss — Boshqaruv Markazi',
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
