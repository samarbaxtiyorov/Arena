// ============================================
// Arena — Do'kon & Bar Riverpod Providers
// ============================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/app_database.dart';
import '../../../data/repositories/database_providers.dart';

// Barcha faol tovarlar oqimi
final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.productsDao.watchAllProducts();
});

// Toifa filtri: 'all', 'drink', 'snack', 'energy', 'other'
class ShopCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void select(String cat) => state = cat;
}

final shopCategoryProvider =
    NotifierProvider<ShopCategoryNotifier, String>(ShopCategoryNotifier.new);

// Qidiruv (nom yoki shtrix-kod)
class ShopSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String q) => state = q;
  void clear() => state = '';
}

final shopSearchQueryProvider =
    NotifierProvider<ShopSearchNotifier, String>(ShopSearchNotifier.new);

// Filtrlangan tovarlar
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final productsAsync = ref.watch(productsStreamProvider);
  final category = ref.watch(shopCategoryProvider);
  final query = ref.watch(shopSearchQueryProvider).toLowerCase().trim();

  return productsAsync.maybeWhen(
    data: (list) {
      return list.where((p) {
        // Toifa mosligi
        final nameLower = p.name.toLowerCase();
        final matchesCat = category == 'all' ||
            p.category == category ||
            (category == 'drink' &&
                (nameLower.contains('cola') ||
                    nameLower.contains('fanta') ||
                    nameLower.contains('pepsi') ||
                    nameLower.contains('suv') ||
                    nameLower.contains('water') ||
                    nameLower.contains('sharbat') ||
                    nameLower.contains('redbull'))) ||
            (category == 'snack' &&
                (nameLower.contains('chips') ||
                    nameLower.contains('lays') ||
                    nameLower.contains('pista') ||
                    nameLower.contains('snack') ||
                    nameLower.contains('shokolad'))) ||
            (category == 'hot' &&
                (nameLower.contains('choy') ||
                    nameLower.contains('kofe') ||
                    nameLower.contains('coffee') ||
                    nameLower.contains('tea')));
        if (!matchesCat) return false;

        // Qidiruv mosligi
        if (query.isEmpty) return true;
        final matchesName = nameLower.contains(query);
        final matchesBarcode = p.barcode != null && p.barcode!.contains(query);
        return matchesName || matchesBarcode;
      }).toList();
    },
    orElse: () => [],
  );
});

// Savat elementi modeli
class CartItem {
  final Product product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  int get subtotal => product.price * quantity;

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

// Savat holati
class CartState {
  final Map<String, CartItem> items; // productId -> CartItem

  const CartState({this.items = const {}});

  int get totalCount =>
      items.values.fold(0, (sum, item) => sum + item.quantity);

  int get totalQuantity => totalCount;

  int get totalAmount =>
      items.values.fold(0, (sum, item) => sum + item.subtotal);

  int get totalSum => totalAmount;

  List<CartItem> get itemsList => items.values.toList();
  bool get isEmpty => items.isEmpty;
}

// Savat Notifier
class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  void addItem(Product product) => add(product);

  void add(Product product) {
    if (product.stock <= 0) return;
    final current = Map<String, CartItem>.from(state.items);
    if (current.containsKey(product.id)) {
      final existing = current[product.id]!;
      if (existing.quantity >= product.stock) return;
      current[product.id] = existing.copyWith(quantity: existing.quantity + 1);
    } else {
      current[product.id] = CartItem(product: product, quantity: 1);
    }
    state = CartState(items: current);
  }

  void removeOne(Product product) {
    final current = Map<String, CartItem>.from(state.items);
    if (!current.containsKey(product.id)) return;

    final existing = current[product.id]!;
    if (existing.quantity > 1) {
      current[product.id] = existing.copyWith(quantity: existing.quantity - 1);
    } else {
      current.remove(product.id);
    }
    state = CartState(items: current);
  }

  void removeItem(String productId) {
    final current = Map<String, CartItem>.from(state.items);
    current.remove(productId);
    state = CartState(items: current);
  }

  void clear() => state = const CartState();
}

final cartProvider =
    NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

// Do'kon boshqaruv xizmati / Controller
class ShopController {
  final AppDatabase _db;
  final Ref _ref;
  static const _uuid = Uuid();

  ShopController(this._db, this._ref);

  // Savatdagi xaridni rasmiylashtirish (Checkout)
  Future<void> checkout({
    required List<CartItem> items,
    required String paymentType, // 'cash', 'card', 'debt'
    String? customerId,
    String? notes,
  }) async {
    if (items.isEmpty) return;
    final now = DateTime.now();
    final totalSum = items.fold(0, (sum, it) => sum + it.subtotal);

    // 1. Zaxiradan kamaytirish
    for (final item in items) {
      await _db.productsDao.decreaseStock(item.product.id, item.quantity);
    }

    // 2. To'lov turiga qarab qayd etish
    if (paymentType == 'cash' || paymentType == 'card') {
      final itemDetails = items.map((i) => '${i.product.name} x${i.quantity}').join(', ');
      await _db.cashRecordsDao.insertRecord(CashRecordsCompanion.insert(
        id: _uuid.v4(),
        amount: totalSum,
        type: 'income',
        category: const Value('shop'),
        description: Value('Bar savdosi ($paymentType): $itemDetails'),
        createdAt: Value(now),
        recordedAt: Value(now),
        isSynced: const Value(false),
      ));
    } else if (paymentType == 'debt' && customerId != null) {
      final itemDetails = items.map((i) => '${i.product.name} x${i.quantity}').join(', ');
      await _db.debtsDao.insertDebt(DebtsCompanion.insert(
        id: _uuid.v4(),
        customerId: customerId,
        amount: totalSum,
        type: 'debt',
        description: Value('Bar savdosi (nasiya): $itemDetails'),
        createdAt: Value(now),
        updatedAt: Value(now),
        isSynced: const Value(false),
      ));

      // Mijoz umumiy qarzini yangilash
      final newTotal = await _db.debtsDao.calculateTotalDebt(customerId);
      await _db.customersDao.updateTotalDebt(customerId, newTotal);
    }

    // 3. Savatni tozalash
    _ref.read(cartProvider.notifier).clear();

    _triggerSync();
  }

  // Yangi tovar qo'shish
  Future<void> addProduct({
    required String name,
    required int price,
    int stock = 0,
    String? barcode,
    String? category,
  }) async {
    final now = DateTime.now();
    await _db.productsDao.insertProduct(ProductsCompanion.insert(
      id: _uuid.v4(),
      name: name,
      price: price,
      stock: Value(stock),
      barcode: Value(barcode),
      category: Value(category ?? 'drink'),
      isActive: const Value(true),
      createdAt: Value(now),
      updatedAt: Value(now),
      isSynced: const Value(false),
    ));

    _triggerSync();
  }

  // Tovarni tahrirlash
  Future<void> updateProduct({
    required String id,
    required String name,
    required int price,
    int stock = 0,
    String? barcode,
    String? category,
  }) async {
    final now = DateTime.now();
    await _db.productsDao.updateProduct(ProductsCompanion(
      id: Value(id),
      name: Value(name),
      price: Value(price),
      stock: Value(stock),
      barcode: Value(barcode),
      category: Value(category ?? 'drink'),
      updatedAt: Value(now),
      isSynced: const Value(false),
    ));

    _triggerSync();
  }

  // Tovarni o'chirish (soft-delete)
  Future<void> deleteProduct(String id) async {
    final now = DateTime.now();
    await _db.productsDao.updateProduct(ProductsCompanion(
      id: Value(id),
      isActive: const Value(false),
      updatedAt: Value(now),
      isSynced: const Value(false),
    ));

    _triggerSync();
  }

  // Tovar zaxirasini oshirish (Kirim / Prikhod)
  Future<void> addStock({
    required String productId,
    required int quantity,
  }) async {
    await _db.productsDao.increaseStock(productId, quantity);
    _triggerSync();
  }

  void _triggerSync() {
    try {
      final sync = _ref.read(syncServiceProvider);
      sync.syncAll();
    } catch (_) {}
  }
}

final shopControllerProvider = Provider<ShopController>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ShopController(db, ref);
});
