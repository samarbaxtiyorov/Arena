// ============================================
// Arena — Maydon/Stol Haqiqiy Foto Banneri
// Desktopdagi Arena_Rasmlar to'plamidan real suratlar
// LED Neon Taymer va Jonli Vaqt nishoni
// ============================================

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class StadiumBanner extends StatelessWidget {
  final bool isLive;
  final String timerString;
  final String type;
  final int tableIndex;

  const StadiumBanner({
    super.key,
    required this.isLive,
    required this.timerString,
    this.type = 'football',
    this.tableIndex = 1,
  });

  String _getImageAsset() {
    switch (type) {
      case 'billiard':
        return isLive
            ? 'assets/images/billiard_active.jpg'
            : (tableIndex % 2 == 0
                ? 'assets/images/billiard_table_balls.jpg'
                : 'assets/images/billiard_table.jpg');
      case 'tennis':
      case 'table_tennis':
        return 'assets/images/table_tennis.jpg';
      case 'ps':
      case 'playstation':
        return 'assets/images/vr_zone.jpg';
      case 'bowling':
        return 'assets/images/bowling.jpg';
      case 'cinema':
        return 'assets/images/cinema.jpg';
      case 'karaoke':
        return 'assets/images/karaoke.jpg';
      case 'badminton':
        return 'assets/images/badminton.jpg';
      case 'playground':
        return 'assets/images/playground.jpg';
      case 'football':
      default:
        return 'assets/images/football_pitch.jpg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF0F172A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Haqiqiy Professional Surat (Arena_Rasmlar)
            Image.asset(
              _getImageAsset(),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.sports_soccer, color: Colors.white24, size: 48),
                  ),
                );
              },
            ),

            // 2. Qoraytirilgan gradient (matnlar o'qilishi uchun)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.12),
                    Colors.black.withOpacity(0.68),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // 3. Banner ustidagi interfeys elementlari
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Jonli Vaqt ko'rsatkichi
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isLive
                              ? const Color(0xFF10B981)
                              : Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isLive
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withOpacity(0.45),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isLive ? Colors.white : const Color(0xFF94A3B8),
                              ),
                            ),
                            const Gap(6),
                            Text(
                              isLive ? 'JONLI VAQT' : "KUTILMOQDA",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: isLive ? Colors.white : const Color(0xFFCBD5E1),
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // LED Raqamli Neon Taymer (Skrinshot 6 bilan 1:1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF030712).withOpacity(0.88),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isLive
                                ? const Color(0xFF22D3EE)
                                : const Color(0xFF334155),
                            width: 1.2,
                          ),
                          boxShadow: isLive
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF22D3EE).withOpacity(0.35),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          timerString,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isLive
                                ? const Color(0xFF22D3EE)
                                : const Color(0xFF94A3B8),
                            letterSpacing: 2.2,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Pastki ramz (faqat bo'sh bo'lganda nozik ko'rinadi)
                  if (!isLive)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.sports_soccer_rounded, color: Colors.white70, size: 16),
                              Gap(6),
                              Text(
                                "Maydon o'yinga shay",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
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
