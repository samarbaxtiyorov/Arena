// ============================================
// Arena — Maydon/Stol Haqiqiy Foto Banneri
// Real suratlar: Stadion, Bilyard, PlayStation
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
        return 'assets/images/billiard_table.jpg';
      case 'ps':
        return 'assets/images/playstation_room.jpg';
      case 'tennis':
        return 'assets/images/tennis_court.jpg';
      case 'football':
      default:
        // Maydon 1 va Maydon 2 uchun turli burchakdagi tungi stadion suratlari
        if (tableIndex % 2 == 0) {
          return 'assets/images/stadium_night_2.jpg';
        }
        return 'assets/images/stadium_night_1.jpg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 155,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF0F172A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Haqiqiy Surat (Real Photography)
            Image.asset(
              _getImageAsset(),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Agar fayl topilmasa to'q gradient
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
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.65),
                  ],
                  stops: const [0.0, 0.5, 1.0],
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
                              : Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isLive
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withOpacity(0.4),
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

                      // LED Raqamli Neon Taymer
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
                            fontSize: 17,
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
                                "Stadion tayyor",
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
