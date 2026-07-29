import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Base URL for the backend API.
///
/// Android emulator maps host loopback to 10.0.2.2; iOS simulator and desktop
/// can use localhost directly. Override with --dart-define=API_BASE_URL=... at build time.
const _defaultBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:4000',
);

/// Same host the REST client talks to — used by the WebSocket client so both
/// stay in sync when overridden via --dart-define for a real device/deploy.
String get apiBaseUrl => _defaultBaseUrl;

const _tokenKey = 'auth_token';

/// Attached to [MaterialApp.scaffoldMessengerKey] so the API layer can show
/// snackbars without needing a BuildContext of its own.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class ApiClient {
  ApiClient() : dio = Dio(BaseOptions(baseUrl: _defaultBaseUrl)) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await clearToken();
            _showSnackBar('เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่');
            onUnauthorized?.call();
          } else {
            _showSnackBar(_messageFor(error));
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio dio;
  final _storage = const FlutterSecureStorage();

  /// Registered by [AuthController] so a 401 anywhere can trigger logout
  /// without ApiClient depending on Riverpod state directly.
  void Function()? onUnauthorized;

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  void _showSnackBar(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text(message)));
  }

  String _messageFor(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง';
      case DioExceptionType.connectionError:
        return 'ไม่สามารถเชื่อมต่อเครือข่ายได้';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode ?? 0;
        if (status >= 500) return 'เซิร์ฟเวอร์ขัดข้อง กรุณาลองใหม่ภายหลัง';
        return (error.response?.data is Map && (error.response?.data as Map)['error'] != null)
            ? (error.response!.data as Map)['error'] as String
            : 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
      default:
        return 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
    }
  }
}
