// ============================================
// Arena POS — Navigatsiya (GoRouter)
// Asosiy modullar: Maydonlar/Stollar, Do'kon, Arxiv, Qarzlar, Boshqaruv
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/tables/screens/tables_screen.dart';
import '../../features/shop/screens/shop_screen.dart';
import '../../features/archive/screens/archive_screen.dart';
import '../../features/nasiya/screens/nasiya_screen.dart';
import '../../features/management/screens/management_screen.dart';
import '../widgets/app_shell.dart';
import '../auth/auth_provider.dart';
import '../auth/pin_login_screen.dart';
import '../auth/providers/business_account_provider.dart';
import '../auth/screens/business_auth_screen.dart';

class AppRoutes {
  static const String tables     = '/tables';
  static const String shop       = '/shop';
  static const String archive    = '/archive';
  static const String debts      = '/debts';
  static const String management = '/management';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final businessState = ref.watch(businessAccountProvider);

  return GoRouter(
    initialLocation: AppRoutes.tables,
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          if (businessState.isLoading) {
            return const Scaffold(
              backgroundColor: Color(0xFF0F172A),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
              ),
            );
          }

          // Akkaunt yo'q bo'lsa ro'yxatdan o'tish / kirish ekrani
          if (!businessState.hasActiveAccount) {
            return const BusinessAuthScreen();
          }

          // Xodim / Kassir autentifikatsiyasi
          if (!authState.isAuthenticated) {
            return const PinLoginScreen();
          }

          return AppShell(child: child);
        },
        routes: [
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
        ],
      ),
    ],
  );
});
