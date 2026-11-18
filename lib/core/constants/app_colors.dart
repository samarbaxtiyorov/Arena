// ============================================
// Arena — Rang va mavzu konstantalari
// ============================================

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Asosiy fon ranglari (Qora-Slate) ────────
  static const Color background    = Color(0xFF0A0E13); // eng qoʻyuq fon
  static const Color surface       = Color(0xFF131920); // karta foni
  static const Color surfaceAlt    = Color(0xFF1C2531); // ikkinchi daraja
  static const Color surfaceBorder = Color(0xFF263040); // chegara

  // ── Accent rangi ────────────────────────────
  static const Color primary       = Color(0xFF3B82F6); // ko'k
  static const Color primaryDark   = Color(0xFF1D4ED8);
  static const Color primaryGlow   = Color(0x333B82F6); // shaffof ko'k

  // ── Status ranglari ─────────────────────────
  static const Color success       = Color(0xFF22C55E); // yashil
  static const Color warning       = Color(0xFFF59E0B); // sariq
  static const Color danger        = Color(0xFFEF4444); // qizil
  static const Color info          = Color(0xFF06B6D4); // moviy

  // ── Matn ranglari ───────────────────────────
  static const Color textPrimary   = Color(0xFFF1F5F9); // oq
  static const Color textSecondary = Color(0xFF94A3B8); // kulrang
  static const Color textDisabled  = Color(0xFF475569); // o'chiq

  // ── Stol holatlari ──────────────────────────
  static const Color tableActive   = Color(0xFF22C55E); // mashg'ul
  static const Color tableIdle     = Color(0xFF334155); // bo'm-bo'sh
  static const Color tablePaused   = Color(0xFFF59E0B); // pauza

  // ── Nasiya ranglari ─────────────────────────
  static const Color debtHigh      = Color(0xFFEF4444); // 500k+
  static const Color debtMedium    = Color(0xFFF59E0B); // 100-500k
  static const Color debtLow       = Color(0xFF22C55E); // 0-100k
}
