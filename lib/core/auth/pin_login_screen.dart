// ============================================
// Arena — PIN Login Ekrani (Skrinshot 5 bilan 1:1)
// 4 xonali shaxsiy PIN (7777 - Ega, 1111 - Kassir)
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'auth_provider.dart';

class PinLoginScreen extends ConsumerStatefulWidget {
  const PinLoginScreen({super.key});

  @override
  ConsumerState<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<PinLoginScreen> {
  String _enteredPin = '';
  String? _errorMessage;

  void _onDigitPress(String digit) {
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
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _onClear() {
    setState(() {
      _enteredPin = '';
      _errorMessage = null;
    });
  }

  void _verifyPin() {
    final success = ref.read(authProvider.notifier).verifyPin(_enteredPin);
    if (!success) {
      setState(() {
        _errorMessage = "Noto'g'ri PIN-kod! (Ega: 7777, Kassir: 1111)";
        _enteredPin = '';
      });
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
                const Text(
                  'Poliya Demo',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const Gap(6),
                const Text(
                  '4 xonali shaxsiy PIN-kodingizni kiriting',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
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

                // Boshqa hisob bilan kirish
                TextButton(
                  onPressed: () {
                    // Demo yordamchi
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Boshliq PIN: 7777 | Kassir PIN: 1111"),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                  child: const Text(
                    'Boshqa hisob bilan kirish',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
