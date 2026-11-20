# ⚡ Arena Boss Dashboard — Onlayn Jonli Boshqaruv Markazi

Arena sport majmualari, bilyard zallari va PlayStation klublari boshliqlari (egalari) uchun maxsus ishlab chiqilgan **Realtime Web Dashboard**.

---

## 🌟 Asosiy Imkoniyatlar:
1. **Jonli Maydonlar & Stollar Monitoringi:**
   - Qaysi stolda o'yin ketmoqda (soniyabay o'sayotgan jonli taymer va hisoblangan joriy summa).
   - Qaysi maydonlar bo'sh va yangi mijozga tayyor.
2. **Realtime WebSockets (Supabase):**
   - Kassir telefondagi Arena ilovasida o'yinni tugatishi yoki barda tovar sotishi bilan dashboardda **sahifani yangilamasdan (0 soniya kechikish bilan)** ma'lumotlar yangilanadi.
   - Har bir to'lovda yoqimli kassa ohangi (Chime sound) yangraydi va xabarnoma chiqadi.
   - 100 000 so'mdan katta to'lovlarda ekranda konfeti otiladi.
3. **Moliya & Analitika (Chart.js):**
   - Bugungi soatbay tushum grafigi.
   - To'lov turlari taqsimoti (Naqd pul, Karta/Click/Payme, Nasiya).
4. **Nasiya va Qarzdorlar:**
   - Eng ko'p qarzdor mijozlar ro'yxati va ularning balansi.
5. **Moslashuvchan Dizayn (Ultra-Responsive):**
   - Telefon (iOS / Android) brauzerlarida.
   - Planshet (iPad / Android Tablet) ekranlarida.
   - Noutbuk va Katta kompyuter monitorlarida chiroyli ochiladi.

---

## 🚀 Ishga Tushirish:

### 1-usul: Terminal orqali (eng tezkor):
```bash
./run_dashboard.sh
```
yoki:
```bash
cd dashboard && python3 serve.py
```
Brauzerda quyidagi manzil ochiladi:
- Kompyuterda: `http://localhost:3000`
- Bir xil WiFi'dagi telefonda: `http://<SIZNING_IP>:3000`

### 2-usul: Internetga (Bulutga) tekin joylash:
Ushbu `dashboard/` papkasini [Vercel](https://vercel.com), [Netlify](https://netlify.com) yoki [Cloudflare Pages](https://pages.cloudflare.com) ga drag-and-drop qilsangiz, internet orqali istalgan joydan `https://sizning-arenangiz.vercel.app` orqali ochiladi!
