// ============================================
// Arena POS — Kassir Maxsus Kirish Ekrani
// Faqat Login va Parol. Ortiqcha hech narsa yo'q.
// Toza, zamonaviy, professional dizayn.
// ============================================

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_provider.dart';
import '../providers/business_account_provider.dart';
import '../../widgets/arena_logo.dart';
import '../../../features/management/providers/staff_provider.dart';
import '../../../data/repositories/database_providers.dart';

class CashierLoginScreen extends ConsumerStatefulWidget {
  const CashierLoginScreen({super.key});

  @override
  ConsumerState<CashierLoginScreen> createState() => _CashierLoginScreenState();
}

class _CashierLoginScreenState extends ConsumerState<CashierLoginScreen> {
  final TextEditingController _loginCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final FocusNode _loginFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loginFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _loginCtrl.dispose();
    _passwordCtrl.dispose();
    _loginFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final login = _loginCtrl.text.trim();
    final pass = _passwordCtrl.text.trim();

    if (login.isEmpty || pass.isEmpty) {
      setState(() {
        _errorMessage = "Iltimos, login va parolni kiriting!";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Kassirlar ro'yxatidan qidirish (login va parol bo'yicha)
      final cashier = await StaffListNotifier.findCashierByCredentials(
        login: login,
        password: pass,
      );

      if (cashier != null) {
        if (cashier.accountId.isNotEmpty) {
          await ref
              .read(businessAccountProvider.notifier)
              .switchAccount(cashier.accountId);
        }
        ref.read(authProvider.notifier).loginAsStaff(cashier);
        Future.microtask(() => ref.read(syncServiceProvider).syncAll());
        return;
      }

      // 2. Klub egasi / umumiy akkaunt logini va paroli bo'yicha tekshirish
      final ownerSuccess = await ref
          .read(businessAccountProvider.notifier)
          .loginAccount(login: login, password: pass);

      if (ownerSuccess) {
        final active = ref.read(businessAccountProvider).activeAccount;
        if (active != null) {
          ref.read(authProvider.notifier).loginAsOwner(
                ownerName: active.ownerName,
                phone: active.phone,
              );
        }
        Future.microtask(() => ref.read(syncServiceProvider).syncAll());
        return;
      }

      // 3. Agar ikkalasi ham mos kelmasa
      if (mounted) {
        setState(() {
          _errorMessage = "Login yoki parol noto'g'ri! Qayta tekshirib kiring.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Tizimga ulanishda xatolik: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 650;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // To'q hashamatli fon
      body: Stack(
        children: [
          // Fon dekoratsiyasi: Nozik yumshoq nurlar
          Positioned(
            top: -120,
            left: -100,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2563EB).withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF059669).withOpacity(0.08),
              ),
            ),
          ),

          // Markaziy Karta
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Container(
                width: isDesktop ? 420 : double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Arena Logotipi
                    const ArenaLogo(size: 58, borderRadius: 16),
                    const Gap(16),

                    // Tizim Sarlavhasi
                    const Text(
                      'ARENA POS',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Gap(4),

                    // Kassir Ish O'rni nishoni
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.point_of_sale_rounded,
                              size: 14, color: Color(0xFF059669)),
                          Gap(6),
                          Text(
                            'Kassir Ish O\'rni',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Gap(24),

                    // Tushuntirish matni
                    const Text(
                      'Tizimga kirish',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Gap(4),
                    const Text(
                      'Kassaga kirish uchun login va parolni kiriting',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const Gap(24),

                    // ── 1. Login Maydoni ──────────────────────
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const Gap(6),
                        TextField(
                          controller: _loginCtrl,
                          focusNode: _loginFocus,
                          enabled: !_isLoading,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _passwordFocus.requestFocus(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Kassir loginini kiriting',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                            ),
                            prefixIcon: const Icon(Icons.person_outline_rounded,
                                color: Color(0xFF64748B), size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: Color(0xFF2563EB), width: 1.8),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Gap(16),

                    // ── 2. Parol Maydoni ──────────────────────
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Parol',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const Gap(6),
                        TextField(
                          controller: _passwordCtrl,
                          focusNode: _passwordFocus,
                          enabled: !_isLoading,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleLogin(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Parolingizni kiriting',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                            ),
                            prefixIcon: const Icon(Icons.lock_outline_rounded,
                                color: Color(0xFF64748B), size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF64748B),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: Color(0xFF2563EB), width: 1.8),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Xatolik xabari
                    if (_errorMessage != null) ...[
                      const Gap(14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: Color(0xFFDC2626), size: 18),
                            const Gap(8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const Gap(24),

                    // ── 3. Kirish Tugmasi ─────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          disabledBackgroundColor:
                              const Color(0xFF93C5FD),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Kassaga Kirish',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  Gap(8),
                                  Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
