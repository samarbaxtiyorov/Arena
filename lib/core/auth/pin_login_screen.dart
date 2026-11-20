// ============================================
// Arena — PIN Login Ekrani (Skrinshot 5 bilan 1:1)
// 4 xonali shaxsiy PIN (7777 - Ega, 1111 - Kassir)
// ============================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../features/management/providers/staff_provider.dart';
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

  @override
  void dispose() {
    _lockoutTimer?.cancel();
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

    // 1. Agar Boshliqning shaxsiy PIN-kodi kiritilgan bo'lsa
    if (activeVenue != null && _enteredPin == activeVenue.ownerPin) {
      _failedAttempts = 0;
      ref.read(authProvider.notifier).loginAsOwner(
            ownerName: activeVenue.ownerName,
            phone: activeVenue.phone,
          );
      return;
    }

    // 2. Agar kassirlardan birortasining PIN-kodi kiritilgan bo'lsa
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Fon yumshoq doiralari (dekoratsiya)
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

          SafeArea(
            child: Column(
              children: [
                const Gap(16),
                // Yuqori belgi qatori (Koptok ikonkasi va Qalqon)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDBEAFE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sports_soccer_rounded,
                          color: Color(0xFF2563EB),
                          size: 24,
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Color(0xFF2563EB),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),

                const Gap(24),

                // Sarlavhalar
                Consumer(
                  builder: (context, ref, _) {
                    final venue = ref.watch(businessAccountProvider).activeAccount;
                    return Column(
                      children: [
                        Text(
                          venue?.venueName ?? 'Arena POS',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          venue != null
                              ? "Boshliq: ${venue.ownerName} • Kirish PIN-kodi"
                              : "4 xonali shaxsiy PIN-kodingizni kiriting",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const Gap(36),

                const Text(
                  'Xush kelibsiz!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Gap(8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Tizimga kirish uchun shaxsiy PIN kodingizni kiriting',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                ),

                const Gap(32),

                // 4 ta PIN nuqtalari
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < _enteredPin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled
                            ? const Color(0xFF2563EB)
                            : Colors.white,
                        border: Border.all(
                          color: isFilled
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFCBD5E1),
                          width: 2,
                        ),
                        boxShadow: isFilled
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                    );
                  }),
                ),

                if (_errorMessage != null) ...[
                  const Gap(14),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                const Spacer(),

                // Maxsus Numpad (1 - 9, Reset, 0, Backspace)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      _buildNumRow(['1', '2', '3']),
                      const Gap(16),
                      _buildNumRow(['4', '5', '6']),
                      const Gap(16),
                      _buildNumRow(['7', '8', '9']),
                      const Gap(16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildActionButton(
                            icon: Icons.refresh_rounded,
                            onTap: _onClear,
                          ),
                          _buildNumButton('0'),
                          _buildActionButton(
                            icon: Icons.backspace_outlined,
                            onTap: _onBackspace,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Gap(24),

                // Boshqa hisobga o'tish / Yangi hisob ochish
                TextButton.icon(
                  onPressed: () {
                    ref.read(businessAccountProvider.notifier).logoutToAuthScreen();
                  },
                  icon: const Icon(Icons.switch_account_rounded,
                      size: 18, color: Color(0xFF2563EB)),
                  label: const Text(
                    "Boshqa hisobga o'tish / Yangi hisob",
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFEFF6FF),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFDBEAFE)),
                    ),
                  ),
                ),

                const Gap(16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: digits.map((d) => _buildNumButton(d)).toList(),
    );
  }

  Widget _buildNumButton(String digit) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onDigitPress(digit),
          borderRadius: BorderRadius.circular(36),
          splashColor: const Color(0xFFDBEAFE),
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
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
  }) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(36),
          splashColor: const Color(0xFFDBEAFE),
          child: Center(
            child: Icon(
              icon,
              size: 26,
              color: const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }
}
