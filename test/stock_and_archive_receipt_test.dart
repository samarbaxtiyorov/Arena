import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arena/features/shop/providers/shop_providers.dart';
import 'package:arena/data/local/app_database.dart';

void main() {
  group('Inventory and Stock Enforcement Tests', () {
    test('CartNotifier rejects out-of-stock items (stock <= 0)', () {
      final container = ProviderContainer();
      final notifier = container.read(cartProvider.notifier);

      final outOfStockProduct = Product(
        id: 'prod-0',
        name: 'Coca-Cola Zero',
        price: 12000,
        stock: 0,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      notifier.add(outOfStockProduct);
      final state = container.read(cartProvider);
      expect(state.items.isEmpty, isTrue);
      expect(state.totalCount, equals(0));
    });

    test('CartNotifier does not allow adding more quantity than stock', () {
      final container = ProviderContainer();
      final notifier = container.read(cartProvider.notifier);

      final limitedProduct = Product(
        id: 'prod-2',
        name: 'Fanta 0.5L',
        price: 10000,
        stock: 2,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      // Add 1st
      notifier.add(limitedProduct);
      expect(container.read(cartProvider).items[limitedProduct.id]?.quantity, equals(1));

      // Add 2nd
      notifier.add(limitedProduct);
      expect(container.read(cartProvider).items[limitedProduct.id]?.quantity, equals(2));

      // Attempt 3rd (exceeds stock of 2)
      notifier.add(limitedProduct);
      expect(container.read(cartProvider).items[limitedProduct.id]?.quantity, equals(2));
      expect(container.read(cartProvider).totalAmount, equals(20000));
    });
  });

  group('Archive Receipt Regex Parsing Tests', () {
    test('Regex correctly parses JAMI TO\'LOV, JAMI SUMMA, and SUMMA variations', () {
      final regex = RegExp(r"^(JAMI TO'LOV:|JAMI SUMMA:|JAMI:|SUMMA:|UMUMIY:|TOTAL:)", caseSensitive: false);

      final line1 = "JAMI TO'LOV: 50 000 so'm";
      final match1 = regex.firstMatch(line1);
      expect(match1, isNotNull);
      final val1 = line1.replaceFirst(regex, '').trim();
      expect(val1, equals("50 000 so'm"));

      final line2 = "JAMI SUMMA: 120 000 so'm";
      final match2 = regex.firstMatch(line2);
      expect(match2, isNotNull);
      final val2 = line2.replaceFirst(regex, '').trim();
      expect(val2, equals("120 000 so'm"));

      final line3 = "SUMMA: 35 000 so'm";
      final match3 = regex.firstMatch(line3);
      expect(match3, isNotNull);
      final val3 = line3.replaceFirst(regex, '').trim();
      expect(val3, equals("35 000 so'm"));
    });
  });
}
