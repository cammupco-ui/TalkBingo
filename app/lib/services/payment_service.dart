import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── VP Package Definitions ───────────────────────────────
class VPPackage {
  final String id;
  final int vp;
  final int bonusVp;
  final int krwPrice;
  final int usdPriceCents; // in cents (e.g. 399 = $3.99)
  final String labelKo;
  final String labelEn;
  final bool isBestValue;

  const VPPackage({
    required this.id,
    required this.vp,
    this.bonusVp = 0,
    required this.krwPrice,
    required this.usdPriceCents,
    required this.labelKo,
    required this.labelEn,
    this.isBestValue = false,
  });

  int get totalVp => vp + bonusVp;

  String displayPrice(String currency) {
    if (currency == 'KRW') {
      final formatted = krwPrice.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
      return '₩$formatted';
    } else {
      return '\$${(usdPriceCents / 100).toStringAsFixed(2)}';
    }
  }

  int getAmount(String currency) {
    return currency == 'KRW' ? krwPrice : usdPriceCents;
  }
}

// All available packages
const List<VPPackage> vpPackages = [
  VPPackage(
    id: 'vp_100',
    vp: 100,
    krwPrice: 1100,
    usdPriceCents: 99,
    labelKo: '100 VP',
    labelEn: '100 VP',
  ),
  VPPackage(
    id: 'vp_550',
    vp: 500,
    bonusVp: 50,
    krwPrice: 5500,
    usdPriceCents: 399,
    labelKo: '550 VP (500+50 보너스)',
    labelEn: '550 VP (500+50 Bonus)',
  ),
  VPPackage(
    id: 'vp_1200',
    vp: 1000,
    bonusVp: 200,
    krwPrice: 11000,
    usdPriceCents: 799,
    labelKo: '1,200 VP (1,000+200 보너스)',
    labelEn: '1,200 VP (1,000+200 Bonus)',
    isBestValue: true,
  ),
  VPPackage(
    id: 'vp_3500',
    vp: 2500,
    bonusVp: 1000,
    krwPrice: 33000,
    usdPriceCents: 2299,
    labelKo: '3,500 VP (2,500+1,000 보너스)',
    labelEn: '3,500 VP (2,500+1,000 Bonus)',
  ),
  VPPackage(
    id: 'vp_7000',
    vp: 5000,
    bonusVp: 2000,
    krwPrice: 64000,
    usdPriceCents: 4499,
    labelKo: '7,000 VP (5,000+2,000 보너스)',
    labelEn: '7,000 VP (5,000+2,000 Bonus)',
  ),
];

// ─── Payment Models ───────────────────────────────────────
enum PaymentGateway {
  tossDomestic,  // 국내: 카드, 카카오페이, 네이버페이, 토스페이
  tossPaypal,    // 해외: PayPal
}

enum PaymentStatus {
  pending,
  completed,
  failed,
  cancelled,
}

class PaymentRequest {
  final VPPackage package;
  final PaymentGateway gateway;

  const PaymentRequest({
    required this.package,
    required this.gateway,
  });

  String get gatewayString {
    switch (gateway) {
      case PaymentGateway.tossDomestic:
        return 'toss_domestic';
      case PaymentGateway.tossPaypal:
        return 'toss_paypal';
    }
  }

  String get currency => gateway == PaymentGateway.tossDomestic ? 'KRW' : 'USD';
}

class CreatePaymentResult {
  final String orderId;
  final int amount;
  final String currency;
  final String orderName;
  final String transactionId;
  final String gateway;

  CreatePaymentResult({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.orderName,
    required this.transactionId,
    required this.gateway,
  });

  factory CreatePaymentResult.fromJson(Map<String, dynamic> json) {
    return CreatePaymentResult(
      orderId: json['orderId'] as String,
      amount: json['amount'] as int,
      currency: json['currency'] as String,
      orderName: json['orderName'] as String,
      transactionId: json['transactionId'] as String,
      gateway: json['gateway'] as String,
    );
  }
}

class VerifyPaymentResult {
  final bool success;
  final int vpGranted;
  final int newVPBalance;
  final String transactionId;

  VerifyPaymentResult({
    required this.success,
    required this.vpGranted,
    required this.newVPBalance,
    required this.transactionId,
  });

  factory VerifyPaymentResult.fromJson(Map<String, dynamic> json) {
    return VerifyPaymentResult(
      success: json['success'] as bool,
      vpGranted: json['vpGranted'] as int,
      newVPBalance: json['newVPBalance'] as int,
      transactionId: json['transactionId'] as String,
    );
  }
}

class TransactionRecord {
  final String id;
  final String gateway;
  final String orderId;
  final int amount;
  final String currency;
  final int vpGranted;
  final String status;
  final DateTime createdAt;

  TransactionRecord({
    required this.id,
    required this.gateway,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.vpGranted,
    required this.status,
    required this.createdAt,
  });

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    return TransactionRecord(
      id: json['id'] as String,
      gateway: json['gateway'] as String,
      orderId: json['order_id'] as String,
      amount: json['amount'] as int,
      currency: json['currency'] as String,
      vpGranted: json['vp_granted'] as int,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// ─── Payment Service ──────────────────────────────────────
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final _supabase = Supabase.instance.client;

  /// Step 1: Create a payment session (calls create-payment Edge Function)
  Future<CreatePaymentResult> createPayment(PaymentRequest request) async {
    try {
      final response = await _supabase.functions.invoke(
        'create-payment',
        body: {
          'packageId': request.package.id,
          'gateway': request.gatewayString,
        },
      );

      if (response.status != 200) {
        final error = response.data is Map ? response.data['error'] : 'Unknown error';
        throw PaymentException('결제 생성 실패: $error');
      }

      return CreatePaymentResult.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (e is PaymentException) rethrow;
      debugPrint('PaymentService.createPayment error: $e');
      throw PaymentException('결제 요청 중 오류가 발생했습니다.');
    }
  }

  /// Step 2: Verify payment after Toss SDK callback (calls verify-payment Edge Function)
  Future<VerifyPaymentResult> verifyPayment({
    required String paymentKey,
    required String orderId,
    required int amount,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'verify-payment',
        body: {
          'paymentKey': paymentKey,
          'orderId': orderId,
          'amount': amount,
        },
      );

      if (response.status != 200) {
        final error = response.data is Map ? response.data['error'] : 'Unknown error';
        throw PaymentException('결제 검증 실패: $error');
      }

      return VerifyPaymentResult.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (e is PaymentException) rethrow;
      debugPrint('PaymentService.verifyPayment error: $e');
      throw PaymentException('결제 확인 중 오류가 발생했습니다.');
    }
  }

  /// Get user's transaction history
  Future<List<TransactionRecord>> getTransactionHistory({int limit = 20}) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => TransactionRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('PaymentService.getTransactionHistory error: $e');
      return [];
    }
  }

  /// Determine the default gateway based on locale
  static PaymentGateway getDefaultGateway(String languageCode) {
    return languageCode == 'ko'
        ? PaymentGateway.tossDomestic
        : PaymentGateway.tossPaypal;
  }
}

// ─── Exception ────────────────────────────────────────────
class PaymentException implements Exception {
  final String message;
  const PaymentException(this.message);

  @override
  String toString() => 'PaymentException: $message';
}
