import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/ui_scale_provider.dart';
import 'core/router/app_router.dart';
import 'data/repositories/database_providers.dart';

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

class _ArenaAppState extends ConsumerState<ArenaApp> {
  @override
  void initState() {
    super.initState();
    // Ilovani ochganda davriy sinxronizatsiyani ishga tushirish
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final syncService = ref.read(syncServiceProvider);
      syncService.startPeriodicSync();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final uiScale = ref.watch(uiScaleProvider);

    return MaterialApp.router(
      title:        'Arena',
      debugShowCheckedModeBanner: false,
      theme:        AppTheme.light,
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(uiScale.textScale),
          ),
          child: child!,
        );
      },
    );
  }
}
