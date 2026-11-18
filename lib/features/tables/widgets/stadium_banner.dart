// ============================================
// Arena — Maydon/Stol Banneri (Floodlit Stadium)
// Skrinshot 6 dagi tungi stadion va LED taymer
// ============================================

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class StadiumBanner extends StatelessWidget {
  final bool isLive;
  final String timerString;
  final String type;

  const StadiumBanner({
    super.key,
    required this.isLive,
    required this.timerString,
    this.type = 'football',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF0F172A),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Fon stadioni rasmi / gradienti
            Positioned.fill(
              child: CustomPaint(
                painter: StadiumNightPainter(type: type),
              ),
            ),

            // Qoraytirilgan qatlam
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),

            // Banner ichidagi ko'rsatkichlar
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Jonli vaqt ko'rsatkichi
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLive
                              ? const Color(0xFF10B981)
                              : const Color(0xFF475569).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                            const Gap(6),
                            Text(
                              isLive ? 'JONLI VAQT' : 'TO\'XTATILGAN',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // LED Raqamli Taymer (Neon Cyan)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF050B14).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF22D3EE).withOpacity(0.5),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF22D3EE).withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Text(
                          timerString,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF22D3EE),
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Pastki qism: Stadion chiroqlari yoki maydon ramzi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        type == 'football'
                            ? Icons.sports_soccer
                            : (type == 'billiard'
                                ? Icons.sports_baseball
                                : Icons.sports_esports),
                        color: Colors.white.withOpacity(0.25),
                        size: 30,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Haqiqiy stadion atmosferasini chizuvchi maxsus painter
class StadiumNightPainter extends CustomPainter {
  final String type;
  StadiumNightPainter({this.type = 'football'});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Tungi osmon va projektor nurlari
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0B1329), Color(0xFF1E293B)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.6));

    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.6), skyPaint);

    // Projektor nurlari (Floodlights)
    final lightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.7, -0.6),
        radius: 0.8,
        colors: [
          Colors.white.withOpacity(0.4),
          const Color(0xFF38BDF8).withOpacity(0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.2),
        size.width * 0.45, lightPaint);

    final lightPaint2 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.7, -0.6),
        radius: 0.8,
        colors: [
          Colors.white.withOpacity(0.4),
          const Color(0xFF38BDF8).withOpacity(0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.2),
        size.width * 0.45, lightPaint2);

    // 2. Yashil maysa (Football pitch) yoki Bilyard movut / Zali
    Color pitchTopColor = const Color(0xFF15803D);
    Color pitchBottomColor = const Color(0xFF166534);

    if (type == 'billiard') {
      pitchTopColor = const Color(0xFF047857);
      pitchBottomColor = const Color(0xFF064E3B);
    } else if (type == 'ps') {
      pitchTopColor = const Color(0xFF1E3A8A);
      pitchBottomColor = const Color(0xFF1E1B4B);
    }

    final pitchPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [pitchTopColor, pitchBottomColor],
      ).createShader(
        Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45),
      );

    final path = Path()
      ..moveTo(0, size.height * 0.55)
      ..lineTo(size.width, size.height * 0.55)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, pitchPaint);

    // Maydon chiziqlari (Oq chiziqlar)
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(0, size.height * 0.65),
      Offset(size.width, size.height * 0.65),
      linePaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.78),
      size.width * 0.2,
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
