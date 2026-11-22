// ============================================
// Arena POS — Kassir va Marker Maxsus Dasturi
// Faqat: Stollar/Maydonlar, Do'kon/Bar, Kassa & Cheklar, Nasiya
// Boshqaruv Markazi va Sozlamalardan 100% toza ajratilgan kassa dasturi
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/auth/providers/business_account_provider.dart';
import 'core/config/app_mode.dart';
import 'core/constants/app_constants.dart';
import 'main.dart';

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
        appModeProvider.overrideWith(AppModeNotifier.new),
      ],
      child: const ArenaApp(initialMode: AppMode.pos),
    ),
  );
}
