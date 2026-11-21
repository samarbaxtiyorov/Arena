// ============================================
// Arena POS — Aqlli Chiroqlar Sozlamalari
// ESP32, ESP8266, Sonoff 4CH, Tasmota, Tuya Smart Life
// O'yin boshlanganda avtomatik yoqish, yopilganda o'chirish
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/services/smart_light_service.dart';
import '../../tables/providers/tables_providers.dart';
import '../providers/business_settings_provider.dart';

class SmartLightsScreen extends ConsumerStatefulWidget {
  const SmartLightsScreen({super.key});

  @override
  ConsumerState<SmartLightsScreen> createState() => _SmartLightsScreenState();
}

class _SmartLightsScreenState extends ConsumerState<SmartLightsScreen> {
  late bool _smartLightsEnabled;
  late String _smartLightType; // 'local_wifi' yoki 'tuya'
  late TextEditingController _localRelayIpController;
  late TextEditingController _tuyaAccessIdController;
  late TextEditingController _tuyaAccessSecretController;
  late TextEditingController _tuyaDeviceIdController;

  bool _isCheckingStatus = false;
  Map<String, dynamic>? _deviceStatusResult;
  final Map<int, bool> _channelTestStates = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(businessSettingsProvider);

    _smartLightsEnabled = s.smartLightsEnabled;
    _smartLightType = s.smartLightType;
    _localRelayIpController = TextEditingController(text: s.localRelayIp);
    _tuyaAccessIdController = TextEditingController(text: s.tuyaAccessId);
    _tuyaAccessSecretController = TextEditingController(text: s.tuyaAccessSecret);
    _tuyaDeviceIdController = TextEditingController(text: s.tuyaDeviceId);
  }

  @override
  void dispose() {
    _localRelayIpController.dispose();
    _tuyaAccessIdController.dispose();
    _tuyaAccessSecretController.dispose();
    _tuyaDeviceIdController.dispose();
    super.dispose();
  }

  void _saveSettings({bool showToast = true}) {
    setState(() => _isSaving = true);
    final notifier = ref.read(businessSettingsProvider.notifier);
    final current = ref.read(businessSettingsProvider);

    final updated = current.copyWith(
      smartLightsEnabled: _smartLightsEnabled,
      smartLightType: _smartLightType,
      localRelayIp: _localRelayIpController.text.trim(),
      tuyaAccessId: _tuyaAccessIdController.text.trim(),
      tuyaAccessSecret: _tuyaAccessSecretController.text.trim(),
      tuyaDeviceId: _tuyaDeviceIdController.text.trim(),
    );

    notifier.saveSettings(updated);
    setState(() => _isSaving = false);

    if (showToast && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("💡 Aqlli chiroqlar sozlamalari muvaffaqiyatli saqlandi!"),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _checkDevicePing() async {
    final ip = _localRelayIpController.text.trim();
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Iltimos, avval qurilma IP-manzilini kiriting!"),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isCheckingStatus = true;
      _deviceStatusResult = null;
    });

    final smartService = ref.read(smartLightServiceProvider);
    final res = await smartService.checkDeviceStatus(customIp: ip);

    if (mounted) {
      setState(() {
        _isCheckingStatus = false;
        _deviceStatusResult = res;
      });
    }
  }

  Future<void> _testChannelToggle(int channel) async {
    final currentState = _channelTestStates[channel] ?? false;
    final newState = !currentState;

    setState(() {
      _channelTestStates[channel] = newState;
    });

    final smartService = ref.read(smartLightServiceProvider);
    final success = await smartService.setLightState(
      channel: channel,
      state: newState,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? "💡 $channel-kanal ${newState ? 'YOQILDI' : 'O\'CHIRILDI'}!"
              : "⚠️ $channel-kanalga signal yuborib bo'lmadi. IP-manzilni tekshiring."),
          backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Aqlli Chiroqlar Sozlamalari",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: "Saqlash",
            icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB)),
            onPressed: () => _saveSettings(showToast: true),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. ASOSIY YOQISH / O'CHIRISH KARTASI ─────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _smartLightsEnabled
                      ? const Color(0xFF2563EB).withOpacity(0.3)
                      : const Color(0xFFE2E8F0),
                  width: _smartLightsEnabled ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _smartLightsEnabled
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.lightbulb_rounded,
                          color: _smartLightsEnabled
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF94A3B8),
                          size: 26,
                        ),
                      ),
                      const Gap(14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Aqlli Chiroqlar Tizimi",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const Gap(2),
                            Text(
                              _smartLightsEnabled
                                  ? "Avtomatik boshqaruv FAOL"
                                  : "Tizim o'chirilgan (qo'lda rejim)",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _smartLightsEnabled
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _smartLightsEnabled,
                        activeColor: const Color(0xFF2563EB),
                        onChanged: (val) {
                          setState(() => _smartLightsEnabled = val);
                          _saveSettings(showToast: false);
                        },
                      ),
                    ],
                  ),
                  if (_smartLightsEnabled) ...[
                    const Gap(12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                          Gap(8),
                          Expanded(
                            child: Text(
                              "Stol boshlanganda chiroq avtomatik yonadi, to'lov qilinganda avtomatik o'chadi.",
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF15803D),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (_smartLightsEnabled) ...[
              const Gap(16),

              // ── 2. ULANISH TURI TANLASH ─────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "QURILMA VA ULANISH TURI:",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() => _smartLightType = 'local_wifi');
                              _saveSettings(showToast: false);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              decoration: BoxDecoration(
                                color: _smartLightType == 'local_wifi'
                                    ? const Color(0xFFEFF6FF)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _smartLightType == 'local_wifi'
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFCBD5E1),
                                  width: _smartLightType == 'local_wifi' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.wifi_rounded,
                                    color: _smartLightType == 'local_wifi'
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFF64748B),
                                    size: 24,
                                  ),
                                  const Gap(6),
                                  Text(
                                    "Lokal Wi-Fi (ESP32)",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: _smartLightType == 'local_wifi'
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const Gap(2),
                                  const Text(
                                    "Internetsiz ishlaydi",
                                    style: TextStyle(fontSize: 10, color: Color(0xFF10B981)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() => _smartLightType = 'tuya');
                              _saveSettings(showToast: false);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              decoration: BoxDecoration(
                                color: _smartLightType == 'tuya'
                                    ? const Color(0xFFEFF6FF)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _smartLightType == 'tuya'
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFCBD5E1),
                                  width: _smartLightType == 'tuya' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.cloud_sync_rounded,
                                    color: _smartLightType == 'tuya'
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFF64748B),
                                    size: 24,
                                  ),
                                  const Gap(6),
                                  Text(
                                    "Tuya / Smart Life",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: _smartLightType == 'tuya'
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const Gap(2),
                                  const Text(
                                    "Bulut orqali ulanish",
                                    style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Gap(16),

                    // Lokal Wi-Fi sozlamalari
                    if (_smartLightType == 'local_wifi') ...[
                      const Text(
                        "Rele IP-Manzili (Mahalliy Wi-Fi router tarmog'i):",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                      ),
                      const Gap(6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _localRelayIpController,
                              decoration: InputDecoration(
                                hintText: "Masalan: 192.168.1.105",
                                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                prefixIcon: const Icon(Icons.router_rounded, size: 20, color: Color(0xFF2563EB)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                              onChanged: (_) => _saveSettings(showToast: false),
                            ),
                          ),
                          const Gap(10),
                          ElevatedButton.icon(
                            onPressed: _isCheckingStatus ? null : _checkDevicePing,
                            icon: _isCheckingStatus
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.sensors_rounded, size: 18),
                            label: const Text(
                              "Tekshirish",
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),

                      if (_deviceStatusResult != null) ...[
                        const Gap(10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _deviceStatusResult!['online'] == true
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _deviceStatusResult!['online'] == true
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _deviceStatusResult!['online'] == true
                                    ? Icons.check_circle_rounded
                                    : Icons.error_outline_rounded,
                                color: _deviceStatusResult!['online'] == true
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFDC2626),
                                size: 20,
                              ),
                              const Gap(10),
                              Expanded(
                                child: Text(
                                  _deviceStatusResult!['message'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _deviceStatusResult!['online'] == true
                                        ? const Color(0xFF065F46)
                                        : const Color(0xFF991B1B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ] else ...[
                      // Tuya sozlamalari
                      TextField(
                        controller: _tuyaDeviceIdController,
                        decoration: InputDecoration(
                          labelText: "Tuya Device ID",
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (_) => _saveSettings(showToast: false),
                      ),
                      const Gap(10),
                      TextField(
                        controller: _tuyaAccessIdController,
                        decoration: InputDecoration(
                          labelText: "Tuya Client ID (Access ID)",
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (_) => _saveSettings(showToast: false),
                      ),
                      const Gap(10),
                      TextField(
                        controller: _tuyaAccessSecretController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Tuya Access Secret",
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (_) => _saveSettings(showToast: false),
                      ),
                    ],
                  ],
                ),
              ),

              const Gap(16),

              // ── 3. STOLLARNI RELE KANALLARIGA BIRIKTIRISH ───────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "STOLLAR VA KANALLAR MOSLIGI:",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.6,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Avtomatik ulangan",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(12),
                    Consumer(
                      builder: (context, ref, _) {
                        final tablesAsync = ref.watch(tablesStreamProvider);
                        return tablesAsync.when(
                          data: (tables) {
                            if (tables.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: Text(
                                    "Hozircha stollar mavjud emas. Avval Maydonlar bo'limidan stol qo'shing.",
                                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                  ),
                                ),
                              );
                            }

                            final settings = ref.watch(businessSettingsProvider);
                            final channels = settings.tableRelayChannels;

                            return Column(
                              children: tables.map((t) {
                                final currentCh = channels[t.id] ?? 1;
                                final isTesting = _channelTestStates[currentCh] ?? false;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isTesting
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFFE2E8F0),
                                      width: isTesting ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.table_restaurant_rounded,
                                        size: 20,
                                        color: isTesting
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFF2563EB),
                                      ),
                                      const Gap(10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              t.name,
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                            Text(
                                              "${t.pricePerHour ~/ 1000} ming/soat",
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Kanal tanlash dropdowni
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFFCBD5E1)),
                                        ),
                                        child: DropdownButton<int>(
                                          value: currentCh,
                                          underline: const SizedBox(),
                                          isDense: true,
                                          items: List.generate(16, (i) => i + 1).map((ch) {
                                            return DropdownMenuItem(
                                              value: ch,
                                              child: Text(
                                                "$ch-Kanal",
                                                style: const TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (newCh) {
                                            if (newCh != null) {
                                              final updatedMap = Map<String, int>.from(channels);
                                              updatedMap[t.id] = newCh;
                                              final sNotifier = ref.read(businessSettingsProvider.notifier);
                                              sNotifier.saveSettings(
                                                settings.copyWith(tableRelayChannels: updatedMap),
                                              );
                                            }
                                          },
                                        ),
                                      ),

                                      const Gap(8),

                                      // Chiroqni shu zahoti sinash (test) tugmasi
                                      IconButton(
                                        tooltip: "$currentCh-kanalni yoqib/o'chirib ko'rish",
                                        icon: Icon(
                                          isTesting
                                              ? Icons.lightbulb_rounded
                                              : Icons.lightbulb_outline_rounded,
                                          color: isTesting
                                              ? const Color(0xFFF59E0B)
                                              : const Color(0xFF64748B),
                                          size: 22,
                                        ),
                                        onPressed: () => _testChannelToggle(currentCh),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Text("Xatolik: $e"),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const Gap(16),

              // ── 4. APPARAT VA QO'LLANMA (Yo'riqnoma) ─────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline_rounded, size: 18, color: Color(0xFF2563EB)),
                        Gap(8),
                        Text(
                          "Aqlli Rele Qanday Ishlaydi?",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Gap(8),
                    Text(
                      "1. Arena POS istalgan standart 4-kanalli yoki 8-kanalli Wi-Fi relelar (ESP32, ESP8266, Sonoff 4CH, Shelly, Tasmota) bilan ishlaydi.\n"
                      "2. Qurilma va kassa kompyuteri (yoki telefon) bitta klub Wi-Fi routeriga ulangan bo'lishi kifoya (INTERNET bo'lishi shart emas).\n"
                      "3. Kassir maydonni 'Boshlash' tugmasini bosishi bilan ushbu stolning chirog'i bir zumda avtomatik yonadi.\n"
                      "4. O'yin tugab, to'lov qabul qilinganda esa chiroq darhol avtomatik o'chadi.",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF475569),
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Gap(24),

            // ── SAQLASH TUGMASI ──────────────────────────────────────
            ElevatedButton(
              onPressed: _isSaving ? null : () => _saveSettings(showToast: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Sozlamalarni Saqlash",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
            const Gap(16),
          ],
        ),
      ),
    );
  }
}
