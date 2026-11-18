import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🛒 Do'kon / Bar"),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront, size: 64, color: AppColors.success),
            SizedBox(height: 16),
            Text("Do'kon moduli — tez kunda", style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
