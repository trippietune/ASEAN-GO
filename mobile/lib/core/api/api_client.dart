import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Base URL for the backend API.
///
/// Android emulator maps host loopback to 10.0.2.2; web (Chrome/Edge), iOS
/// simulator, and desktop can all reach the backend via localhost directly
/// (the browser/process shares the host's network namespace, unlike the
/// Android emulator's isolated one). Override with
/// --dart-define=API_BASE_URL=... for a real device or a deployed backend,
/// where neither default applies.
const _defaultBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
String get _resolvedBaseUrl {
  if (_defaultBaseUrl.isNotEmpty) return _defaultBaseUrl;
  return kIsWeb ? 'http://localhost:4000' : 'http://10.0.2.2:4000';
}

/// Same host the REST client talks to — used by the WebSocket client so both
/// stay in sync when overridden via --dart-define for a real device/deploy.
String get apiBaseUrl => _resolvedBaseUrl;

const _tokenKey = 'auth_token';

/// Attached to [MaterialApp.scaffoldMessengerKey] so the API layer can show
/// snackbars without needing a BuildContext of its own.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class ApiClient {
  ApiClient()
      : dio = Dio(
          BaseOptions(
            baseUrl: _resolvedBaseUrl,
            // Without explicit timeouts Dio waits indefinitely on a hung
            // connection (e.g. wifi drops mid-request) — the UI would stay
            // in a loading state forever instead of surfacing an error.
            connectTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
          ),
        ) {
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
            _showSnackBar(await _messageFor(error));
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

  // Left as Thai-only: this interceptor runs outside the widget tree (no
  // BuildContext available at construction time), so it can't reach
  // AppLocalizations without a fragile global-context workaround.
  Future<String> _messageFor(DioException error) async {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง';
      case DioExceptionType.connectionError:
        // Distinguishes "device has no network at all" from "network is up
        // but the backend itself is unreachable" (wrong host, server down,
        // firewall) — the fix for each is different, so the message should be.
        final results = await Connectivity().checkConnectivity();
        final hasNetwork = results.any((r) => r != ConnectivityResult.none);
        return hasNetwork ? 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาลองใหม่ภายหลัง' : 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต กรุณาตรวจสอบการเชื่อมต่อ';
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
