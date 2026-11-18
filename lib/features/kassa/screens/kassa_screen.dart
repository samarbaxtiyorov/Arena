import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class KassaScreen extends StatelessWidget {
  const KassaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧾 Kassa'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.point_of_sale, size: 64, color: AppColors.info),
            SizedBox(height: 16),
            Text('Kassa moduli — tez kunda', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
