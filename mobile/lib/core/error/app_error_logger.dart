import 'package:flutter/foundation.dart';

/// Central sink for uncaught errors — wired up in `main()` via
/// `runZonedGuarded` and `FlutterError.onError` so a crash anywhere in the
/// app funnels through one place instead of disappearing into a red screen
/// (debug) or silent process death (release).
///
/// No remote crash reporting (Crashlytics/Sentry) is wired up yet — that
/// needs its own account/project setup. This keeps the last handful of
/// errors in memory (visible via [recent] for in-app diagnostics/support
/// screens) and always echoes to the console, which is the reachable floor
/// for now without adding a new backend dependency.
class AppErrorLogger {
  AppErrorLogger._();

  static final List<AppErrorRecord> _recent = [];
  static const _maxRecords = 20;

  static List<AppErrorRecord> get recent => List.unmodifiable(_recent);

  static void record(Object error, StackTrace? stackTrace, {String? context}) {
    final record = AppErrorRecord(
      error: error,
      stackTrace: stackTrace,
      context: context,
      timestamp: DateTime.now(),
    );
    _recent.add(record);
    if (_recent.length > _maxRecords) {
      _recent.removeAt(0);
    }
    debugPrint('[AppError]${context != null ? ' [$context]' : ''} $error');
    if (stackTrace != null) debugPrint(stackTrace.toString());
  }
}

class AppErrorRecord {
  AppErrorRecord({required this.error, required this.stackTrace, required this.context, required this.timestamp});

  final Object error;
  final StackTrace? stackTrace;
  final String? context;
  final DateTime timestamp;
}
