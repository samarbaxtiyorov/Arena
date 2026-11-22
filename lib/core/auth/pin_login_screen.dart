// ============================================
// Champion POS — PIN Login Ekrani
// Desktop & Mobil uchun moslashuvchan, klaviatura qo'llab-quvvatlovchi
// 4 xonali shaxsiy PIN (Boshliq va Kassirlar uchun)
// ============================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../features/management/providers/staff_provider.dart';
import '../config/app_mode.dart';
import '../widgets/arena_logo.dart';
import 'auth_provider.dart';
import 'providers/business_account_provider.dart';

class PinLoginScreen extends ConsumerStatefulWidget {
  const PinLoginScreen({super.key});

  @override
  ConsumerState<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<PinLoginScreen> {
  String _enteredPin = '';
  String? _errorMessage;
  int _failedAttempts = 0;
  int _lockoutSeconds = 0;
  Timer? _lockoutTimer;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Kompyuterda ochilganda avtomatik klaviatura fokusini olish
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _startLockout() {
    setState(() {
      _lockoutSeconds = 30;
      _enteredPin = '';
      _errorMessage = "Xavfsizlik blokirovkasi: 5 marta xato PIN! 30 soniya kuting.";
    });
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_lockoutSeconds <= 1) {
        timer.cancel();
        setState(() {
          _lockoutSeconds = 0;
          _failedAttempts = 0;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _lockoutSeconds--;
          _errorMessage =
              "Xavfsizlik blokirovkasi: 5 marta xato PIN! $_lockoutSeconds soniya kuting.";
        });
      }
    });
  }

  void _onDigitPress(String digit) {
    if (_lockoutSeconds > 0) return;
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _errorMessage = null;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_lockoutSeconds > 0) return;
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _onClear() {
    if (_lockoutSeconds > 0) return;
    setState(() {
      _enteredPin = '';
      _errorMessage = null;
    });
  }

  void _verifyPin() {
    final businessState = ref.read(businessAccountProvider);
    final activeVenue = businessState.activeAccount;
    final staffList = ref.read(staffListProvider).value;
    final appMode = ref.read(appModeProvider);
    final isBoss = appMode == AppMode.boss;

    // 1. Agar Boshliqning shaxsiy PIN-kodi kiritilgan bo'lsa
    if (activeVenue != null && _enteredPin == activeVenue.ownerPin) {
      _failedAttempts = 0;
      ref.read(authProvider.notifier).loginAsOwner(
            ownerName: activeVenue.ownerName,
            phone: activeVenue.phone,
          );
      return;
    }

    // 2. Agar Arena Boss rejimida bo'lsa va kassir PIN kiritilsa:
    // Kassirlar Arena Boss tizimiga kira olmaydi! Faqat Ega uchun.
    if (isBoss) {
      _failedAttempts++;
      setState(() {
        _errorMessage = "Bu PIN-kod kassirga tegishli! Arena Boss faqat Klub Egasi (Boshliq) uchun.";
        _enteredPin = '';
      });
      return;
    }

    // 3. Agar kassirlardan birortasining PIN-kodi kiritilgan bo'lsa (Arena POS kassa rejimi)
    final success = ref.read(authProvider.notifier).verifyPin(_enteredPin, staffList: staffList);
    if (success) {
      _failedAttempts = 0;
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _startLockout();
      } else {
        final remaining = 5 - _failedAttempts;
        setState(() {
          _errorMessage = "Noto'g'ri PIN-kod! (Qolgan urinishlar: $remaining)";
          _enteredPin = '';
        });
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Raqamlar (Asosiy klaviatura va Numpad)
    final char = event.character;
    if (char != null && RegExp(r'^[0-9]$').hasMatch(char)) {
      _onDigitPress(char);
      return KeyEventResult.handled;
    }

    // Backspace
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _onBackspace();
      return KeyEventResult.handled;
    }

    // Escape - PINni tozalash
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _onClear();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 650;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: Scaffold(
          backgroundColor: isDesktop ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          body: Stack(
            children: [
              // Fon dekoratsiyasi (Desktop va Mobile uchun chiroyli fon)
              if (isDesktop) ...[
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, -0.3),
                        radius: 1.2,
                        colors: [
                          Color(0xFF1E293B),
                          Color(0xFF0F172A),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -100,
                  left: -100,
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2563EB).withOpacity(0.08),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -120,
                  right: -100,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF38BDF8).withOpacity(0.05),
                    ),
                  ),
                ),
              ] else ...[
                Positioned(
                  top: -60,
                  left: -60,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3B82F6).withOpacity(0.08),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -80,
                  left: -60,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3B82F6).withOpacity(0.06),
                    ),
                  ),
                ),
              ],

              // Asosiy kontent
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: isDesktop ? _buildDesktopCard() : _buildMobileLayout(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // DESKTOP: Ixcham, Markazlashgan Premium Karta
  // ============================================
  Widget _buildDesktopCard() {
    final appMode = ref.watch(appModeProvider);
    final isBoss = appMode == AppMode.boss;

    return Container(
      width: 440,
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isBoss ? const Color(0xFFFACC15).withOpacity(0.5) : const Color(0xFFE2E8F0),
          width: isBoss ? 1.5 : 1,
        ),
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
          // ── Rejimni Tanlash: Arena POS vs Arena Boss ──
          _buildModeSelector(isBoss),

          const Gap(18),

          // Logotip va Rejim Belgisi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ArenaLogo(size: 44, borderRadius: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isBoss ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isBoss ? const Color(0xFFFDE68A) : const Color(0xFFA7F3D0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isBoss ? Icons.shield_rounded : Icons.point_of_sale_rounded,
                      color: isBoss ? const Color(0xFFB45309) : const Color(0xFF059669),
                      size: 14,
                    ),
                    const Gap(4),
                    Text(
                      isBoss ? '👑 Ega Markazi' : '🖥️ Kassir Ish O\'rni',
                      style: TextStyle(
                        fontSize: 11,
                        color: isBoss ? const Color(0xFFB45309) : const Color(0xFF059669),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Gap(16),

          // Foydalanuvchi va Muassasa ma'lumoti
          Consumer(
            builder: (context, ref, _) {
              final venue = ref.watch(businessAccountProvider).activeAccount;
              return Column(
                children: [
                  Text(
                    isBoss ? 'ARENA BOSS' : (venue?.venueName ?? 'ARENA POS'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isBoss ? const Color(0xFF92400E) : const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Gap(6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: isBoss ? const Color(0xFFFFFBEB) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isBoss ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      isBoss
                          ? "👑 Faqat Klub Rahbari (Boshliq: ${venue?.ownerName ?? 'Ega'})"
                          : (venue != null ? "👤 Kassir / Marker stoli" : "Xodim PIN-kodi"),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isBoss ? const Color(0xFFB45309) : const Color(0xFF475569),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const Gap(16),

          Text(
            isBoss ? 'Boshqaruv Tizimi' : 'Xush kelibsiz!',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const Gap(4),
          Text(
            isBoss
                ? 'Boshqaruv markaziga kirish uchun Boshliq PIN kodini kiriting'
                : 'Kassaga kirish uchun 4 xonali PIN kodni kiriting',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),

          const Gap(24),

          // 4 ta PIN Nuqtalari
          _buildPinDots(),

          if (_errorMessage != null) ...[
            const Gap(12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          const Gap(24),

          // Ixcham Numpad (Desktop uchun eni atigi 280px)
          SizedBox(
            width: 280,
            child: _buildNumpadGrid(),
          ),

          const Gap(16),

          // Klaviaturadan kiritish haqida maslahat
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.keyboard_outlined, size: 14, color: Color(0xFF94A3B8)),
                Gap(6),
                Text(
                  'Klaviaturadan ham terish mumkin (0-9)',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const Gap(16),

          // Boshqa hisobga o'tish tugmasi
          _buildSwitchAccountButton(),
        ],
      ),
    );
  }

  // ============================================
  // MOBIL: Vertikal mutanosib tartib
  // ============================================
  Widget _buildMobileLayout() {
    final appMode = ref.watch(appModeProvider);
    final isBoss = appMode == AppMode.boss;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Rejimni Tanlash: Arena POS vs Arena Boss
        _buildModeSelector(isBoss),

        const Gap(16),

        // Yuqori belgi qatori
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ArenaLogo(size: 44, borderRadius: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isBoss ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isBoss ? const Color(0xFFFDE68A) : const Color(0xFFA7F3D0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isBoss ? Icons.shield_rounded : Icons.point_of_sale_rounded,
                      color: isBoss ? const Color(0xFFB45309) : const Color(0xFF059669),
                      size: 14,
                    ),
                    const Gap(4),
                    Text(
                      isBoss ? '👑 Ega Markazi' : '🖥️ Kassir Ish O\'rni',
                      style: TextStyle(
                        fontSize: 11,
                        color: isBoss ? const Color(0xFFB45309) : const Color(0xFF059669),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Gap(16),

        // Sarlavhalar
        Consumer(
          builder: (context, ref, _) {
            final venue = ref.watch(businessAccountProvider).activeAccount;
            return Column(
              children: [
                Text(
                  isBoss ? 'ARENA BOSS' : (venue?.venueName ?? 'ARENA POS'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: isBoss ? const Color(0xFF92400E) : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const Gap(4),
                Text(
                  isBoss
                      ? "👑 Klub Egasi (Boshliq: ${venue?.ownerName ?? 'Ega'})"
                      : (venue != null
                          ? "👤 Kassir / Marker stoli"
                          : "4 xonali shaxsiy PIN-kodingizni kiriting"),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isBoss ? const Color(0xFFB45309) : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          },
        ),

        const Gap(20),

        Text(
          isBoss ? 'Boshqaruv Tizimi' : 'Xush kelibsiz!',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        const Gap(6),
        Text(
          isBoss
              ? 'Boshqaruv markaziga kirish uchun Boshliq PIN kodini kiriting'
              : 'Tizimga kirish uchun shaxsiy PIN kodingizni kiriting',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),

        const Gap(24),

        // 4 ta PIN nuqtalari
        _buildPinDots(),

        if (_errorMessage != null) ...[
          const Gap(12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],

        const Gap(28),

        // Numpad (Mobil uchun maxWidth: 300px qilib cheklangan, hech qachon cho'zilib ketmaydi)
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: _buildNumpadGrid(),
        ),

        const Gap(24),

        _buildSwitchAccountButton(),
      ],
    );
  }

  // 4 ta PIN indikator nuqtasi
  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < _enteredPin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? const Color(0xFF2563EB) : Colors.transparent,
            border: Border.all(
              color: isFilled ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
              width: 2,
            ),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
        );
      }),
    );
  }

  // Numpad tugmalari
  Widget _buildNumpadGrid() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNumRow(['1', '2', '3']),
        const Gap(14),
        _buildNumRow(['4', '5', '6']),
        const Gap(14),
        _buildNumRow(['7', '8', '9']),
        const Gap(14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.refresh_rounded,
              tooltip: 'Tozalash',
              onTap: _onClear,
            ),
            _buildNumButton('0'),
            _buildActionButton(
              icon: Icons.backspace_outlined,
              tooltip: 'O\'chirish',
              onTap: _onBackspace,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildNumButton(d)).toList(),
    );
  }

  Widget _buildNumButton(String digit) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Material(
        color: const Color(0xFFF8FAFC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        child: InkWell(
          onTap: () => _onDigitPress(digit),
          borderRadius: BorderRadius.circular(32),
          splashColor: const Color(0xFFDBEAFE),
          hoverColor: const Color(0xFFEFF6FF),
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Material(
        color: const Color(0xFFF8FAFC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          splashColor: const Color(0xFFDBEAFE),
          hoverColor: const Color(0xFFEFF6FF),
          child: Center(
            child: Icon(
              icon,
              size: 24,
              color: const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector(bool isBoss) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                if (isBoss) {
                  ref.read(appModeProvider.notifier).setMode(AppMode.pos);
                  setState(() => _errorMessage = null);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !isBoss ? const Color(0xFF10B981) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !isBoss
                      ? [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.point_of_sale_rounded,
                      size: 15,
                      color: !isBoss ? Colors.white : const Color(0xFF64748B),
                    ),
                    const Gap(6),
                    Text(
                      'Arena POS (Kassa)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: !isBoss ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Gap(4),
          Expanded(
            child: InkWell(
              onTap: () {
                if (!isBoss) {
                  ref.read(appModeProvider.notifier).setMode(AppMode.boss);
                  setState(() => _errorMessage = null);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isBoss ? const Color(0xFFFACC15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isBoss
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFACC15).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 15,
                      color: isBoss ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                    ),
                    const Gap(6),
                    Text(
                      'Arena Boss (Ega)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isBoss ? const Color(0xFF0F172A) : const Color(0xFF64748B),
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

  Widget _buildSwitchAccountButton() {
    return TextButton.icon(
      onPressed: () {
        ref.read(authProvider.notifier).logout();
        ref.read(businessAccountProvider.notifier).logoutToAuthScreen();
      },
      icon: const Icon(Icons.switch_account_rounded, size: 16, color: Color(0xFF2563EB)),
      label: const Text(
        "Boshqa hisobga o'tish / Parol bilan kirish",
        style: TextStyle(
          color: Color(0xFF2563EB),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFFEFF6FF),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFDBEAFE)),
        ),
      ),
    );
  }
}
