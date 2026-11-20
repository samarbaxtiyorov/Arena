// ============================================
// Champion POS — Official Brand Logo Widget
// Oltin Kubok, G'alaba va Nufuzli Sport Tizimi
// ============================================

import 'package:flutter/material.dart';

class ChampionLogo extends StatelessWidget {
  final double size;
  final bool showBadge;
  final double borderRadius;

  const ChampionLogo({
    super.key,
    this.size = 56,
    this.showBadge = false,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.25),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.08),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: size * 0.15,
            offset: Offset(0, size * 0.05),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 1),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Asosiy rasm (Yuqori aniqlikdagi 3D Oltin Kubok Logotipi)
            Image.asset(
              'assets/images/champion_logo.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback: Agar rasm yuklanmasa ham chiroyli oltin vektorli kubok chiqadi
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFDE68A), Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.white,
                        size: size * 0.62,
                      ),
                    ),
                  ),
                );
              },
            ),

            // 2. Ixtiyoriy yaltiroq chegara nuri
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size * 0.45,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
