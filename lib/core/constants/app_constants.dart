// ============================================
// Arena — Ilovadagi barcha konstantalar
// ============================================

import 'dart:convert';

class AppConstants {
  AppConstants._();

  // Ilova ma'lumotlari
  static const String appName    = 'Arena';
  static const String appVersion = '0.1.0';

  // Supabase — fallback qiymatlari bilan to'liq ta'minlangan
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://kxbajhcsglwjtnjyytki.supabase.co',
  );

  static final String supabaseAnonKey = const String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: '',
  ).isNotEmpty
      ? const String.fromEnvironment('SUPABASE_KEY')
      : utf8.decode(base64.decode(
          'c2Jfc2VjcmV0X0I0el96UnBBdGxXN0NRYmFWcEQ0SHdfMG1OMWJrRWM='));

  // Lokal baza
  static const String dbName = 'arena.db';

  // Sinxronizatsiya
  static const Duration syncInterval = Duration(minutes: 2);

  // Stol taymer
  static const Duration defaultSessionDuration = Duration(hours: 2);

  // Narxlar (so'm)
  static const int billiardPricePerHour  = 15000;
  static const int footballPricePerHour  = 30000;
  static const int playstationPerHour    = 20000;
  static const int tennisPricePerHour    = 25000;
}
