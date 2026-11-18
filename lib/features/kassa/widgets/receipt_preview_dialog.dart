// ============================================
// Arena — Termal Chek Ko'rish Modali
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';

class ReceiptPreviewDialog extends StatelessWidget {
  final String receiptText;

  const ReceiptPreviewDialog({super.key, required this.receiptText});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sarlavha
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.receipt_long,
                          color: AppColors.primary, size: 22),
                      Gap(8),
                      Text(
                        'Termal Chek (58mm)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const Gap(12),

              // Qog'oz chek ko'rinishi (Thermal Paper)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC), // Oq-kulrang termal qog'oz
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SelectableText(
                      receiptText,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.35,
                        color: Color(0xFF0F172A), // To'q termal bosma siyoh
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(8),
                    // Shtrix-kod simulyatsiyasi
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                              color: Colors.black.withOpacity(0.3), width: 1),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '||||| |||| |||||| ||||| ||||',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            letterSpacing: 2,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Gap(16),

              // Tugmalar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Nusxa olish'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: receiptText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Chek matni nusxalandi!'),
                            backgroundColor: AppColors.success,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      icon: const Icon(Icons.print, size: 16),
                      label: const Text('Chop etish'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'ESC/POS termal printerga buyruq yuborildi!'),
                            backgroundColor: AppColors.info,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
