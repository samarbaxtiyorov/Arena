// ============================================
// Arena — Asosiy Shell (NavigationBar)
// ============================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../router/app_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith(AppRoutes.nasiya)) return 1;
    if (location.startsWith(AppRoutes.shop))   return 2;
    if (location.startsWith(AppRoutes.kassa))  return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.surfaceBorder, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            switch (index) {
              case 0: context.go(AppRoutes.tables);
              case 1: context.go(AppRoutes.nasiya);
              case 2: context.go(AppRoutes.shop);
              case 3: context.go(AppRoutes.kassa);
            }
          },
          destinations: const [
            NavigationDestination(
              icon:         Icon(Icons.table_restaurant_outlined),
              selectedIcon: Icon(Icons.table_restaurant),
              label:        'Zallar',
            ),
            NavigationDestination(
              icon:         Icon(Icons.book_outlined),
              selectedIcon: Icon(Icons.book),
              label:        'Nasiya',
            ),
            NavigationDestination(
              icon:         Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label:        "Do'kon",
            ),
            NavigationDestination(
              icon:         Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale),
              label:        'Kassa',
            ),
          ],
        ),
      ),
    );
  }
}
