// ============================================
// Arena — Ranglar Palitrasi (Skrinshotlar 1:1)
// Clean Premium Light SaaS + Dark Arxiv
// ============================================

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Asosiy fon va yuzalar ────────────────────
  static const Color background     = Color(0xFFF8FAFC); // Yorug' nozik fon
  static const Color surface        = Color(0xFFFFFFFF); // Sof oq karta
  static const Color surfaceAlt     = Color(0xFFF1F5F9); // Ikkinchi darajali och kulrang
  static const Color surfaceBorder  = Color(0xFFE2E8F0); // Yupqa chegara

  // ── To'q ranglar (Boshliq kartasi va Arxiv) ──
  static const Color darkBackground = Color(0xFF070B14); // Arxiv eng to'q fon
  static const Color darkSurface    = Color(0xFF0F172A); // Arxiv karta foni
  static const Color darkSurfaceAlt = Color(0xFF1E293B); // Arxiv ikkinchi daraja
  static const Color darkBorder     = Color(0xFF334155); // Arxiv chegara

  // ── Asosiy Accent rangi (Arena Blue) ─────────
  static const Color primary        = Color(0xFF2563EB); // Jonli ko'k
  static const Color primaryLight   = Color(0xFF3B82F6);
  static const Color primaryPill    = Color(0xFFDBEAFE); // Navbar tanlangan fon (#DBEAFE)
  static const Color primaryGlow    = Color(0x262563EB);

  // ── Status va Metrika ranglari ───────────────
  static const Color success        = Color(0xFF10B981); // Emerald yashil
  static const Color successLight   = Color(0xFFD1FAE5);
  static const Color successGlow    = Color(0x3310B981);

  static const Color warning        = Color(0xFFF59E0B); // Tilla / Amber
  static const Color warningLight   = Color(0xFFFEF3C7);
  static const Color priceGold      = Color(0xFFD97706); // Tovarlar narxi (sariq-oltin)

  static const Color danger         = Color(0xFFEF4444); // Qizil
  static const Color dangerLight    = Color(0xFFFEE2E2);

  static const Color info           = Color(0xFF06B6D4); // Moviy / Cyan neon
  static const Color neonCyan       = Color(0xFF22D3EE); // 00:00:08 taymer rangi

  // ── Matn ranglari ────────────────────────────
  static const Color textPrimary    = Color(0xFF0F172A); // To'q slate (oq fonda)
  static const Color textSecondary  = Color(0xFF64748B); // Yumshoq kulrang
  static const Color textDisabled   = Color(0xFF94A3B8); // O'chiq

  static const Color textDarkPrimary   = Color(0xFFF8FAFC); // Oq matn (to'q fonda)
  static const Color textDarkSecondary = Color(0xFF94A3B8);

  // ── Qarz ranglari ────────────────────────────
  static const Color debtHigh       = Color(0xFFEF4444); // 500k+
  static const Color debtMedium     = Color(0xFFF59E0B); // 100k - 500k
  static const Color debtLow        = Color(0xFF10B981); // 0 - 100k
}
