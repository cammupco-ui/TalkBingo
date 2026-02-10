import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;

import 'package:flutter/foundation.dart';
import 'payment_service.dart';

/// Toss Payments integration for Flutter Web
/// Uses Toss Payments JavaScript SDK via dart:js interop
///
/// Flow:
/// 1. Client calls PaymentService.createPayment() → gets orderId, amount
/// 2. Client calls TossPaymentService.requestPayment() → opens Toss checkout UI
/// 3. Toss redirects to success URL with paymentKey
/// 4. Client calls PaymentService.verifyPayment() → Edge Function confirms with Toss
class TossPaymentService {
  static final TossPaymentService _instance = TossPaymentService._internal();
  factory TossPaymentService() => _instance;
  TossPaymentService._internal();

  bool _sdkLoaded = false;

  // Placeholder - replace with actual Toss client key
  // Test key format: test_ck_... | Live key format: live_ck_...
  static const String _tossClientKey = String.fromEnvironment(
    'TOSS_CLIENT_KEY',
    defaultValue: 'test_ck_PLACEHOLDER',
  );

  /// Load Toss Payments JavaScript SDK dynamically
  Future<void> loadSDK() async {
    if (_sdkLoaded) return;
    if (!kIsWeb) return;

    // Check if already loaded
    if (js.context.hasProperty('TossPayments')) {
      _sdkLoaded = true;
      return;
    }

    final completer = html.ScriptElement()
      ..src = 'https://js.tosspayments.com/v1/payment'
      ..type = 'text/javascript';

    final loadFuture = completer.onLoad.first;
    html.document.head!.children.add(completer);

    await loadFuture;
    _sdkLoaded = true;
    debugPrint('✅ Toss Payments SDK loaded');
  }

  /// Request payment via Toss Payments checkout UI
  /// 
  /// [paymentInfo] - Result from PaymentService.createPayment()
  /// [customerEmail] - Optional customer email for receipt
  Future<void> requestPayment({
    required CreatePaymentResult paymentInfo,
    String? customerEmail,
    String? customerName,
  }) async {
    if (!kIsWeb) {
      throw PaymentException('Toss Payments는 현재 웹에서만 지원됩니다.');
    }

    await loadSDK();

    if (!js.context.hasProperty('TossPayments')) {
      throw PaymentException('Toss SDK 로드에 실패했습니다.');
    }

    // Get the current URL for success/fail redirects
    final baseUrl = html.window.location.origin;
    final currentHash = html.window.location.hash;

    final successUrl = '$baseUrl$currentHash?payment=success';
    final failUrl = '$baseUrl$currentHash?payment=fail';

    try {
      // Initialize TossPayments
      final tossPayments = js.context.callMethod('TossPayments', [_tossClientKey]);

      if (paymentInfo.gateway == 'toss_paypal') {
        // PayPal (Foreign payment)
        tossPayments.callMethod('requestPayment', [
          '해외간편결제',
          js.JsObject.jsify({
            'amount': paymentInfo.amount,
            'orderId': paymentInfo.orderId,
            'orderName': paymentInfo.orderName,
            'successUrl': successUrl,
            'failUrl': failUrl,
            'flowMode': 'DIRECT',
            'easyPay': 'PAYPAL',
            if (customerEmail != null) 'customerEmail': customerEmail,
            if (customerName != null) 'customerName': customerName,
          }),
        ]);
      } else {
        // Domestic payment (card, easy pay, etc.)
        tossPayments.callMethod('requestPayment', [
          '카드',
          js.JsObject.jsify({
            'amount': paymentInfo.amount,
            'orderId': paymentInfo.orderId,
            'orderName': paymentInfo.orderName,
            'successUrl': successUrl,
            'failUrl': failUrl,
            if (customerEmail != null) 'customerEmail': customerEmail,
            if (customerName != null) 'customerName': customerName,
          }),
        ]);
      }
    } catch (e) {
      debugPrint('Toss requestPayment error: $e');
      throw PaymentException('결제 요청 중 오류가 발생했습니다: $e');
    }
  }

  /// Check URL for payment callback parameters
  /// Call this on page load to handle Toss redirects
  static PaymentCallbackResult? checkPaymentCallback() {
    if (!kIsWeb) return null;

    final uri = Uri.parse(html.window.location.href);
    final paymentStatus = uri.queryParameters['payment'];

    if (paymentStatus == 'success') {
      final paymentKey = uri.queryParameters['paymentKey'];
      final orderId = uri.queryParameters['orderId'];
      final amount = int.tryParse(uri.queryParameters['amount'] ?? '');

      if (paymentKey != null && orderId != null && amount != null) {
        // Clean URL after processing
        _cleanPaymentUrl();
        return PaymentCallbackResult(
          success: true,
          paymentKey: paymentKey,
          orderId: orderId,
          amount: amount,
        );
      }
    } else if (paymentStatus == 'fail') {
      final code = uri.queryParameters['code'];
      final message = uri.queryParameters['message'];
      _cleanPaymentUrl();
      return PaymentCallbackResult(
        success: false,
        errorCode: code,
        errorMessage: message,
      );
    }

    return null;
  }

  /// Remove payment-related query parameters from URL
  static void _cleanPaymentUrl() {
    if (!kIsWeb) return;
    
    final uri = Uri.parse(html.window.location.href);
    final cleanParams = Map<String, String>.from(uri.queryParameters)
      ..remove('payment')
      ..remove('paymentKey')
      ..remove('orderId')
      ..remove('amount')
      ..remove('code')
      ..remove('message');
    
    final cleanUri = uri.replace(queryParameters: cleanParams.isEmpty ? null : cleanParams);
    html.window.history.replaceState(null, '', cleanUri.toString());
  }
}

/// Result from Toss payment redirect callback
class PaymentCallbackResult {
  final bool success;
  final String? paymentKey;
  final String? orderId;
  final int? amount;
  final String? errorCode;
  final String? errorMessage;

  PaymentCallbackResult({
    required this.success,
    this.paymentKey,
    this.orderId,
    this.amount,
    this.errorCode,
    this.errorMessage,
  });
}
