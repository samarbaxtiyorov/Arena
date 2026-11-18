# 🏟️ Arena

**Arena** — sport va o'yin zallari uchun professional, offline-first boshqaruv tizimi.

> Bilyard · Futbol · PlayStation · Tennis · Do'kon · Kassa

---

## 👨‍💻 Dasturchi

**Samar Baxtiyorov** — Jeyda, Qashqadaryo  
📧 oqdwer@gmail.com

---

## 📱 Platformalar

| Platform | Holat |
|----------|-------|
| Android (planshet / telefon) | ✅ |
| Linux Desktop | ✅ |

---

## 🏗️ Arxitektura

```
Offline-first (SQLite / Drift)
         ↕  avtomatik sinxronizatsiya
Supabase Cloud (PostgreSQL)
```

- **UI**: Flutter + Material 3 (Qora-Slate mavzu)
- **Lokal baza**: Drift (SQLite)
- **Bulut**: Supabase (real-time + REST)
- **Holat boshqaruvi**: Riverpod

---

## 📦 Modullar

| # | Modul | Tavsif |
|---|-------|--------|
| 1 | 🎱 Zallar & Stollar | Taymer, narxlar, split, chiroq |
| 2 | 📒 Nasiya Daftari | Mijozlar, qarz, to'lovlar |
| 3 | 🛒 Do'kon / Bar | Tovarlar, savdo, shtrix-kod |
| 4 | 🧾 Kassa & Chek | Kunlik kassa, ESC/POS chek |

---

## 🚀 Ishga tushirish

```bash
flutter pub get
flutter run -d linux     # Desktop
flutter run -d android   # Android
```

---

*Arena v0.1.0 — Noyabr 2026*
