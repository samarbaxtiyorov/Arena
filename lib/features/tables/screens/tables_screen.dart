import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TablesScreen extends StatelessWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎱 Zallar & Stollar'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_restaurant, size: 64, color: AppColors.primary),
            SizedBox(height: 16),
            Text('Zallar moduli — tez kunda', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
