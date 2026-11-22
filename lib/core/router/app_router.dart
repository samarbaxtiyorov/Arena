// ============================================
// Arena — Navigatsiya (GoRouter)
// 5 ta asosiy modul: Maydonlar, Do'kon, Arxiv, Qarzlar, Boshqaruv
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/tables/screens/tables_screen.dart';
import '../../features/shop/screens/shop_screen.dart';
import '../../features/archive/screens/archive_screen.dart';
import '../../features/nasiya/screens/nasiya_screen.dart';
import '../../features/management/screens/management_screen.dart';
import '../../features/boss/screens/boss_radar_screen.dart';
import '../../features/management/screens/analytics_screen.dart';
import '../../features/management/screens/manage_tables_screen.dart';
import '../../features/management/screens/manage_products_screen.dart';
import '../../features/management/screens/smart_lights_screen.dart';
import '../../features/management/screens/manage_staff_screen.dart';
import '../../features/management/screens/business_settings_screen.dart';
import '../widgets/app_shell.dart';
import '../widgets/boss_shell.dart';
import '../auth/auth_provider.dart';
import '../auth/pin_login_screen.dart';
import '../auth/providers/business_account_provider.dart';
import '../auth/screens/business_auth_screen.dart';
import '../config/app_mode.dart';

class AppRoutes {
  static const String tables     = '/tables';
  static const String shop       = '/shop';
  static const String archive    = '/archive';
  static const String debts      = '/debts';
  static const String management = '/management';

  // Arena Boss (Xo'jayin) maxsus marshrutlari
  static const String bossRadar     = '/boss/radar';
  static const String bossAnalytics = '/boss/analytics';
  static const String bossTables    = '/boss/tables';
  static const String bossProducts  = '/boss/products';
  static const String bossLights    = '/boss/lights';
  static const String bossStaff     = '/boss/staff';
  static const String bossSettings  = '/boss/settings';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final businessState = ref.watch(businessAccountProvider);
  final appMode = ref.watch(appModeProvider);
  final isBoss = appMode == AppMode.boss;

  return GoRouter(
    initialLocation: isBoss ? AppRoutes.bossRadar : AppRoutes.tables,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // 1. Arena POS (kassa) rejimida: Boshqaruv Markazi va Boss marshrutlari qat'iyan man etiladi
      if (!isBoss) {
        if (loc.startsWith('/boss') || loc.startsWith(AppRoutes.management)) {
          return AppRoutes.tables;
        }
      }

      // 2. Arena Boss rejimida: Faqat /boss bilan boshlanuvchi marshrutlarga ruxsat beriladi!
      // Agar kassa sahifalariga (tables, shop, archive, debts) kirilsa, darhol Boss Radarga yo'naltirish
      if (isBoss) {
        if (!loc.startsWith('/boss')) {
          return AppRoutes.bossRadar;
        }
      }

      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          if (businessState.isLoading) {
            return const Scaffold(
              backgroundColor: Color(0xFF0F172A),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFFFACC15)),
              ),
            );
          }

          if (!businessState.hasActiveAccount) {
            return const BusinessAuthScreen();
          }

          if (!authState.isAuthenticated) {
            return const PinLoginScreen();
          }

          // Arena Boss uchun alohida BossShell, Arena POS uchun AppShell
          if (isBoss) {
            return BossShell(child: child);
          }
          return AppShell(child: child);
        },
        routes: [
          // ── POS (KASSA) MARSHRUTLARI ─────────────────────────
          GoRoute(
            path: AppRoutes.tables,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TablesScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.shop,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ShopScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.archive,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ArchiveScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.debts,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NasiyaScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.management,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ManagementScreen(),
            ),
          ),

          // ── BOSS (XO'JAYIN) MAXSUS MARSHRUTLARI ──────────────
          GoRoute(
            path: AppRoutes.bossRadar,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BossRadarScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.bossAnalytics,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AnalyticsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.bossTables,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ManageTablesScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.bossProducts,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ManageProductsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.bossLights,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SmartLightsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.bossStaff,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ManageStaffScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.bossSettings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BusinessSettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});
