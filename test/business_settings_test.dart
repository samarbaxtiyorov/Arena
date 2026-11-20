import 'package:flutter_test/flutter_test.dart';
import 'package:arena/features/management/models/business_settings.dart';

void main() {
  group('BusinessSettings Model Tests', () {
    test('Default values are correct', () {
      const settings = BusinessSettings();
      expect(settings.smartLightsEnabled, isFalse);
      expect(settings.smartLightType, 'local_wifi');
      expect(settings.cardPaymentEnabled, isTrue);
      expect(settings.paperFormat, '58mm');
      expect(settings.localRelayIp, '192.168.1.100');
    });

    test('Serialization and Deserialization works cleanly', () {
      const original = BusinessSettings(
        smartLightsEnabled: true,
        smartLightType: 'tuya',
        tuyaAccessId: 'test_access_id',
        tuyaAccessSecret: 'test_secret',
        tuyaDeviceId: 'test_device',
        localRelayIp: '192.168.1.200',
        tableRelayChannels: {'table-1': 1, 'table-2': 2},
        cardPaymentEnabled: true,
        cardNumber: '8600123456789012',
        cardHolder: 'SAMAR BAXTIYOROV',
        bankName: 'Kapitalbank',
        printerEnabled: true,
        paperFormat: '80mm',
        receiptTitle: 'ARENA ARENA',
        receiptFooter: 'Rahmat!',
      );

      final jsonStr = original.toJson();
      final restored = BusinessSettings.fromJson(jsonStr);

      expect(restored.smartLightsEnabled, isTrue);
      expect(restored.smartLightType, 'tuya');
      expect(restored.tuyaAccessId, 'test_access_id');
      expect(restored.tuyaDeviceId, 'test_device');
      expect(restored.cardNumber, '8600123456789012');
      expect(restored.cardHolder, 'SAMAR BAXTIYOROV');
      expect(restored.bankName, 'Kapitalbank');
      expect(restored.paperFormat, '80mm');
      expect(restored.tableRelayChannels['table-2'], 2);
    });

    test('copyWith properly updates selective fields', () {
      const initial = BusinessSettings();
      final updated = initial.copyWith(
        smartLightsEnabled: true,
        cardNumber: '9860000000001111',
      );

      expect(updated.smartLightsEnabled, isTrue);
      expect(updated.cardNumber, '9860000000001111');
      expect(updated.smartLightType, 'local_wifi'); // unmodified
    });
  });
}
