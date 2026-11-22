// ============================================
// Arena Boss — Boshqaruv Markazi (Xo'jayin uchun)
// Analitika, Moliya, Xodimlar, Aqlli Chiroqlar, Stol Tariflari
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/auth/providers/business_account_provider.dart';
import 'core/config/app_mode.dart';
import 'core/constants/app_constants.dart';
import 'main.dart';

class BossModeNotifier extends AppModeNotifier {
  @override
  AppMode build() => AppMode.boss;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url:            AppConstants.supabaseUrl,
    publishableKey: AppConstants.supabaseAnonKey,
  );

  final prefs = await SharedPreferences.getInstance();
  BusinessAccountNotifier.initialPrefs = prefs;

  runApp(
    ProviderScope(
      overrides: [
        appModeProvider.overrideWith(BossModeNotifier.new),
      ],
      child: const ArenaApp(initialMode: AppMode.boss),
    ),
  );
}
