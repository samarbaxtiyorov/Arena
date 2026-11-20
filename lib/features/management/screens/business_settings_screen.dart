// ============================================
// Arena — Biznes va Tizim Sozlamalari Sahifasi
// Aqlli Chiroqlar (Smart Switch & Tuya / Wi-Fi Relay),
// Mijoz To'lov Kartasi, Chek Printer, Majburiy Bulut Zaxirasi
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/models/business_account.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/providers/business_account_provider.dart';
import '../../../core/services/smart_light_service.dart';
import '../../../core/theme/ui_scale_provider.dart';
import '../../../core/utils/receipt_generator.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/database_providers.dart';
import '../../tables/providers/tables_providers.dart';
import '../models/business_settings.dart';
import '../providers/business_settings_provider.dart';
import '../widgets/customer_payment_card_view.dart';

class BusinessSettingsScreen extends ConsumerStatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  ConsumerState<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends ConsumerState<BusinessSettingsScreen> {
  // Aqlli chiroqlar
  late bool _smartLightsEnabled;
  late String _smartLightType;
  late TextEditingController _tuyaAccessIdController;
  late TextEditingController _tuyaAccessSecretController;
  late TextEditingController _tuyaDeviceIdController;
  late TextEditingController _localRelayIpController;

  // Mijoz to'lov kartasi
  late bool _cardPaymentEnabled;
  late TextEditingController _cardNumberController;
  late TextEditingController _cardHolderController;
  late TextEditingController _bankNameController;

  // Chek Printer
  late bool _printerEnabled;
  late String _paperFormat;
  late TextEditingController _receiptTitleController;
  late TextEditingController _receiptFooterController;

  bool _isForceSyncing = false;
  bool _isTestingLight = false;
  int _selectedTestChannel = 1;
  String? _testLightResult;

  @override
  void initState() {
    super.initState();
    final s = ref.read(businessSettingsProvider);

    _smartLightsEnabled = s.smartLightsEnabled;
    _smartLightType = s.smartLightType;
    _tuyaAccessIdController = TextEditingController(text: s.tuyaAccessId);
    _tuyaAccessSecretController = TextEditingController(text: s.tuyaAccessSecret);
    _tuyaDeviceIdController = TextEditingController(text: s.tuyaDeviceId);
    _localRelayIpController = TextEditingController(text: s.localRelayIp);

    _cardPaymentEnabled = s.cardPaymentEnabled;
    _cardNumberController = TextEditingController(text: s.cardNumber);
    _cardHolderController = TextEditingController(text: s.cardHolder);
    _bankNameController = TextEditingController(text: s.bankName);

    _printerEnabled = s.printerEnabled;
    _paperFormat = s.paperFormat;
    _receiptTitleController = TextEditingController(text: s.receiptTitle);
    _receiptFooterController = TextEditingController(text: s.receiptFooter);
  }

  @override
  void dispose() {
    _tuyaAccessIdController.dispose();
    _tuyaAccessSecretController.dispose();
    _tuyaDeviceIdController.dispose();
    _localRelayIpController.dispose();

    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _bankNameController.dispose();

    _receiptTitleController.dispose();
    _receiptFooterController.dispose();
    super.dispose();
  }

  void _saveAllSettings() {
    final notifier = ref.read(businessSettingsProvider.notifier);
    final current = ref.read(businessSettingsProvider);

    final updated = current.copyWith(
      smartLightsEnabled: _smartLightsEnabled,
      smartLightType: _smartLightType,
      tuyaAccessId: _tuyaAccessIdController.text.trim(),
      tuyaAccessSecret: _tuyaAccessSecretController.text.trim(),
      tuyaDeviceId: _tuyaDeviceIdController.text.trim(),
      localRelayIp: _localRelayIpController.text.trim(),
      cardPaymentEnabled: _cardPaymentEnabled,
      cardNumber: _cardNumberController.text.trim(),
      cardHolder: _cardHolderController.text.trim(),
      bankName: _bankNameController.text.trim(),
      printerEnabled: _printerEnabled,
      paperFormat: _paperFormat,
      receiptTitle: _receiptTitleController.text.trim(),
      receiptFooter: _receiptFooterController.text.trim(),
    );

    notifier.saveSettings(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Barcha sozlamalar muvaffaqiyatli saqlandi!"),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _runForceSync() async {
    setState(() => _isForceSyncing = true);
    try {
      final sync = ref.read(syncServiceProvider);
      await sync.syncAll();
      final now = DateTime.now();
      await ref.read(businessSettingsProvider.notifier).recordSyncTime(now);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Barcha ma'lumotlar bulutli bazaga to'liq yuklandi!"),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Yuklashda xatolik: $e"),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isForceSyncing = false);
      }
    }
  }

  Future<void> _testLightCommand(int channel, bool state) async {
    setState(() {
      _isTestingLight = true;
      _testLightResult = null;
    });

    try {
      final smartService = ref.read(smartLightServiceProvider);
      // Vaqtincha kiritilgan qiymatlarni hisobga olib tekshirish
      _saveAllSettings();
      final ok = await smartService.setLightState(channel: channel, state: state);
      setState(() {
        _testLightResult = ok
            ? "Kanal $channel muvaffaqiyatli ${state ? 'YOQILDI' : 'O\'CHIRILDI'}!"
            : "Kanal $channel bilan bog'lanib bo'lmadi. IP yoki Tuya sozlamalarini tekshiring.";
      });
    } catch (e) {
      setState(() {
        _testLightResult = "Xatolik: $e";
      });
    } finally {
      setState(() => _isTestingLight = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessState = ref.watch(businessAccountProvider);
    final activeVenue = businessState.activeAccount;
    final settings = ref.watch(businessSettingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () {
            _saveAllSettings();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Biznes va Tizim Sozlamalari",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _saveAllSettings,
            icon: const Icon(Icons.check_rounded, color: Color(0xFF2563EB), size: 20),
            label: const Text(
              "Saqlash",
              style: TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const Gap(8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. MAJBURIY BAZAGA YUKLASH (Bulut Zaxirasi) ────────
            _buildForceSyncCard(settings),

            const Gap(16),

            // ── 2. AQLI CHIROQLAR (Smart Switch & Tuya / Wi-Fi) ───
            _buildSmartLightsCard(),

            const Gap(16),

            // ── 3. MIJOZLAR UCHUN TO'LOV KARTASI ─────────────────
            _buildCustomerPaymentCard(),

            const Gap(16),

            // ── 4. CHEK PRINTER SOZLAMALARI ──────────────────────
            _buildReceiptPrinterCard(),

            const Gap(16),

            // ── 5. AKKAUNT VA BIZNES PROFILI ─────────────────────
            _buildVenueProfileCard(activeVenue),

            const Gap(16),

            // ── 6. EKRAN VA SHRIFT MASSHTABI ─────────────────────
            _buildScreenScaleCard(),

            const Gap(32),
          ],
        ),
      ),
    );
  }

  // ── 1. Majburiy Bazaga Yuklash Kartasi ─────────────────────
  Widget _buildForceSyncCard(BusinessSettings settings) {
    final syncTimeStr = settings.lastSyncTime != null
        ? DateFormat('dd.MM.yyyy HH:mm:ss').format(settings.lastSyncTime!)
        : "Hali yuklanmagan";

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.cloud_sync_rounded, color: Color(0xFF2563EB), size: 22),
              ),
              const Gap(12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Bulutli Baza Sinxronizatsiyasi",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      "Internet bor paytda barcha ma'lumotlarni bulutga zaxiralash",
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Oxirgi to'liq yuklash:",
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                Text(
                  syncTimeStr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          const Gap(14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isForceSyncing ? null : _runForceSync,
              icon: _isForceSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.upload_rounded),
              label: Text(
                _isForceSyncing
                    ? "Bazaga yuklanmoqda..."
                    : "Majburiy Bazaga Yuklash (Bulut Zaxirasi)",
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Aqlli Chiroqlar Kartasi ─────────────────────────────
  Widget _buildSmartLightsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lightbulb_rounded, color: Color(0xFFD97706), size: 22),
                  ),
                  const Gap(12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Aqlli Chiroqlar (Smart Switch)",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        "O'yinda avtomatik yoqish / o'chirish",
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              Switch.adaptive(
                value: _smartLightsEnabled,
                activeColor: const Color(0xFF2563EB),
                onChanged: (val) {
                  setState(() => _smartLightsEnabled = val);
                },
              ),
            ],
          ),

          if (_smartLightsEnabled) ...[
            const Gap(16),
            const Divider(height: 1),
            const Gap(16),

            // Rejim tanlash: Lokal Wi-Fi yoki Tuya Cloud
            const Text(
              "ULANISH TURI / MINI QURILMA:",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const Gap(8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _smartLightType = 'local_wifi'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      decoration: BoxDecoration(
                        color: _smartLightType == 'local_wifi'
                            ? const Color(0xFFEFF6FF)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _smartLightType == 'local_wifi'
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.wifi_rounded,
                            color: _smartLightType == 'local_wifi'
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF64748B),
                          ),
                          const Gap(4),
                          Text(
                            "Internetga ulangan Lokal Wi-Fi Relay",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _smartLightType == 'local_wifi'
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const Text(
                            "(Router orqali lokal va internetsiz ishlaydi)",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _smartLightType = 'tuya'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      decoration: BoxDecoration(
                        color: _smartLightType == 'tuya'
                            ? const Color(0xFFEFF6FF)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _smartLightType == 'tuya'
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_outlined,
                            color: _smartLightType == 'tuya'
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF64748B),
                          ),
                          const Gap(4),
                          Text(
                            "Tuya / Smart Life",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _smartLightType == 'tuya'
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const Text(
                            "(Cloud API orqali)",
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

            // Agar Lokal Wi-Fi Rele bo'lsa
            if (_smartLightType == 'local_wifi') ...[
              _buildTextField(
                controller: _localRelayIpController,
                label: "Mini Qurilma Lokal IP Manzili",
                hint: "Masalan: 192.168.4.1 yoki 192.168.1.100",
                icon: Icons.router_rounded,
                onChanged: (_) => setState(() {}),
              ),
              const Gap(8),

              // Tezkor IP tanlash
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.wifi_tethering_rounded, size: 16, color: Color(0xFF2563EB)),
                      label: const Text("Routersiz (192.168.4.1)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      backgroundColor: const Color(0xFFEFF6FF),
                      onPressed: () {
                        setState(() {
                          _localRelayIpController.text = "192.168.4.1";
                        });
                      },
                    ),
                    const Gap(6),
                    ActionChip(
                      avatar: const Icon(Icons.router_rounded, size: 16, color: Color(0xFF059669)),
                      label: const Text("Router 1 (192.168.1.100)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      backgroundColor: const Color(0xFFECFDF5),
                      onPressed: () {
                        setState(() {
                          _localRelayIpController.text = "192.168.1.100";
                        });
                      },
                    ),
                    const Gap(6),
                    ActionChip(
                      avatar: const Icon(Icons.router_rounded, size: 16, color: Color(0xFFD97706)),
                      label: const Text("Router 2 (192.168.0.100)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      backgroundColor: const Color(0xFFFFFBEB),
                      onPressed: () {
                        setState(() {
                          _localRelayIpController.text = "192.168.0.100";
                        });
                      },
                    ),
                  ],
                ),
              ),

              const Gap(8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final ip = _localRelayIpController.text.trim();
                        final res = await ref.read(smartLightServiceProvider).checkDeviceStatus(customIp: ip);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res['message'] as String),
                              backgroundColor: res['online'] == true
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.sensors_rounded, size: 16),
                      label: const Text("Aloqani Tekshirish (Ping)", style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showWiringGuideDialog,
                      icon: const Icon(Icons.cable_rounded, size: 16),
                      label: const Text("Ulash Sxemasi", style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(6),
              const Text(
                "💡 Bilyardxona/zaldagi ESP32 yoki Wi-Fi rele modul IP manzili. Router bo'lmasa '192.168.4.1' tanlang.",
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
              ),
            ] else ...[
              // Tuya Cloud parametrlari
              _buildTextField(
                controller: _tuyaAccessIdController,
                label: "Tuya Access ID (Client ID)",
                hint: "Tuya Developer Console dan olingan ID",
                icon: Icons.key_rounded,
              ),
              const Gap(12),
              _buildTextField(
                controller: _tuyaAccessSecretController,
                label: "Tuya Access Secret",
                hint: "Tuya Developer Access Secret",
                icon: Icons.lock_outline_rounded,
                isPassword: true,
              ),
              const Gap(12),
              _buildTextField(
                controller: _tuyaDeviceIdController,
                label: "Tuya Device ID (Aqlli switch)",
                hint: "Aqlli switch qurilmasi ID raqami",
                icon: Icons.developer_board_rounded,
              ),
            ],

            const Gap(18),

            // Stollarni Rele kanallariga biriktirish
            const Text(
              "STOLLAR VA CHIROQ KANALLARI MOSLIGI:",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const Gap(8),
            Consumer(
              builder: (context, ref, _) {
                final tablesAsync = ref.watch(tablesStreamProvider);
                return tablesAsync.when(
                  data: (tables) {
                    if (tables.isEmpty) {
                      return const Text("Hozircha stollar qo'shilmagan.",
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)));
                    }
                    final channels = ref.watch(businessSettingsProvider).tableRelayChannels;
                    return Column(
                      children: tables.map((table) {
                        final currentCh = channels[table.id] ?? 1;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.table_restaurant_rounded, size: 18, color: Color(0xFF2563EB)),
                                  const Gap(8),
                                  Text(
                                    table.name,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text("Rele: ", style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                  DropdownButton<int>(
                                    value: currentCh,
                                    underline: const SizedBox(),
                                    items: List.generate(16, (i) => i + 1).map((ch) {
                                      return DropdownMenuItem(
                                        value: ch,
                                        child: Text(
                                          "$ch-Kanal",
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (newCh) {
                                      if (newCh != null) {
                                        ref.read(businessSettingsProvider.notifier).setTableRelayChannel(table.id, newCh);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text("Xatolik: $e", style: const TextStyle(fontSize: 12)),
                );
              },
            ),

            const Gap(14),

            // Test yoqish/o'chirish tugmalari
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Chiroqni Sinab Ko'rish:",
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: DropdownButton<int>(
                          value: _selectedTestChannel,
                          isDense: true,
                          underline: const SizedBox(),
                          items: [1, 2, 3, 4].map((ch) {
                            return DropdownMenuItem(
                              value: ch,
                              child: Text(
                                "$ch-Stol Chirog'i",
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedTestChannel = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const Gap(10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTestingLight ? null : () => _testLightCommand(_selectedTestChannel, true),
                          icon: const Icon(Icons.flash_on_rounded, size: 16),
                          label: Text("$_selectedTestChannel-Chiroqni Yoqish"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTestingLight ? null : () => _testLightCommand(_selectedTestChannel, false),
                          icon: const Icon(Icons.flash_off_rounded, size: 16),
                          label: const Text("O'chirish"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_testLightResult != null) ...[
                    const Gap(8),
                    Text(
                      _testLightResult!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _testLightResult!.contains('muvaffaqiyatli')
                            ? const Color(0xFF047857)
                            : const Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showWiringGuideDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cable_rounded, color: Color(0xFF2563EB)),
            Gap(8),
            Text("Simlarni Ulash Sxemasi", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "ESP32 va 4-Kanalli Rele Modulini Bog'lash:",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const Gap(10),
              _buildWiringRow("GND (Qora)", "GND", const Color(0xFF475569)),
              _buildWiringRow("VIN / 5V (Qizil)", "VCC", const Color(0xFFDC2626)),
              _buildWiringRow("GPIO 23 (D23)", "IN1 (1-Stol)", const Color(0xFF2563EB)),
              _buildWiringRow("GPIO 22 (D22)", "IN2 (2-Stol)", const Color(0xFF059669)),
              _buildWiringRow("GPIO 21 (D21)", "IN3 (3-Stol)", const Color(0xFFD97706)),
              _buildWiringRow("GPIO 19 (D19)", "IN4 (4-Stol)", const Color(0xFF7C3AED)),
              const Gap(14),
              const Text(
                "220V Chiroq Simlarini Ulash:",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const Gap(6),
              const Text(
                "Har bir relening 3 ta teshigi bor:\n"
                "• [COM] - 220V faza simi ulanadi.\n"
                "• [NO] - Lampochkaga ketadigan sim ulanadi.\n"
                "• Quvvat: ESP32 ga oddiy telefon zaryadkasini tiqib qo'yasiz.",
                style: TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            child: const Text("Tushundim"),
          ),
        ],
      ),
    );
  }

  static Widget _buildWiringRow(String from, String to, Color dotColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const Gap(8),
              Text(from, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF94A3B8)),
          Text(to, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
        ],
      ),
    );
  }

  // ── 3. Mijoz To'lov Kartasi Kartasi ────────────────────────
  Widget _buildCustomerPaymentCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.credit_card_rounded, color: Color(0xFF2563EB), size: 22),
                  ),
                  const Gap(12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Mijozlar Uchun To'lov Kartasi",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        "Kassada ko'rsatiladigan bank rekviziti",
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              Switch.adaptive(
                value: _cardPaymentEnabled,
                activeColor: const Color(0xFF2563EB),
                onChanged: (val) {
                  setState(() => _cardPaymentEnabled = val);
                },
              ),
            ],
          ),

          if (_cardPaymentEnabled) ...[
            const Gap(16),
            const Divider(height: 1),
            const Gap(16),

            _buildTextField(
              controller: _cardNumberController,
              label: "Karta Raqami (16 xonali)",
              hint: "8600 0000 0000 0000 yoki 9860 ...",
              icon: Icons.payment_rounded,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
              ],
              onChanged: (_) => setState(() {}),
            ),

            const Gap(12),

            _buildTextField(
              controller: _cardHolderController,
              label: "Karta Egasi Ism-Familiyasi",
              hint: "Masalan: SAMAR BAXTIYOROV",
              icon: Icons.person_outline_rounded,
              onChanged: (_) => setState(() {}),
            ),

            const Gap(12),

            _buildTextField(
              controller: _bankNameController,
              label: "Bank Nomi",
              hint: "Masalan: Kapitalbank, TBC, Agrobank",
              icon: Icons.account_balance_rounded,
              onChanged: (_) => setState(() {}),
            ),

            const Gap(16),

            const Text(
              "JONLI KARTA KO'RINISHI (PREVIEW):",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const Gap(8),

            // Real-time Preview Card
            CustomerPaymentCardView(
              settings: BusinessSettings(
                cardPaymentEnabled: true,
                cardNumber: _cardNumberController.text.trim(),
                cardHolder: _cardHolderController.text.trim(),
                bankName: _bankNameController.text.trim(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 4. Chek Printer Sozlamalari ────────────────────────────
  Widget _buildReceiptPrinterCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.print_rounded, color: Color(0xFF9333EA), size: 22),
                  ),
                  const Gap(12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Chek Printer Sozlamalari",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        "Qog'oz o'lchami va chek matnlari",
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              Switch.adaptive(
                value: _printerEnabled,
                activeColor: const Color(0xFF2563EB),
                onChanged: (val) {
                  setState(() => _printerEnabled = val);
                },
              ),
            ],
          ),

          if (_printerEnabled) ...[
            const Gap(16),
            const Divider(height: 1),
            const Gap(16),

            // Format tanlash (58mm yoki 80mm)
            const Text(
              "QOG'OZ FORMATI:",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const Gap(8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text("58 mm (Standart POS)"),
                    selected: _paperFormat == '58mm',
                    selectedColor: const Color(0xFFDBEAFE),
                    onSelected: (val) {
                      if (val) setState(() => _paperFormat = '58mm');
                    },
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: ChoiceChip(
                    label: const Text("80 mm (Keng chek)"),
                    selected: _paperFormat == '80mm',
                    selectedColor: const Color(0xFFDBEAFE),
                    onSelected: (val) {
                      if (val) setState(() => _paperFormat = '80mm');
                    },
                  ),
                ),
              ],
            ),

            const Gap(16),

            _buildTextField(
              controller: _receiptTitleController,
              label: "Chek Sarlavhasi (Muassasa Nomi)",
              hint: "Masalan: ARENA BILARD & PS5",
              icon: Icons.title_rounded,
            ),

            const Gap(12),

            _buildTextField(
              controller: _receiptFooterController,
              label: "Chek Osti Xabari (Footer)",
              hint: "Masalan: Tashrifingiz uchun rahmat! Yana kuting!",
              icon: Icons.chat_bubble_outline_rounded,
            ),

            const Gap(14),

            OutlinedButton.icon(
              onPressed: () {
                _showSampleReceiptDialog();
              },
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: const Text("Namunaviy Chekni Ko'rish"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSampleReceiptDialog() {
    final sample = ReceiptGenerator.forTableSession(
      table: ClubTable(
        id: 'sample',
        name: '1-Bilyard Stoli',
        type: 'billiard',
        pricePerHour: 30000,
        isActive: true,
        sortOrder: 1,
        isSynced: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      session: Session(
        id: '12345678-test',
        tableId: 'sample',
        startedAt: DateTime.now().subtract(const Duration(minutes: 75)),
        endedAt: DateTime.now(),
        status: 'finished',
        durationMin: 75,
        totalAmount: 45000,
        paymentType: 'card',
        isSynced: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      finalAmount: 45000,
      paymentType: 'card',
      headerTitle: _receiptTitleController.text.trim().isEmpty
          ? 'ARENA'
          : _receiptTitleController.text.trim(),
      footerMessage: _receiptFooterController.text.trim().isEmpty
          ? 'Tashrifingiz uchun rahmat!'
          : _receiptFooterController.text.trim(),
      width: _paperFormat == '80mm' ? 42 : ReceiptGenerator.width58,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Namunaviy Chek Ko'rinishi"),
        content: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(12),
          color: const Color(0xFFF1F5F9),
          child: SingleChildScrollView(
            child: Text(
              sample,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Yopish")),
        ],
      ),
    );
  }

  // ── 5. Venue / Profil Kartasi ──────────────────────────────
  Widget _buildVenueProfileCard(BusinessAccount? activeVenue) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business_rounded, color: Color(0xFF2563EB), size: 22),
              ),
              const Gap(12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeVenue?.venueName ?? "Arena Majmuasi",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    "Boshliq: ${activeVenue?.ownerName ?? 'Ega'} • Tel: ${activeVenue?.phone ?? ''}",
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          const Gap(16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showEditProfileDialog(activeVenue);
                  },
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const Text("Tahrirlash"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const Gap(10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    ref.read(businessAccountProvider.notifier).logoutToAuthScreen();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.switch_account_rounded, size: 18, color: Color(0xFFDC2626)),
                  label: const Text("Hisob almashtirish", style: TextStyle(color: Color(0xFFDC2626))),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BusinessAccount? activeVenue) {
    if (activeVenue == null) return;
    final nameCtrl = TextEditingController(text: activeVenue.venueName);
    final ownerCtrl = TextEditingController(text: activeVenue.ownerName);
    final phoneCtrl = TextEditingController(text: activeVenue.phone);
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Majmua va Parolni Tahrirlash"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Majmua nomi", prefixIcon: Icon(Icons.stadium_rounded)),
              ),
              const Gap(10),
              TextField(
                controller: ownerCtrl,
                decoration: const InputDecoration(labelText: "Boshliq ismi", prefixIcon: Icon(Icons.person_rounded)),
              ),
              const Gap(10),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: "Telefon", prefixIcon: Icon(Icons.phone_rounded)),
              ),
              const Gap(10),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Yangi parol (o'zgartirish ixtiyoriy)",
                  prefixIcon: Icon(Icons.lock_rounded),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Bekor qilish")),
          ElevatedButton(
            onPressed: () async {
              await ref.read(businessAccountProvider.notifier).updateAccountInfo(
                venueName: nameCtrl.text.trim(),
                ownerName: ownerCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                newPassword: passCtrl.text.trim().isNotEmpty ? passCtrl.text.trim() : null,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Saqlash"),
          ),
        ],
      ),
    );
  }

  // ── 6. Ekran Masshtabi ─────────────────────────────────────
  Widget _buildScreenScaleCard() {
    final currentScale = ref.watch(uiScaleProvider);
    final notifier = ref.read(uiScaleProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.zoom_in_rounded, color: Color(0xFF2563EB), size: 22),
              Gap(10),
              Text(
                "Shrift va Ekran Masshtabi",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text("Kichik (85%)"),
                  selected: currentScale == UiScale.small,
                  onSelected: (_) => notifier.setScale(UiScale.small),
                ),
              ),
              const Gap(8),
              Expanded(
                child: ChoiceChip(
                  label: const Text("O'rta (100%)"),
                  selected: currentScale == UiScale.medium,
                  onSelected: (_) => notifier.setScale(UiScale.medium),
                ),
              ),
              const Gap(8),
              Expanded(
                child: ChoiceChip(
                  label: const Text("Katta (115%)"),
                  selected: currentScale == UiScale.large,
                  onSelected: (_) => notifier.setScale(UiScale.large),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
        ),
        const Gap(6),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
