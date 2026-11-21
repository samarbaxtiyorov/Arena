// ============================================
// Arena POS — Yordam va Qo'llanma Sahifasi
// Bosh dasturchi: Samar Baxtiyorov (@Samar_Baxtiyorov)
// Tel: +998 91 634 61 85
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/arena_logo.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openTelegram() async {
    final uri = Uri.parse('https://t.me/Samar_Baxtiyorov');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _copyToClipboard('@Samar_Baxtiyorov', 'Telegram username nusxalandi');
    }
  }

  Future<void> _makeCall() async {
    final uri = Uri.parse('tel:+998916346185');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _copyToClipboard('+998916346185', 'Telefon raqam nusxalandi');
    }
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const Gap(10),
            Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 750;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Row(
          children: [
            ArenaLogo(size: 32, borderRadius: 8),
            Gap(10),
            Text(
              "Yordam va Qo'llanma",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 900 : double.infinity),
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 16,
              vertical: 20,
            ),
            children: [
              // ── 1. BOSH DASTURCHI KARTASI ──────────────────────
              _buildDeveloperCard(isDesktop),

              const Gap(24),

              // ── 2. QIDIRUV MAYDONI ─────────────────────────────
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Savol yoki mavzuni qidiring (masalan: PIN, chek, stol...)",
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2563EB)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                  ),
                ),
              ),

              const Gap(24),

              // ── 3. QADAM-BA-QADAM QO'LLANMALAR (FAQ) ───────────
              const Row(
                children: [
                  Icon(Icons.menu_book_rounded, color: Color(0xFF2563EB), size: 20),
                  Gap(8),
                  Text(
                    "Foydalanish bo'yicha qo'llanmalar",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const Gap(12),

              ..._buildFaqList(),

              const Gap(24),

              // ── 4. ILOVA HAQIDA VA LITSENZIYA ───────────────────
              _buildAppInfoCard(),

              const Gap(32),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // Dasturchi va Texnik Ko'mak Vizitkasi
  // ============================================
  Widget _buildDeveloperCard(bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    "SB",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            "Samar Baxtiyorov",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Gap(6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
                          ),
                          child: const Text(
                            "Muallif",
                            style: TextStyle(
                              color: Color(0xFF34D399),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(2),
                    const Text(
                      "Arena POS bosh dasturchisi va asoschisi",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Gap(4),
                    const Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 13, color: Color(0xFF38BDF8)),
                        Gap(4),
                        Text(
                          "O'zbekiston, Qashqadaryo (Jeyda)",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF38BDF8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Gap(20),
          const Divider(color: Color(0xFF334155), height: 1),
          const Gap(18),

          const Text(
            "Savollar, xatoliklar, maxsus buyurtmalar yoki dasturni sozlash bo'yicha bevosita muallifga bog'lanishingiz mumkin:",
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFCBD5E1),
              height: 1.4,
            ),
          ),

          const Gap(16),

          // Tezkor Aloqa Tugmalari (Telegram & Telefon)
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              // Telegram tugmasi
              ElevatedButton.icon(
                onPressed: _openTelegram,
                icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                label: const Text(
                  "Telegram: @Samar_Baxtiyorov",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0088CC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),

              // Telefon tugmasi
              ElevatedButton.icon(
                onPressed: _makeCall,
                icon: const Icon(Icons.phone_rounded, size: 16, color: Colors.white),
                label: const Text(
                  "+998 91 634 61 85",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),

              // Raqamni nusxalash
              OutlinedButton.icon(
                onPressed: () => _copyToClipboard('+998916346185', 'Telefon raqam nusxalandi'),
                icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFFCBD5E1)),
                label: const Text(
                  "Nusxa olish",
                  style: TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF475569)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // Foydalanish Qo'llanmalari (FAQ Ro'yxati)
  // ============================================
  List<Widget> _buildFaqList() {
    final allGuides = [
      _FaqItem(
        icon: Icons.sports_soccer_rounded,
        iconColor: const Color(0xFF10B981),
        title: "Stol yoki Maydonda o'yinni boshlash qanday ishlaydi?",
        content:
            "1. Asosiy ekrandagi bo'sh stol kartasidagi 'Boshlash' tugmasini bosing.\n"
            "2. O'yinni boshlash bo'yicha tasdiqlash oynasi chiqadi — tasdiqlang.\n"
            "3. O'yin vaqti va summasi sekundiga aniq hisoblanib boradi.\n\n"
            "🛡 1 daqiqalik bepul kafolat: Agar adashib bosib yuborgan bo'lsangiz, 1 daqiqa ichida to'xtatsangiz tizim 0 so'm hisoblaydi.",
      ),
      _FaqItem(
        icon: Icons.receipt_long_rounded,
        iconColor: const Color(0xFF2563EB),
        title: "O'yinni to'xtatish va kassa chekini chiqarish",
        content:
            "1. Band stol kartasidagi 'To'xtatish' tugmasini bosing.\n"
            "2. Yakuniy oynada o'yin vaqti, stol narxi va buyurtma qilingan bar mahsulotlari ko'rsatiladi.\n"
            "3. To'lov turini tanlang: Naqd pul, Karta yoki Nasiya (Qarz daftariga yozish).\n"
            "4. 'To'lovni tasdiqlash' tugmasi bosilganda avtomatik kassa cheki shakllanadi va chop etiladi.",
      ),
      _FaqItem(
        icon: Icons.local_bar_rounded,
        iconColor: const Color(0xFFF59E0B),
        title: "Stolga bar mahsulotlari (choy, kola, chips) qo'shish",
        content:
            "1. Band stol ustidagi 'Buyurtma' (Savat) tugmasini bosing.\n"
            "2. Bar vitrinasidan mijoz olgan mahsulotlarni tanlang va miqdorini belgilang.\n"
            "3. Qo'shilgan tovarlar stolning umumiy hisobiga yoziladi va o'yin to'xtatilganda bitta chekda birga chiqadi.",
      ),
      _FaqItem(
        icon: Icons.badge_rounded,
        iconColor: const Color(0xFF9333EA),
        title: "Kassirlar va yangi xodim qo'shish tartibi",
        content:
            "1. Boshqaruv markazidan 'Xodimlar va Kassirlar' bo'limiga o'ting.\n"
            "2. 'Yangi xodim qo'shish' tugmasini bosing, ismini va 4 xonali shaxsiy PIN-kodini kiriting.\n"
            "3. Kassir o'z PIN-kodi orqali kirganda faqat stollarni boshqara oladi, umumiy kassa foydasi va biznes sozlamalarini o'zgartira olmaydi.",
      ),
      _FaqItem(
        icon: Icons.lock_rounded,
        iconColor: const Color(0xFFEF4444),
        title: "PIN-kod tizimi va xavfsizlik (Bank uslubida)",
        content:
            "1. Arena POS dasturi yopilib qayta ochilganda begona shaxslar ko'rmasligi uchun darhol 4 xonali PIN so'raydi.\n"
            "2. Kompyuterda ishlayotganda klaviaturaning raqamlari (0-9) orqali terish mumkin.\n"
            "3. Agar PIN-kod esdan chiqsa: Pastdagi 'Boshqa hisobga o'tish / Parol bilan kirish' tugmasini bosib, Boshliqning asosiy login va paroli orqali tizimga qayta kirib, PIN-kodni yangilash mumkin.",
      ),
      _FaqItem(
        icon: Icons.cloud_done_rounded,
        iconColor: const Color(0xFF06B6D4),
        title: "Internet o'chib qolsa nima bo'ladi? (Offline rejim)",
        content:
            "Arena POS 100% to'liq oflayn ishlaydi! Internet bo'lmasa ham stollar to'xtamaydi, hisob-kitob va chek chiqarish uzluksiz davom etadi.\n\n"
            "Internet qayta ulanganda barcha yangi o'yinlar va savdolar bulut bazasiga (Supabase) avtomatik sinxronlanadi.",
      ),
      _FaqItem(
        icon: Icons.print_rounded,
        iconColor: const Color(0xFF64748B),
        title: "Chek printeri (Bluetooth / USB) ulash",
        content:
            "1. Boshqaruv markazi -> 'Biznes va Tizim Sozlamalari' bo'limiga kiring.\n"
            "2. 'Printer sozlamalari' qismidan printerning qog'oz enini (58mm yoki 80mm) tanlang.\n"
            "3. Kompyuterda tizim printeriga, telefonda esa Bluetooth orqali printerni biriktirib oling.",
      ),
    ];

    final filtered = _searchQuery.isEmpty
        ? allGuides
        : allGuides.where((g) =>
            g.title.toLowerCase().contains(_searchQuery) ||
            g.content.toLowerCase().contains(_searchQuery)).toList();

    if (filtered.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Column(
            children: [
              Icon(Icons.search_off_rounded, size: 40, color: Color(0xFF94A3B8)),
              Gap(10),
              Text(
                "So'rovingiz bo'yicha ma'lumot topilmadi",
                style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569)),
              ),
              Gap(4),
              Text(
                "Yuqoridagi Telegram tugmasi orqali dasturchiga to'g'ridan-to'g'ri murojaat qilishingiz mumkin.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ];
    }

    return filtered.map((item) => _buildFaqCard(item)).toList();
  }

  Widget _buildFaqCard(_FaqItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 20),
          ),
          title: Text(
            item.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                item.content,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // Dastur Ma'lumoti va Litsenziya Bloki
  // ============================================
  Widget _buildAppInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ArenaLogo(size: 38, borderRadius: 10),
              Gap(12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Arena POS",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    "Versiya 2.0 (Rel. 2026) • Rasmiy Nashr",
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          Gap(14),
          Divider(color: Color(0xFFF1F5F9), height: 1),
          Gap(12),
          Text(
            "Sport maydonlari, bilyard, PlayStation klublari va ko'ngilochar maskanlar uchun avtomatlashtirilgan aqlli boshqaruv tizimi.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
          ),
          Gap(8),
          Text(
            "Mualliflik huquqi: © 2026 Samar Baxtiyorov. Barcha huquqlar himoyalangan.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;

  _FaqItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
  });
}
