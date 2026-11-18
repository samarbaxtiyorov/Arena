// ============================================
// Arena — ProductsDao
// ============================================

import 'package:drift/drift.dart';
import '../tables/products_table.dart';
import '../app_database.dart';

part 'products_dao.g.dart';

@DriftAccessor(tables: [Products])
class ProductsDao extends DatabaseAccessor<AppDatabase>
    with _$ProductsDaoMixin {
  ProductsDao(super.db);

  Stream<List<Product>> watchAllProducts() =>
      (select(products)
        ..where((p) => p.isActive.equals(true))
        ..orderBy([(p) => OrderingTerm.asc(p.name)]))
          .watch();

  Future<Product?> getByBarcode(String barcode) =>
      (select(products)..where((p) => p.barcode.equals(barcode)))
          .getSingleOrNull();

  Future<void> insertProduct(ProductsCompanion entry) =>
      into(products).insertOnConflictUpdate(entry);

  Future<void> updateProduct(ProductsCompanion entry) =>
      (update(products)..where((p) => p.id.equals(entry.id.value)))
          .write(entry);

  // Zaxirani kamaytirish (savdo)
  Future<void> decreaseStock(String id, int quantity) async {
    final product = await (select(products)
        ..where((p) => p.id.equals(id)))
        .getSingle();
    await (update(products)..where((p) => p.id.equals(id)))
        .write(ProductsCompanion(
          stock:     Value(product.stock - quantity),
          updatedAt: Value(DateTime.now()),
          isSynced:  const Value(false),
        ));
  }

  // Zaxirani oshirish (kirim / tovar qabul qilish)
  Future<void> increaseStock(String id, int quantity) async {
    final product = await (select(products)
        ..where((p) => p.id.equals(id)))
        .getSingle();
    await (update(products)..where((p) => p.id.equals(id)))
        .write(ProductsCompanion(
          stock:     Value(product.stock + quantity),
          updatedAt: Value(DateTime.now()),
          isSynced:  const Value(false),
        ));
  }

  Future<List<Product>> getUnsynced() =>
      (select(products)..where((p) => p.isSynced.equals(false))).get();

  Future<void> markSynced(String id) =>
      (update(products)..where((p) => p.id.equals(id)))
          .write(const ProductsCompanion(isSynced: Value(true)));
}
