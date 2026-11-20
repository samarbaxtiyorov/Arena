// ============================================
// Arena — ESC/POS Termal Chek Generatori
// 58mm va 80mm termal printerlar uchun
// O'yin vaqti, Bo'lingan partiyalar, Bar savdosi
// ============================================

import 'package:intl/intl.dart';
import '../../data/local/app_database.dart';
import 'formatters.dart';
import 'session_billing_helper.dart';

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

  // Stol sessiyasi uchun to'liq POS cheki
  static String forTableSession({
    required ClubTable table,
    required Session session,
    required int finalAmount,
    required String paymentType,
    String? customerName,
    String? customNotes,
    String headerTitle = 'ARENA POS',
    String? footerMessage,
    int width = width58,
  }) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(now);
    final duration = session.endedAt != null
        ? session.endedAt!.difference(session.startedAt)
        : now.difference(session.startedAt);

    final effectiveNotes = customNotes ?? session.notes;
    final gameAmount = SessionBillingHelper.calculateGameAmount(
      startedAt: session.startedAt,
      endedAt: session.endedAt ?? now,
      pricePerHour: table.pricePerHour,
    );
    final barTotal = SessionBillingHelper.getBarTotal(effectiveNotes);
    final barItems = SessionBillingHelper.getBarItemsSummary(effectiveNotes);
    final splits = SessionBillingHelper.getSplits(effectiveNotes);

    buffer.writeln(_divider(width, '='));
    buffer.writeln(_center(headerTitle.toUpperCase(), width));
    buffer.writeln(_center('Sport & O\'yin Markazi', width));
    buffer.writeln(_divider(width, '='));
    buffer.writeln(_row('Chek #:', session.id.substring(0, 8).toUpperCase(), width));
    buffer.writeln(_row('Sana:', dateStr, width));
    buffer.writeln(_row('Maydon/Stol:', table.name, width));
    if (customerName != null && customerName.isNotEmpty) {
      buffer.writeln(_row('Mijoz:', customerName, width));
    }
    buffer.writeln(_divider(width));

    buffer.writeln(_row('Boshlandi:', DateFormat('HH:mm').format(session.startedAt), width));
    buffer.writeln(_row('Tugatildi:', DateFormat('HH:mm').format(now), width));
    buffer.writeln(_row('Vaqt:', Formatters.timerString(duration), width));
    buffer.writeln(_row('Tarif:', '${table.pricePerHour ~/ 1000} ming/soat', width));
    buffer.writeln(_row('O\'yin narxi:', Formatters.currency(gameAmount), width));

    // Partiyalar bo'yicha taqsimot (agar bo'lingan bo'lsa)
    if (splits.isNotEmpty) {
      buffer.writeln(_divider(width));
      buffer.writeln(_center('BO\'LINGAN PARTIYALAR', width));
      for (int i = 0; i < splits.length; i++) {
        final s = splits[i];
        buffer.writeln(_row('${i + 1}. ${s.name}:', Formatters.currency(s.amount), width));
      }
      final totalSplits = splits.fold(0, (sum, s) => sum + s.amount);
      if (gameAmount > totalSplits) {
        buffer.writeln(_row('Qolgan vaqt:', Formatters.currency(gameAmount - totalSplits), width));
      }
    }

    // Bardan xaridlar (agar bor bo'lsa)
    if (barTotal > 0) {
      buffer.writeln(_divider(width));
      buffer.writeln(_center('BARDAN XARIDLAR', width));
      for (final item in barItems) {
        buffer.writeln('  $item');
      }
      buffer.writeln(_row('Bar jami:', '+${Formatters.currency(barTotal)}', width));
    }

    buffer.writeln(_divider(width, '='));
    buffer.writeln(_row('JAMI TO\'LOV:', Formatters.currency(finalAmount), width));

    final paymentName = paymentType == 'cash'
        ? 'NAQD PUL'
        : paymentType == 'card'
            ? 'BANK KARTASI'
            : 'NASIYA / QARZ';
    buffer.writeln(_row('To\'lov turi:', paymentName, width));
    buffer.writeln(_divider(width, '='));
    buffer.writeln(_center(footerMessage ?? 'Xaridingiz uchun rahmat! Yana kutamiz!', width));
    buffer.writeln(_center('Arena POS v2.0', width));
    buffer.writeln(_divider(width, '='));

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
    buffer.writeln(_center('ARENA POS'));
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
      buffer.writeln('  ${record.description!}');
      buffer.writeln(_divider());
    }

    buffer.writeln(_row('SUMMA:', Formatters.currency(record.amount)));
    buffer.writeln(_divider(width58, '='));
    buffer.writeln(_center('Arena POS'));
    buffer.writeln(_divider(width58, '='));

    return buffer.toString();
  }
}
