// ============================================
// Arena — Biznes / Muassasa Akkauntiga Kirish & Ro'yxatdan O'tish
// Har bir poliya/arena egasi uchun shaxsiy hisob yaratish va kirish
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../auth_provider.dart';
import '../providers/business_account_provider.dart';
import '../../../features/management/models/staff_member.dart';
import '../../../features/management/providers/staff_provider.dart';

class BusinessAuthScreen extends ConsumerStatefulWidget {
  const BusinessAuthScreen({super.key});

  @override
  ConsumerState<BusinessAuthScreen> createState() => _BusinessAuthScreenState();
}

class _BusinessAuthScreenState extends ConsumerState<BusinessAuthScreen> {
  bool _isLoginTab = true;
  bool _isCashierLogin = false; // Boshliq yoki Kassir rejimi

  // Boshliq Login Controllerlari
  final TextEditingController _loginPhoneCtrl =
      TextEditingController(text: '+998 ');
  final TextEditingController _loginPassCtrl =
      TextEditingController();
  bool _obscureLoginPass = true;

  // Kassir Login Controllerlari
  final TextEditingController _cashierLoginCtrl = TextEditingController();
  final TextEditingController _cashierPassCtrl = TextEditingController();
  bool _obscureCashierPass = true;

  // Ro'yxatdan o'tish Controllerlari
  final TextEditingController _regVenueCtrl = TextEditingController();
  final TextEditingController _regOwnerCtrl = TextEditingController();
  final TextEditingController _regPhoneCtrl =
      TextEditingController(text: '+998 ');
  final TextEditingController _regPassCtrl = TextEditingController();
  final TextEditingController _regPinCtrl = TextEditingController();
  bool _obscureRegPass = true;

  @override
  void dispose() {
    _loginPhoneCtrl.dispose();
    _loginPassCtrl.dispose();
    _cashierLoginCtrl.dispose();
    _cashierPassCtrl.dispose();
    _regVenueCtrl.dispose();
    _regOwnerCtrl.dispose();
    _regPhoneCtrl.dispose();
    _regPassCtrl.dispose();
    _regPinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final businessState = ref.watch(businessAccountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logotip va Brend Sarlavhasi ──────────────
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.sports_soccer_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),

                  const Gap(16),

                  const Text(
                    'Arena POS',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Gap(4),
                  const Text(
                    'Sport zallari va o\'yin majmualari boshqaruv tizimi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const Gap(24),

                  // ── Tab Switcher (Kirish / Yangi Hisob) ───────
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _isLoginTab = true),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isLoginTab
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _isLoginTab
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Tizimga Kirish',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _isLoginTab
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: _isLoginTab
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _isLoginTab = false),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isLoginTab
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !_isLoginTab
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Yangi Hisob Ochish',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: !_isLoginTab
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: !_isLoginTab
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Gap(20),

                  // ── Asosiy Form Kartasi ───────────────────────
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: _isLoginTab
                        ? _buildLoginForm(businessState)
                        : _buildRegisterForm(),
                  ),

                  const Gap(20),

                  // Pastki ma'lumot
                  const Text(
                    'Arena POS • Versiya 1.0 • O\'zbekiston',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── 1. Tizimga Kirish Formasi ─────────────────────────────
  Widget _buildLoginForm(BusinessAccountState businessState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hisobingizga Kiring',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        const Gap(4),
        Text(
          _isCashierLogin
              ? 'Boshliq bergan login va parolni kiriting'
              : 'Telefon raqami va parolni kiriting',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const Gap(16),

        // ── Rol Tanlash (Boshliq vs Kassir) ───────────────────
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isCashierLogin = false),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          !_isCashierLogin ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: !_isCashierLogin
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '🏢 Boshliq (Ega)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: !_isCashierLogin
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: !_isCashierLogin
                              ? const Color(0xFF1E40AF)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isCashierLogin = true),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          _isCashierLogin ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _isCashierLogin
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '👨‍💼 Kassir',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _isCashierLogin
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: _isCashierLogin
                              ? const Color(0xFF047857)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const Gap(16),

        if (!_isCashierLogin) ...[
          // ── BOSHLIQ FORMASI ────────────────────────────────
          const Text(
            'Telefon Raqami / Login',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155)),
          ),
          const Gap(6),
          TextField(
            controller: _loginPhoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '+998 90 123 45 67',
              prefixIcon: const Icon(Icons.phone_outlined,
                  size: 20, color: Color(0xFF64748B)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),

          const Gap(14),

          const Text(
            'Akkaunt Paroli',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155)),
          ),
          const Gap(6),
          TextField(
            controller: _loginPassCtrl,
            obscureText: _obscureLoginPass,
            decoration: InputDecoration(
              hintText: 'Parolingizni kiriting',
              prefixIcon: const Icon(Icons.lock_outline_rounded,
                  size: 20, color: Color(0xFF64748B)),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureLoginPass
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: const Color(0xFF64748B),
                ),
                onPressed: () {
                  setState(() => _obscureLoginPass = !_obscureLoginPass);
                },
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),

          const Gap(22),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login_rounded, size: 20),
                  Gap(8),
                  Text(
                    'Boshliq Sifatida Kirish',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          // ── KASSIR FORMASI ─────────────────────────────────
          const Text(
            'Kassir Logini *',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155)),
          ),
          const Gap(6),
          TextField(
            controller: _cashierLoginCtrl,
            decoration: InputDecoration(
              hintText: 'Masalan: kassir1 yoki rustam',
              prefixIcon: const Icon(Icons.badge_outlined,
                  size: 20, color: Color(0xFF059669)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),

          const Gap(14),

          const Text(
            'Kassir Paroli *',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155)),
          ),
          const Gap(6),
          TextField(
            controller: _cashierPassCtrl,
            obscureText: _obscureCashierPass,
            decoration: InputDecoration(
              hintText: 'Boshliq bergan parolni kiriting',
              prefixIcon: const Icon(Icons.password_rounded,
                  size: 20, color: Color(0xFF059669)),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureCashierPass
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: const Color(0xFF64748B),
                ),
                onPressed: () {
                  setState(() => _obscureCashierPass = !_obscureCashierPass);
                },
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),

          const Gap(22),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _handleCashierLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.point_of_sale_rounded, size: 20),
                  Gap(8),
                  Text(
                    'Kassir Sifatida Kirish',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── 2. Yangi Hisob Ochish Formasi ─────────────────────────
  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Yangi Majmua / Poliya Qo\'shish',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        const Gap(4),
        const Text(
          'Har bir poliya egasi o\'ziga xos hisob ochadi',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const Gap(18),

        // Majmua / Poliya Nomi
        const Text(
          'Poliya / Majmua Nomi *',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155)),
        ),
        const Gap(6),
        TextField(
          controller: _regVenueCtrl,
          decoration: InputDecoration(
            hintText: 'Masalan: Arena Jeyda Sport Majmuasi',
            prefixIcon: const Icon(Icons.stadium_outlined,
                size: 20, color: Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),

        const Gap(14),

        // Boshliq Ismi
        const Text(
          'Boshliq (Ega) Ismi va Familiyasi *',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155)),
        ),
        const Gap(6),
        TextField(
          controller: _regOwnerCtrl,
          decoration: InputDecoration(
            hintText: 'Masalan: Samar Baxtiyorov',
            prefixIcon: const Icon(Icons.person_outline_rounded,
                size: 20, color: Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),

        const Gap(14),

        // Telefon
        const Text(
          'Telefon Raqami (Login) *',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155)),
        ),
        const Gap(6),
        TextField(
          controller: _regPhoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: '+998 90 123 45 67',
            prefixIcon: const Icon(Icons.phone_outlined,
                size: 20, color: Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),

        const Gap(14),

        // Parol
        const Text(
          'Yangi Akkaunt Paroli *',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155)),
        ),
        const Gap(6),
        TextField(
          controller: _regPassCtrl,
          obscureText: _obscureRegPass,
          decoration: InputDecoration(
            hintText: 'Kamida 4-6 ta belgi',
            prefixIcon: const Icon(Icons.lock_outline_rounded,
                size: 20, color: Color(0xFF64748B)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureRegPass
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: const Color(0xFF64748B),
              ),
              onPressed: () {
                setState(() => _obscureRegPass = !_obscureRegPass);
              },
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),

        const Gap(14),

        // 4 xonali PIN-kod
        const Text(
          'Boshliq 4 xonali Kirish PIN-kodi *',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155)),
        ),
        const Gap(6),
        TextField(
          controller: _regPinCtrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'Masalan: 4920',
            counterText: '',
            prefixIcon: const Icon(Icons.pin_rounded,
                size: 20, color: Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),

        const Gap(22),

        // Ro'yxatdan o'tish tugmasi
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 20),
                Gap(8),
                Text(
                  'Hisobni Yaratish va Kirish',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Login Amalini Bajarish ────────────────────────────────
  Future<void> _handleLogin() async {
    final phone = _loginPhoneCtrl.text.trim();
    final pass = _loginPassCtrl.text.trim();

    if (phone.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Iltimos, telefon va parolni kiriting!"),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final success = await ref
        .read(businessAccountProvider.notifier)
        .loginAccount(phone: phone, password: pass);

    if (success) {
      final active = ref.read(businessAccountProvider).activeAccount;
      if (active != null) {
        ref.read(authProvider.notifier).loginAsOwner(
              ownerName: active.ownerName,
              phone: active.phone,
            );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${active?.venueName ?? 'Hisob'}ga muvaffaqiyatli kirildi!"),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Telefon raqami yoki parol noto'g'ri!"),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  // ── Kassir Sifatida Kirish Amalini Bajarish ───────────────
  Future<void> _handleCashierLogin() async {
    final login = _cashierLoginCtrl.text.trim();
    final pass = _cashierPassCtrl.text.trim();

    if (login.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Iltimos, kassir logini va parolini kiriting!"),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final cashier = await StaffListNotifier.findCashierByCredentials(
      login: login,
      password: pass,
    );

    if (cashier != null) {
      // 1. Agar kassir hali PIN o'rnatmagan bo'lsa — avval PIN dialogini ko'rsatamiz
      if (!cashier.hasCustomPin) {
        if (mounted) {
          _showSetPinModal(cashier);
        }
      } else {
        // 2. PIN mavjud bo'lsa: avval Kassir rolini o'rnatamiz, so'ng hisobga ulaymiz
        ref.read(authProvider.notifier).loginAsStaff(cashier);
        await ref
            .read(businessAccountProvider.notifier)
            .switchAccount(cashier.accountId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Xush kelibsiz, ${cashier.name}! Kassir rejimiga kirildi."),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Kassir logini yoki paroli noto'g'ri! Boshliqdan aniqlang."),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  // ── Kassir Uchun Shaxsiy PIN O'rnatish Modali ─────────────
  void _showSetPinModal(StaffMember cashier) {
    final pin1Ctrl = TextEditingController();
    final pin2Ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.pin_rounded,
                        color: Color(0xFF059669), size: 24),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Xush kelibsiz, ${cashier.name}!",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const Text(
                          "O'zingiz uchun 4 xonali shaxsiy PIN-kod o'rnating",
                          style:
                              TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(18),
              const Text(
                "Yangi 4 xonali PIN *",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const Gap(6),
              TextField(
                controller: pin1Ctrl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: "Masalan: 2580",
                  counterText: "",
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const Gap(12),
              const Text(
                "PIN-kodni tasdiqlang *",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const Gap(6),
              TextField(
                controller: pin2Ctrl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: "PIN-kodni qayta kiriting",
                  counterText: "",
                  prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const Gap(20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final p1 = pin1Ctrl.text.trim();
                    final p2 = pin2Ctrl.text.trim();
                    if (p1.length != 4 || p2.length != 4) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text("PIN-kod 4 ta raqam bo'lishi shart!"),
                          backgroundColor: Color(0xFFEF4444),
                        ),
                      );
                      return;
                    }
                    if (p1 != p2) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text("PIN-kodlar bir-biriga mos kelmadi!"),
                          backgroundColor: Color(0xFFEF4444),
                        ),
                      );
                      return;
                    }

                    await ref
                        .read(staffListProvider.notifier)
                        .setCashierPin(staffId: cashier.id, newPin: p1);

                    final updatedCashier = cashier.copyWith(pin: p1);

                    // 1. Avval Kassir roli bilan tizimga kiritamiz
                    ref
                        .read(authProvider.notifier)
                        .loginAsStaff(updatedCashier);

                    // 2. So'ng hisobni almashtiramiz (GoRouter endi to'g'ri Kassir roli bilan ochadi)
                    await ref
                        .read(businessAccountProvider.notifier)
                        .switchAccount(cashier.accountId);

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              "PIN-kod muvaffaqiyatli saqlandi! Xush kelibsiz, ${cashier.name}! Kassir rejimiga kirildi."),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "PIN-kodni Saqlash va Kirish",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Ro'yxatdan O'tish Amalini Bajarish ────────────────────
  Future<void> _handleRegister() async {
    final venue = _regVenueCtrl.text.trim();
    final owner = _regOwnerCtrl.text.trim();
    final phone = _regPhoneCtrl.text.trim();
    final pass = _regPassCtrl.text.trim();
    final pin = _regPinCtrl.text.trim();

    if (venue.isEmpty || owner.isEmpty || phone.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Iltimos, barcha maydonlarni to'ldiring!"),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (pin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kirish PIN-kodi roppa-rosa 4 ta raqam bo'lishi shart!"),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final success = await ref
        .read(businessAccountProvider.notifier)
        .registerAccount(
          venueName: venue,
          ownerName: owner,
          phone: phone,
          password: pass,
          ownerPin: pin,
        );

    if (success) {
      final active = ref.read(businessAccountProvider).activeAccount;
      if (active != null) {
        ref.read(authProvider.notifier).loginAsOwner(
              ownerName: active.ownerName,
              phone: active.phone,
            );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$venue hisobi yaratildi va tizimga kirildi!"),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Ushbu telefon raqami allaqachon ro'yxatdan o'tgan! Boshqa raqam kiriting."),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}
