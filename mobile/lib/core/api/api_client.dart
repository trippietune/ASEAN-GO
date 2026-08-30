import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../l10n/generated/app_localizations.dart';

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

/// The Dio interceptors below run outside the widget tree (no BuildContext
/// available at construction time), so they can't reach AppLocalizations
/// via `.of(context)` the normal way. [AseanGoApp] keeps this in sync with
/// whatever locale Flutter actually resolved (device locale, or the user's
/// explicit override from [localeControllerProvider]) every time it
/// rebuilds — [lookupAppLocalizations] then resolves error copy from it
/// directly. Defaults to Thai, the app's source language, until the first
/// frame sets a real value.
Locale currentApiLocale = const Locale('th');

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
          final l10n = lookupAppLocalizations(currentApiLocale);
          if (error.response?.statusCode == 401) {
            await clearToken();
            _showSnackBar(l10n.apiSessionExpired);
            onUnauthorized?.call();
          } else {
            _showSnackBar(await _messageFor(error, l10n));
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

  Future<String> _messageFor(DioException error, AppLocalizations l10n) async {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return l10n.apiConnectionTimeout;
      case DioExceptionType.connectionError:
        // Distinguishes "device has no network at all" from "network is up
        // but the backend itself is unreachable" (wrong host, server down,
        // firewall) — the fix for each is different, so the message should be.
        final results = await Connectivity().checkConnectivity();
        final hasNetwork = results.any((r) => r != ConnectivityResult.none);
        return hasNetwork ? l10n.apiServerUnreachable : l10n.apiNoInternet;
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode ?? 0;
        if (status >= 500) return l10n.apiServerError;
        return (error.response?.data is Map && (error.response?.data as Map)['error'] != null)
            ? (error.response!.data as Map)['error'] as String
            : l10n.apiGenericError;
      default:
        return l10n.apiGenericError;
    }
  }
}
