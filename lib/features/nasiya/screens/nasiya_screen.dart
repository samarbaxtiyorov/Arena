import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class NasiyaScreen extends StatelessWidget {
  const NasiyaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📒 Nasiya Daftari'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book, size: 64, color: AppColors.warning),
            SizedBox(height: 16),
            Text('Nasiya moduli — tez kunda', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
