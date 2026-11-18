// ============================================
// Arena — Navigatsiya (GoRouter)
// ============================================

import 'package:go_router/go_router.dart';
import '../../features/tables/screens/tables_screen.dart';
import '../../features/nasiya/screens/nasiya_screen.dart';
import '../../features/shop/screens/shop_screen.dart';
import '../../features/kassa/screens/kassa_screen.dart';
import '../widgets/app_shell.dart';

// Route nomlari
class AppRoutes {
  static const String tables = '/tables';
  static const String nasiya = '/nasiya';
  static const String shop   = '/shop';
  static const String kassa  = '/kassa';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.tables,
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.tables,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TablesScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.nasiya,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: NasiyaScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.shop,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ShopScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.kassa,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: KassaScreen(),
          ),
        ),
      ],
    ),
  ],
);
