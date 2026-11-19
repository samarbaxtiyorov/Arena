// ============================================
// Arena — Sessiya va Hisob-kitob Yordamchisi
// O'yin vaqti, Bar tovarlari, Jami summa va Izohlar
// ============================================

class BarOrderItem {
  final String name;
  final int qty;
  final int price;

  const BarOrderItem({
    required this.name,
    required this.qty,
    required this.price,
  });

  int get total => qty * price;

  Map<String, dynamic> toMap() => {
        'name': name,
        'qty': qty,
        'price': price,
      };

  factory BarOrderItem.fromMap(Map<String, dynamic> map) {
    return BarOrderItem(
      name: map['name'] as String? ?? '',
      qty: (map['qty'] as num?)?.toInt() ?? 1,
      price: (map['price'] as num?)?.toInt() ?? 0,
    );
  }
}

class SessionBillingHelper {
  /// O'yin summasini vaqt va soatlik stavka bo'yicha hisoblash
  /// Minimal hisob: 1 000 so'm (boshlang'ich minimal to'lov)
  static int calculateGameAmount({
    required DateTime startedAt,
    DateTime? endedAt,
    required int pricePerHour,
  }) {
    final finishTime = endedAt ?? DateTime.now();
    final duration = finishTime.difference(startedAt);

    if (duration.isNegative || duration.inSeconds < 5) {
      return 1000;
    }

    // Daqiqabay hisob
    final totalSeconds = duration.inSeconds;
    final ratePerSecond = pricePerHour / 3600.0;
    final calculated = (totalSeconds * ratePerSecond).round();

    // Kamida 1 000 so'm
    return calculated > 1000 ? calculated : 1000;
  }

  /// Sessiya izohidan (notes) bar summasini aniqlash
  static int getBarTotal(String? notes) {
    if (notes == null || notes.isEmpty) return 0;

    // 1. Agar yangi format BAR_SUM:XXXX bo'lsa
    final sumMatch = RegExp(r'BAR_SUM:(\d+)').firstMatch(notes);
    if (sumMatch != null) {
      return int.tryParse(sumMatch.group(1) ?? '0') ?? 0;
    }

    // 2. Agar eski format bo'lsa: "Bar: Cola x1 (10 000 so'm), Choy x2 (16 000 so'm)"
    if (notes.contains('Bar:')) {
      int total = 0;
      final regex = RegExp(r'\(([\d\s]+)\s*so[^)]*m\)');
      for (final match in regex.allMatches(notes)) {
        final digits = match.group(1)?.replaceAll(RegExp(r'\s+'), '') ?? '';
        final val = int.tryParse(digits) ?? 0;
        total += val;
      }
      return total;
    }

    return 0;
  }

  /// Sessiya izohidan bar mahsulotlari ro'yxatini matn sifatida olish
  static List<String> getBarItemsSummary(String? notes) {
    if (notes == null || notes.isEmpty) return [];

    final result = <String>[];
    final parts = notes.split('|');
    for (final p in parts) {
      final trimmed = p.trim();
      if (trimmed.startsWith('Bar:')) {
        final itemsStr = trimmed.replaceFirst('Bar:', '').trim();
        final rawItems = itemsStr.split(',');
        for (final item in rawItems) {
          final clean = item.trim();
          if (clean.isNotEmpty) {
            result.add(clean);
          }
        }
      }
    }
    return result;
  }

  /// Izohdan faqat foydalanuvchi yozgan qo'shimcha matnni ajratib olish
  static String getUserNotes(String? notes) {
    if (notes == null || notes.isEmpty) return '';

    final parts = notes.split('|');
    final userParts = <String>[];
    for (final p in parts) {
      final trimmed = p.trim();
      if (!trimmed.startsWith('BAR_SUM:') &&
          !trimmed.startsWith('Bar:') &&
          !trimmed.startsWith('BAR_META:')) {
        if (trimmed.isNotEmpty) {
          userParts.add(trimmed);
        }
      }
    }
    return userParts.join(' | ');
  }

  /// Yangi bar buyurtmasini mavjud sessiya notesiga qo'shish
  static String composeNotesWithBar({
    required String? currentNotes,
    required List<String> newItemsSummary,
    required int addedBarSum,
  }) {
    final existingBarSum = getBarTotal(currentNotes);
    final newTotalBarSum = existingBarSum + addedBarSum;

    // Mavjud bar tovarlarini olish
    final existingItems = getBarItemsSummary(currentNotes);
    final allItems = [...existingItems, ...newItemsSummary];

    // Mavjud foydalanuvchi izohini saqlab qolish
    final userNotes = getUserNotes(currentNotes);

    final buffer = StringBuffer();
    buffer.write('BAR_SUM:$newTotalBarSum');
    if (allItems.isNotEmpty) {
      buffer.write(' | Bar: ${allItems.join(', ')}');
    }
    if (userNotes.isNotEmpty) {
      buffer.write(' | $userNotes');
    }

    return buffer.toString();
  }

  /// Yakuniy to'lovda yangi izoh bilan birlashtirish
  static String finalizeNotes({
    required String? originalNotes,
    required String? extraUserNote,
  }) {
    final barTotal = getBarTotal(originalNotes);
    final barItems = getBarItemsSummary(originalNotes);
    final existingUserNote = getUserNotes(originalNotes);

    final buffer = StringBuffer();
    if (barTotal > 0) {
      buffer.write('BAR_SUM:$barTotal');
    }
    if (barItems.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write(' | ');
      buffer.write('Bar: ${barItems.join(', ')}');
    }

    final userNotes = <String>[];
    if (existingUserNote.isNotEmpty) userNotes.add(existingUserNote);
    if (extraUserNote != null && extraUserNote.trim().isNotEmpty) {
      final cleanExtra = extraUserNote.trim();
      if (!userNotes.contains(cleanExtra)) {
        userNotes.add(cleanExtra);
      }
    }

    if (userNotes.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write(' | ');
      buffer.write(userNotes.join(' | '));
    }

    return buffer.toString();
  }
}
