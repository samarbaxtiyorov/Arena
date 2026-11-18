// ============================================
// Arena — ESC/POS Termal Chek Generatori
// 58mm va 80mm termal printerlar uchun
// ============================================

import 'package:intl/intl.dart';
import '../../data/local/app_database.dart';
import 'formatters.dart';

class ReceiptGenerator {
  ReceiptGenerator._();

  // 58mm printer uchun 32 ta belgi kenglik
  static const int width58 = 32;

  // Markazlashtirish
  static String _center(String text, [int width = width58]) {
    if (text.length >= width) return text;
    final pad = (width - text.length) ~/ 2;
    return ' ' * pad + text;
  }

  // Chap va o'ng tomonga yoyish
  static String _row(String left, String right, [int width = width58]) {
    final available = width - left.length - right.length;
    if (available <= 0) return '$left $right';
    return left + (' ' * available) + right;
  }

  // Ajratuvchi chiziq
  static String _divider([int width = width58, String char = '-']) {
    return char * width;
  }

  // Stol sessiyasi uchun chek
  static String forTableSession({
    required ClubTable table,
    required Session session,
    required int finalAmount,
    required String paymentType,
    String? customerName,
  }) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(now);
    final duration = session.endedAt != null
        ? session.endedAt!.difference(session.startedAt)
        : now.difference(session.startedAt);

    buffer.writeln(_divider(width58, '='));
    buffer.writeln(_center('ARENA CLUB'));
    buffer.writeln(_center('Sport & O\'yin Zali'));
    buffer.writeln(_divider(width58, '='));
    buffer.writeln(_row('Chek #:', session.id.substring(0, 8).toUpperCase()));
    buffer.writeln(_row('Sana:', dateStr));
    buffer.writeln(_row('Zal/Stol:', table.name));
    if (customerName != null) {
      buffer.writeln(_row('Mijoz:', customerName));
    }
    buffer.writeln(_divider());

    buffer.writeln(_row('Boshlandi:', DateFormat('HH:mm').format(session.startedAt)));
    buffer.writeln(_row('Tugatildi:', DateFormat('HH:mm').format(now)));
    buffer.writeln(_row('Vaqt:', Formatters.timerString(duration)));
    buffer.writeln(_row('Stavka:', '${Formatters.currency(table.pricePerHour)}/soat'));
    buffer.writeln(_divider());

    buffer.writeln(_row('JAMI TO\'LOV:', Formatters.currency(finalAmount)));
    buffer.writeln(_row('To\'lov turi:', paymentType.toUpperCase()));
    buffer.writeln(_divider(width58, '='));
    buffer.writeln(_center('Xaridingiz uchun rahmat!'));
    buffer.writeln(_center('Yana kuting!'));
    buffer.writeln(_center('Dasturchi: Samar Baxtiyorov'));
    buffer.writeln(_divider(width58, '='));

    return buffer.toString();
  }

  // Kassa yozuvi / Bar savdosi uchun chek
  static String forCashRecord({
    required CashRecord record,
  }) {
    final buffer = StringBuffer();
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(record.recordedAt);
    final isIncome = record.type == 'income';

    buffer.writeln(_divider(width58, '='));
    buffer.writeln(_center('ARENA CLUB'));
    buffer.writeln(_center(isIncome ? 'KASSA TO\'LOV CHEKI' : 'CHIQIM ORDERI'));
    buffer.writeln(_divider(width58, '='));
    buffer.writeln(_row('Order #:', record.id.substring(0, 8).toUpperCase()));
    buffer.writeln(_row('Sana:', dateStr));
    buffer.writeln(_row('Turi:', isIncome ? 'Kirim' : 'Chiqim'));
    if (record.category != null) {
      buffer.writeln(_row('Kategoriya:', record.category!));
    }
    buffer.writeln(_divider());

    if (record.description != null && record.description!.isNotEmpty) {
      buffer.writeln('Izoh:');
      buffer.writeln(' ${record.description!}');
      buffer.writeln(_divider());
    }

    buffer.writeln(_row('SUMMA:', Formatters.currency(record.amount.abs())));
    buffer.writeln(_divider(width58, '='));
    buffer.writeln(_center('Arena Boshqaruv Tizimi'));
    buffer.writeln(_center('Dasturchi: Samar Baxtiyorov'));
    buffer.writeln(_divider(width58, '='));

    return buffer.toString();
  }
}
