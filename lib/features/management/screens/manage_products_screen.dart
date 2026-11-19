// ============================================
// Arena — Ombor va Mahsulotlar Boshqaruv Sahifasi
// Haqiqiy mahsulot suratlari, toifalar, shtrix-kod skaneri,
// qoldiq hisobi va zaxira kiritish (kirim/prikhod)
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/product_asset_helper.dart';
import '../../../data/local/app_database.dart';
import '../../shop/providers/shop_providers.dart';
import '../../shop/widgets/add_product_dialog.dart';
import '../../shop/widgets/barcode_scan_dialog.dart';

class ManageProductsScreen extends ConsumerStatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  ConsumerState<ManageProductsScreen> createState() =>
      _ManageProductsScreenState();
}

class _ManageProductsScreenState extends ConsumerState<ManageProductsScreen> {
  String _selectedCategory = 'all';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddOrEdit([Product? product]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddProductDialog(productToEdit: product),
    );
  }

  Future<void> _scanBarcode() async {
    final scanned = await showDialog<String>(
      context: context,
      builder: (_) => const BarcodeScanDialog(),
    );
    if (scanned != null && scanned.isNotEmpty) {
      setState(() {
        _searchController.text = scanned;
        _searchQuery = scanned.toLowerCase().trim();
      });
    }
  }

  // Tezkor zaxira (Kirim) qo'shish dialogi
  void _showAddStockDialog(Product product) {
    final countController = TextEditingController(text: '10');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_shopping_cart_rounded,
                  color: Color(0xFF059669), size: 22),
            ),
            const Gap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    "Omborga kirim qilish (Zaxira qo'shish)",
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hozirgi mavjud qoldiq: ${product.stock} dona",
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569)),
            ),
            const Gap(14),
            TextField(
              controller: countController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF059669),
              ),
              decoration: InputDecoration(
                labelText: "Qo'shiladigan miqdor",
                suffixText: "dona",
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const Gap(12),
            // Tezkor tanlash chiplari
            Wrap(
              spacing: 8,
              children: [5, 10, 20, 50].map((qty) {
                return ActionChip(
                  label: Text("+$qty"),
                  labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF059669)),
                  backgroundColor: const Color(0xFFECFDF5),
                  side: const BorderSide(color: Color(0xFFA7F3D0)),
                  onPressed: () {
                    countController.text = qty.toString();
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Bekor qilish"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final qty = int.tryParse(countController.text.trim()) ?? 0;
              if (qty > 0) {
                await ref
                    .read(shopControllerProvider)
                    .addStock(productId: product.id, quantity: qty);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          "${product.name} ga $qty dona muvaffaqiyatli qo'shildi!"),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text("Kirim qilish"),
          ),
        ],
      ),
    );
  }

  // Tovar o'chirishni tasdiqlash
  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444), size: 24),
            ),
            const Gap(10),
            const Expanded(
              child: Text(
                "Tovarni o'chirish",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          "Rostdan ham \"${product.name}\" tovarini ombordan o'chirmoqchimisiz? Uni qayta tiklab bo'lmaydi.",
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Bekor qilish"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              await ref.read(shopControllerProvider).deleteProduct(product.id);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${product.name} ombordan o'chirildi!"),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text("Ha, o'chirish"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);
    final allProducts = productsAsync.value ?? [];

    // Hisob-kitoblar
    final totalProducts = allProducts.length;
    final totalStockQty = allProducts.fold(0, (sum, p) => sum + p.stock);
    final totalStockValue =
        allProducts.fold(0, (sum, p) => sum + (p.stock * p.price));
    final lowStockCount = allProducts.where((p) => p.stock <= 5).length;

    // Filter
    final filtered = allProducts.where((p) {
      final nameLower = p.name.toLowerCase();
      // Toifa
      if (_selectedCategory != 'all') {
        if (_selectedCategory == 'drink') {
          final isDrink = p.category == 'drink' ||
              nameLower.contains('cola') ||
              nameLower.contains('fanta') ||
              nameLower.contains('suv') ||
              nameLower.contains('pepsi') ||
              nameLower.contains('sharbat');
          if (!isDrink) return false;
        } else if (_selectedCategory == 'energy') {
          final isEnergy = p.category == 'energy' ||
              nameLower.contains('flash') ||
              nameLower.contains('redbull') ||
              nameLower.contains('gorilla') ||
              nameLower.contains('monster');
          if (!isEnergy) return false;
        } else if (_selectedCategory == 'snack') {
          final isSnack = p.category == 'snack' ||
              nameLower.contains('chips') ||
              nameLower.contains('lays') ||
              nameLower.contains('pista') ||
              nameLower.contains('shokolad');
          if (!isSnack) return false;
        } else if (_selectedCategory == 'coffee') {
          final isCoffee = p.category == 'coffee' ||
              nameLower.contains('choy') ||
              nameLower.contains('kofe') ||
              nameLower.contains('coffee') ||
              nameLower.contains('tea');
          if (!isCoffee) return false;
        } else if (p.category != _selectedCategory) {
          return false;
        }
      }

      // Qidiruv
      if (_searchQuery.isNotEmpty) {
        final matchesName = nameLower.contains(_searchQuery);
        final matchesBarcode =
            p.barcode != null && p.barcode!.contains(_searchQuery);
        if (!matchesName && !matchesBarcode) return false;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ombor va Mahsulotlar",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              "Jami: $totalProducts xil tovar ($totalStockQty dona)",
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _openAddOrEdit(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                "Yangi Tovar",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Yuqori Statistika Kartalari ──────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                _buildStatCard(
                  title: "Ombor Qiymati",
                  value: formatSum(totalStockValue),
                  color: const Color(0xFF059669),
                  bgColor: const Color(0xFFECFDF5),
                  icon: Icons.account_balance_wallet_outlined,
                ),
                const Gap(8),
                _buildStatCard(
                  title: "Jami Mahsulot",
                  value: "$totalStockQty dona",
                  color: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                  icon: Icons.inventory_2_outlined,
                ),
                const Gap(8),
                _buildStatCard(
                  title: "Kam Qolgan",
                  value: "$lowStockCount xil",
                  color: lowStockCount > 0
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF64748B),
                  bgColor: lowStockCount > 0
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFF1F5F9),
                  icon: Icons.warning_amber_rounded,
                ),
              ],
            ),
          ),

          // ── Qidiruv va Skaner Maydoni ───────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.toLowerCase().trim();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Tovar nomi yoki shtrix-kod...",
                      hintStyle: const TextStyle(
                          fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 20, color: Color(0xFF64748B)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const Gap(10),
                // Shtrix-kod skaner tugmasi
                InkWell(
                  onTap: _scanBarcode,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Toifalar Chiplari ──────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildCategoryChip('all', "Barchasi ($totalProducts)"),
                  const Gap(8),
                  _buildCategoryChip('drink', "🥤 Ichimliklar"),
                  const Gap(8),
                  _buildCategoryChip('energy', "⚡ Energetiklar"),
                  const Gap(8),
                  _buildCategoryChip('snack', "🍫 Gazaklar"),
                  const Gap(8),
                  _buildCategoryChip('coffee', "☕ Choy & Qahva"),
                  const Gap(8),
                  _buildCategoryChip('other', "📦 Boshqa"),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // ── Mahsulotlar Ro'yxati ───────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: Color(0xFF059669),
                          ),
                        ),
                        const Gap(16),
                        const Text(
                          "Mahsulot topilmadi",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const Gap(6),
                        const Text(
                          "Yangi mahsulot qo'shish uchun yuqoridagi tugmani bosing",
                          style:
                              TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          textAlign: TextAlign.center,
                        ),
                        const Gap(16),
                        ElevatedButton.icon(
                          onPressed: () => _openAddOrEdit(),
                          icon: const Icon(Icons.add),
                          label: const Text("Yangi tovar qo'shish"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Gap(12),
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      final isLowStock = product.stock <= 5;
                      final isOutOfStock = product.stock <= 0;
                      final imageAsset =
                          ProductAssetHelper.getImageForProduct(product.name);

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isOutOfStock
                                ? const Color(0xFFFCA5A5)
                                : (isLowStock
                                    ? const Color(0xFFFCD34D)
                                    : const Color(0xFFE2E8F0)),
                            width: (isOutOfStock || isLowStock) ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // 1. Tovar Rasmi
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 68,
                                height: 68,
                                color: const Color(0xFFF1F5F9),
                                child: Image.asset(
                                  imageAsset,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.fastfood_rounded,
                                    size: 32,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ),

                            const Gap(12),

                            // 2. Tovar Ma'lumotlari
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Gap(4),
                                  Row(
                                    children: [
                                      Text(
                                        formatSum(product.price),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                      const Gap(8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isOutOfStock
                                              ? const Color(0xFFFEE2E2)
                                              : (isLowStock
                                                  ? const Color(0xFFFEF3C7)
                                                  : const Color(0xFFECFDF5)),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isOutOfStock
                                              ? "Tugagan"
                                              : "${product.stock} dona",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: isOutOfStock
                                                ? const Color(0xFFDC2626)
                                                : (isLowStock
                                                    ? const Color(0xFFB45309)
                                                    : const Color(0xFF047857)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (product.barcode != null &&
                                      product.barcode!.isNotEmpty) ...[
                                    const Gap(4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.qr_code_2_rounded,
                                          size: 14,
                                          color: Color(0xFF94A3B8),
                                        ),
                                        const Gap(4),
                                        Text(
                                          product.barcode!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF64748B),
                                            letterSpacing: 0.8,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const Gap(8),

                            // 3. Amallar tugmalari
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Kirim qilish tugmasi
                                ElevatedButton.icon(
                                  onPressed: () => _showAddStockDialog(product),
                                  icon: const Icon(Icons.add_rounded, size: 14),
                                  label: const Text(
                                    "Kirim",
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFECFDF5),
                                    foregroundColor: const Color(0xFF059669),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: const BorderSide(
                                          color: Color(0xFFA7F3D0)),
                                    ),
                                  ),
                                ),
                                const Gap(6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Tahrirlash
                                    InkWell(
                                      onTap: () => _openAddOrEdit(product),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: const Color(0xFFBFDBFE)),
                                        ),
                                        child: const Icon(
                                          Icons.edit_outlined,
                                          color: Color(0xFF2563EB),
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                    const Gap(6),
                                    // O'chirish
                                    InkWell(
                                      onTap: () => _confirmDelete(product),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF2F2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: const Color(0xFFFECACA)),
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Color(0xFFEF4444),
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 14),
                const Gap(4),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Gap(4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String key, String title) {
    final isSelected = _selectedCategory == key;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = key),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF059669) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
