import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class TezCheckBillResult {
  final String billId;
  final String reference;
  final String paymentUrl;
  final int amountMinor;
  final DateTime availableUntil;

  TezCheckBillResult({
    required this.billId,
    required this.reference,
    required this.paymentUrl,
    required this.amountMinor,
    required this.availableUntil,
  });

  int get amountSom => amountMinor ~/ 100;
}

class TezCheckBillStatus {
  final String billId;
  final String state; // 'active', 'paid', 'expired', 'cancelled'
  final bool isPaid;
  final DateTime? paidAt;
  final String? errorMessage;

  TezCheckBillStatus({
    required this.billId,
    required this.state,
    required this.isPaid,
    this.paidAt,
    this.errorMessage,
  });
}

class TezCheckPaymentService {
  static const String baseUrl = 'https://api.tezcheck.uz/api/merchant/v1';
  static const String cashDeskCode = 'cdk_ySxY21zmotFZLnEBJF8AgJtjlOhC';
  static const String apiKey = 'aps_7etNNJBksbsU1OFV0JGpjcTIh_fN-a4UT9DU1DT-0ZE';

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $apiKey',
        'X-Cash-Desk-Code': cashDeskCode,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// 1. Hisob (To'lov havolasi) yaratish
  Future<TezCheckBillResult?> createSubscriptionBill({
    required int amountSom,
    required String title,
    required String externalReference,
  }) async {
    final amountMinor = amountSom * 100; // 1 so'm = 100 tiyin
    final url = Uri.parse('$baseUrl/bills');

    final body = jsonEncode({
      'amount_minor': amountMinor,
      'currency': 'UZS',
      'title': title,
      'external_reference': externalReference,
    });

    try {
      debugPrint("💳 [TezCheck] To'lov hisobi ochilmoqda: $title, Summa: $amountSom so'm");
      final response = await http
          .post(url, headers: _headers, body: body)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final resJson = jsonDecode(response.body);
        final data = resJson['data'];
        final bill = data['bill'];
        final paymentUrl = data['payment_url'] as String;

        return TezCheckBillResult(
          billId: bill['id'] as String,
          reference: bill['reference'] as String? ?? '',
          paymentUrl: paymentUrl,
          amountMinor: (bill['amount_minor'] as num).toInt(),
          availableUntil: DateTime.tryParse(bill['available_until'] as String? ?? '') ??
              DateTime.now().add(const Duration(minutes: 15)),
        );
      } else {
        debugPrint("❌ [TezCheck] Xatolik ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ [TezCheck] Ulanish xatosi: $e");
    }

    return null;
  }

  /// 2. Hisobning to'lov holatini tekshirish
  Future<TezCheckBillStatus> checkBillStatus(String billId) async {
    final url = Uri.parse('$baseUrl/bills/$billId');

    try {
      debugPrint("🔍 [TezCheck] To'lov holati tekshirilmoqda: $billId");
      final response = await http
          .post(url, headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final resJson = jsonDecode(response.body);
        final bill = resJson['data']?['bill'];
        if (bill != null) {
          final isPaid = bill['paid'] == true;
          final state = bill['state'] as String? ?? 'active';
          final paidAtStr = bill['paid_at'] as String?;

          return TezCheckBillStatus(
            billId: billId,
            state: state,
            isPaid: isPaid,
            paidAt: paidAtStr != null ? DateTime.tryParse(paidAtStr) : null,
          );
        }
      }

      return TezCheckBillStatus(
        billId: billId,
        state: 'unknown',
        isPaid: false,
        errorMessage: "Server javobi: ${response.statusCode}",
      );
    } catch (e) {
      return TezCheckBillStatus(
        billId: billId,
        state: 'error',
        isPaid: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 3. Kassa va API kalit faolligini tekshirish
  Future<bool> verifyConnection() async {
    final url = Uri.parse('$baseUrl/me');
    try {
      final response =
          await http.get(url, headers: _headers).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

final tezCheckPaymentServiceProvider = Provider<TezCheckPaymentService>((ref) {
  return TezCheckPaymentService();
});
