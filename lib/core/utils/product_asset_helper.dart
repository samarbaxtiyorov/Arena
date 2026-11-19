// ============================================
// Arena — Tovar Suratlari Yordamchisi
// Do'kon POS va Ombor tovarlarining haqiqiy suratlari
// ============================================

class ProductAssetHelper {
  ProductAssetHelper._();

  static String getImageForProduct(String name) {
    final n = name.toLowerCase().trim();
    if (n.contains('cola')) {
      return 'assets/images/prod_cola.jpg';
    } else if (n.contains('fanta')) {
      return 'assets/images/prod_fanta.jpg';
    } else if (n.contains('suv') || n.contains('water') || n.contains('chortoq') || n.contains('nestle')) {
      return 'assets/images/prod_suv.jpg';
    } else if (n.contains('chips') || n.contains('lays') || n.contains('pista') || n.contains('snack')) {
      return 'assets/images/prod_chips.jpg';
    } else if (n.contains('choy') || n.contains('tea')) {
      return 'assets/images/prod_choy.jpg';
    } else if (n.contains('kofe') || n.contains('coffee') || n.contains('qahva')) {
      return 'assets/images/prod_coffee.jpg';
    }
    // Default drink/snack image
    return 'assets/images/prod_cola.jpg';
  }
}
