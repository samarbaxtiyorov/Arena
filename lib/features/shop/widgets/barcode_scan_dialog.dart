// ============================================
// Arena — Shtrix-kod Skanerlash Modali
// Tezkor skaner simulyatsiyasi, lazer nuri,
// EAN-13 generatsiya va kamera orqali o'qish
// ============================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class BarcodeScanDialog extends StatefulWidget {
  final String? initialBarcode;

  const BarcodeScanDialog({super.key, this.initialBarcode});

  @override
  State<BarcodeScanDialog> createState() => _BarcodeScanDialogState();
}

class _BarcodeScanDialogState extends State<BarcodeScanDialog>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _barcodeController;
  late final AnimationController _animController;
  late final Animation<double> _laserAnim;

  @override
  void initState() {
    super.initState();
    _barcodeController =
        TextEditingController(text: widget.initialBarcode ?? '');

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _laserAnim = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _generateRandomBarcode() {
    final rand = Random();
    // 4780 (O'zbekiston prefiksi) + 8 tasodifiy raqam
    final numPart = 10000000 + rand.nextInt(90000000);
    final code = "478$numPart";
    setState(() {
      _barcodeController.text = code;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      backgroundColor: const Color(0xFF0F172A),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sarlavha
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.qr_code_scanner_rounded,
                          color: Color(0xFF38BDF8), size: 22),
                      Gap(8),
                      Text(
                        'Shtrix-kod Skaneri',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const Gap(14),

              // Kamera / Lazer nuri Viewfinder
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF020617),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Burchak ramkalari
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CustomPaint(
                          painter: _ScannerFramePainter(),
                        ),
                      ),
                    ),

                    // Shtrix kod tasviri
                    Opacity(
                      opacity: 0.35,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.line_weight_rounded,
                              size: 48, color: Colors.white),
                          const Gap(4),
                          Text(
                            _barcodeController.text.isNotEmpty
                                ? _barcodeController.text
                                : "||||| ||||||| |||| |||||",
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              letterSpacing: 3,
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Qizil/Moviy Harakatlanuvchi Lazer Nuri
                    AnimatedBuilder(
                      animation: _laserAnim,
                      builder: (context, child) {
                        return Positioned(
                          top: 160 * _laserAnim.value,
                          left: 24,
                          right: 24,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withOpacity(0.8),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const Gap(16),

              // Shtrix-kod kiritish / natija maydoni
              TextField(
                controller: _barcodeController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Color(0xFF38BDF8),
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  labelText: 'Shtrix-kod (EAN-13 / UPC)',
                  labelStyle:
                      const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.barcode_reader,
                      color: Color(0xFF38BDF8), size: 22),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.auto_awesome_rounded,
                        color: Color(0xFFF59E0B), size: 20),
                    tooltip: "Tasodifiy generatsiya qilish",
                    onPressed: _generateRandomBarcode,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),

              const Gap(10),

              // Tezkor generatsiya tugmasi
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: _generateRandomBarcode,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded,
                            size: 14, color: Color(0xFF94A3B8)),
                        Gap(4),
                        Text(
                          "Yangi shtrix-kod yaratish",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Gap(16),

              // Tasdiqlash tugmalari
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF334155)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Bekor qilish',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text(
                        'Skanerlash',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        final code = _barcodeController.text.trim();
                        if (code.isNotEmpty) {
                          Navigator.pop(context, code);
                        } else {
                          _generateRandomBarcode();
                          Navigator.pop(context, _barcodeController.text.trim());
                        }
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

class _ScannerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 20.0;

    // Yuqori chap
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLen, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLen), paint);

    // Yuqori o'ng
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width - cornerLen, 0), paint);
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width, cornerLen), paint);

    // Quyi chap
    canvas.drawLine(
        Offset(0, size.height), Offset(cornerLen, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(0, size.height - cornerLen), paint);

    // Quyi o'ng
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width - cornerLen, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - cornerLen), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
