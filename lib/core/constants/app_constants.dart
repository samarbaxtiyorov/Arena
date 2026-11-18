// ============================================
// Arena — Ilovadagi barcha konstantalar
// ============================================

class AppConstants {
  AppConstants._();

  // Ilova ma'lumotlari
  static const String appName    = 'Arena';
  static const String appVersion = '0.1.0';

  // Supabase — dart-define orqali beriladi:
  //   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
  static const String supabaseUrl     = String.fromEnvironment('SUPABASE_URL',     defaultValue: '');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_KEY',     defaultValue: '');

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
