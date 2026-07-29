import 'dart:convert';
import 'package:dio/dio.dart';
import 'omise_config.dart';

class CardDetails {
  const CardDetails({
    required this.name,
    required this.number,
    required this.expirationMonth,
    required this.expirationYear,
    required this.securityCode,
  });

  final String name;
  final String number; // digits only, no spaces
  final int expirationMonth;
  final int expirationYear; // 4-digit
  final String securityCode;
}

class OmiseTokenizationException implements Exception {
  OmiseTokenizationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Talks directly to Omise's card-tokenization endpoint using only the
/// *public* key — this never touches our own backend, so full card data
/// never passes through our servers (see docs.omise.co/collecting-card-information).
/// Uses its own bare Dio instance: it must NOT carry our backend's bearer
/// token or trigger our 401-session-expired interceptor.
class OmiseTokenizationClient {
  OmiseTokenizationClient() : _dio = Dio(BaseOptions(baseUrl: 'https://vault.omise.co'));

  final Dio _dio;

  Future<String> createToken(CardDetails card) async {
    if (!isOmiseConfigured) {
      throw OmiseTokenizationException('ยังไม่ได้ตั้งค่าระบบชำระเงิน (OMISE_PUBLIC_KEY)');
    }

    final basicAuth = base64Encode(utf8.encode('$omisePublicKey:'));

    try {
      final response = await _dio.post(
        '/tokens',
        data: {
          'card[name]': card.name,
          'card[number]': card.number,
          'card[expiration_month]': card.expirationMonth,
          'card[expiration_year]': card.expirationYear,
          'card[security_code]': card.securityCode,
        },
        options: Options(
          headers: {'Authorization': 'Basic $basicAuth'},
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      return response.data['id'] as String;
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map ? data['message'] as String? : null) ?? 'ตรวจสอบข้อมูลบัตรไม่สำเร็จ';
      throw OmiseTokenizationException(message);
    }
  }
}
