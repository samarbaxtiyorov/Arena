import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../features/management/models/business_settings.dart';
import '../../features/management/providers/business_settings_provider.dart';

class SmartLightService {
  final Ref _ref;

  SmartLightService(this._ref);

  BusinessSettings get _settings => _ref.read(businessSettingsProvider);

  /// Stol/maydon ochilganda chiroqni avtomatik yoqish
  Future<bool> turnOn(String tableId, {String? tableName}) async {
    final settings = _settings;
    if (!settings.smartLightsEnabled) return false;

    final channel = settings.tableRelayChannels[tableId] ?? 1;
    debugPrint("💡 [SmartLight] Stol ochildi: $tableId ($tableName) -> Kanal $channel YOQILMOQDA...");
    return await setLightState(channel: channel, state: true);
  }

  /// Stol sessiyasi yopilganda / to'lov tasdiqlanganda chiroqni avtomatik o'chirish
  Future<bool> turnOff(String tableId, {String? tableName}) async {
    final settings = _settings;
    if (!settings.smartLightsEnabled) return false;

    final channel = settings.tableRelayChannels[tableId] ?? 1;
    debugPrint("💡 [SmartLight] Stol yopildi: $tableId ($tableName) -> Kanal $channel O'CHIRILMOQDA...");
    return await setLightState(channel: channel, state: false);
  }

  /// Aniq bir rele kanali uchun chiroqni yoqish/o'chirish
  Future<bool> setLightState({required int channel, required bool state}) async {
    final settings = _settings;
    if (settings.smartLightType == 'local_wifi') {
      return await _sendLocalRelayCommand(
        ip: settings.localRelayIp,
        channel: channel,
        state: state,
      );
    } else {
      return await _sendTuyaCommand(
        accessId: settings.tuyaAccessId,
        accessSecret: settings.tuyaAccessSecret,
        endpoint: settings.tuyaEndpoint,
        deviceId: settings.tuyaDeviceId,
        channel: channel,
        state: state,
      );
    }
  }

  /// 1. Lokal Wi-Fi Rele (ESP8266 / Tasmota / Shelly / Maxsus Mini plata)
  /// INTERNETSIZ HAM ISHLAYDI: Lokal Wi-Fi tarmog'i orqali to'g'ridan-to'g'ri so'rov yuboradi.
  Future<bool> _sendLocalRelayCommand({
    required String ip,
    required int channel,
    required bool state,
  }) async {
    if (ip.trim().isEmpty) return false;

    final stateStr = state ? 'on' : 'off';
    final stateNum = state ? '1' : '0';
    final cleanIp = ip.trim().replaceAll('http://', '').replaceAll('/', '');

    // Har xil mashhur Wi-Fi relay protokollari bilan moslashuvchan ulanish
    final urlsToTry = [
      // Standart REST / Mini relay protokoli
      Uri.parse('http://$cleanIp/relay/$channel/$stateStr'),
      // Tasmota / Sonoff protokoli (Power1 ON / Power1 OFF)
      Uri.parse('http://$cleanIp/cm?cmnd=Power$channel%20${state ? "ON" : "OFF"}'),
      // ESP8266 / Arduino WebServer protokoli
      Uri.parse('http://$cleanIp/control?relay=$channel&state=$stateNum'),
      // Shelly protokoli
      Uri.parse('http://$cleanIp/relay/${channel - 1}?turn=$stateStr'),
    ];

    for (final url in urlsToTry) {
      try {
        final response = await http.get(url).timeout(const Duration(milliseconds: 1500));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          debugPrint("✅ [SmartLight] Wi-Fi Relay muvaffaqiyatli: $url -> ${response.body}");
          return true;
        }
      } catch (_) {
        // Keyingi protokol variantini sinab ko'radi
      }
    }

    debugPrint("⚠️ [SmartLight] Wi-Fi Relay ($cleanIp) bilan bog'lanish amalga oshmadi.");
    return false;
  }

  /// 2. Tuya / Smart Life Cloud OpenAPI
  Future<bool> _sendTuyaCommand({
    required String accessId,
    required String accessSecret,
    required String endpoint,
    required String deviceId,
    required int channel,
    required bool state,
  }) async {
    if (accessId.trim().isEmpty || accessSecret.trim().isEmpty || deviceId.trim().isEmpty) {
      return false;
    }

    try {
      final t = DateTime.now().millisecondsSinceEpoch.toString();
      final cleanEndpoint = endpoint.trim().replaceAll(RegExp(r'/+$'), '');

      // Tuya Token olish
      final tokenPath = '/v1.0/token?grant_type=1';
      final stringToSign = '$accessId$t' 'GET\n'
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\n\n$tokenPath';
      final hmac = Hmac(sha256, utf8.encode(accessSecret));
      final sign = hmac.convert(utf8.encode(stringToSign)).toString().toUpperCase();

      final tokenRes = await http.get(
        Uri.parse('$cleanEndpoint$tokenPath'),
        headers: {
          'client_id': accessId,
          'sign': sign,
          't': t,
          'sign_method': 'HMAC-SHA256',
        },
      ).timeout(const Duration(seconds: 4));

      if (tokenRes.statusCode == 200) {
        final tokenData = jsonDecode(tokenRes.body);
        if (tokenData['success'] == true) {
          final accessToken = tokenData['result']['access_token'];

          // Buyruq yuborish
          final cmdPath = '/v1.0/devices/$deviceId/commands';
          final bodyJson = jsonEncode({
            'commands': [
              {
                'code': 'switch_$channel',
                'value': state,
              }
            ]
          });

          final contentSha256 = sha256.convert(utf8.encode(bodyJson)).toString();
          final tCmd = DateTime.now().millisecondsSinceEpoch.toString();
          final stringToSignCmd = '$accessId$accessToken$tCmd' 'POST\n'
              '$contentSha256\n\n$cmdPath';
          final signCmd = hmac.convert(utf8.encode(stringToSignCmd)).toString().toUpperCase();

          final cmdRes = await http.post(
            Uri.parse('$cleanEndpoint$cmdPath'),
            headers: {
              'client_id': accessId,
              'access_token': accessToken,
              'sign': signCmd,
              't': tCmd,
              'sign_method': 'HMAC-SHA256',
              'Content-Type': 'application/json',
            },
            body: bodyJson,
          ).timeout(const Duration(seconds: 4));

          if (cmdRes.statusCode == 200) {
            debugPrint("✅ [Tuya SmartLight] Buyruq muvaffaqiyatli yuborildi: $state");
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint("❌ [Tuya SmartLight] Xatolik: $e");
    }

    return false;
  }
}

final smartLightServiceProvider = Provider<SmartLightService>((ref) {
  return SmartLightService(ref);
});
