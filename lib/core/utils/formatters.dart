// ============================================
// Arena — Formatters (Pul va Vaqt formatlash)
// ============================================

import 'package:intl/intl.dart';

String formatSum(int amount) => Formatters.currency(amount);

class Formatters {
  Formatters._();

  // 15000 -> "15 000 so'm"
  static String currency(int amount) {
    final formatter = NumberFormat('#,###', 'ru_RU');
    return '${formatter.format(amount).replaceAll(',', ' ')} so\'m';
  }

  // Daqiqalarni "1s 30d" yoki "45d" ko'rinishida
  static String duration(int minutes) {
    if (minutes < 60) return '$minutes daqiqa';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hours soat';
    return '$hours soat $mins daqiqa';
  }

  // Duration -> "01:24:35"
  static String timerString(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  // Sana -> "18-noyabr, 18:30"
  static String dateTime(DateTime dt) {
    return DateFormat('dd.MM.yyyy HH:mm').format(dt);
  }

  static String timeOnly(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }
}
