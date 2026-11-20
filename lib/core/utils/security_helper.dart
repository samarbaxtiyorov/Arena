// ============================================
// Arena — Xavfsizlik va Kriptografiya Utilitasi
// SHA-256 xeshlash, parollar xavfsizligi va himoya
// ============================================

import 'dart:convert';
import 'package:crypto/crypto.dart';

class SecurityHelper {
  SecurityHelper._();

  static const String _salt = 'arena_venue_secure_salt_2026';

  /// Parolni SHA-256 va maxfiy tuz (salt) bilan xesh qilish
  static String hashPassword(String password) {
    if (password.trim().isEmpty) return '';
    final bytes = utf8.encode('$_salt:${password.trim()}');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Berilgan qiymat 64 belgili SHA-256 xesh ekanligini aniqlash
  static bool isHashed(String value) {
    final hexRegex = RegExp(r'^[a-f0-9]{64}$');
    return hexRegex.hasMatch(value.trim());
  }

  /// Kiritilgan parolni saqlangan xesh yoki eski parol bilan tekshirish
  static bool verifyPassword(String inputPassword, String storedHashOrPassword) {
    if (storedHashOrPassword.trim().isEmpty) return false;

    // 1. Yangi SHA-256 xesh bilan solishtirish
    final inputHash = hashPassword(inputPassword);
    if (inputHash == storedHashOrPassword) {
      return true;
    }

    // 2. Eskiroq hisoblar uchun ochiq matnli parolni tekshirish (Backward-compatibility)
    if (inputPassword.trim() == storedHashOrPassword.trim()) {
      return true;
    }

    return false;
  }
}
