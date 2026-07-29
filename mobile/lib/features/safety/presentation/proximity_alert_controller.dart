import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/api/providers.dart';
import '../data/risk_pin_model.dart';
import '../data/safety_repository.dart';

final safetyRepositoryProvider = Provider<SafetyRepository>((ref) {
  return SafetyRepository(ref.watch(apiClientProvider));
});

/// The most recent risky pin the user was warned about, or null if nothing
/// nearby right now / no check has run yet. The UI (e.g. Home screen) watches
/// this to show a banner; it does not itself pop dialogs, so multiple
/// screens can react to the same state without duplicate alerts.
class ProximityAlertController extends Notifier<RiskPin?> {
  Timer? _timer;
  String? _lastWarnedPinId;

  static const _checkInterval = Duration(seconds: 45);
  static const _alertRadiusMeters = 1500.0;

  @override
  RiskPin? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  /// Starts foreground polling. Safe to call multiple times (e.g. once per
  /// screen that cares) — it only schedules one timer.
  void start() {
    if (_timer != null) return;
    _checkOnce();
    _timer = Timer.periodic(_checkInterval, (_) => _checkOnce());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Lets the user dismiss the current banner without waiting for the next
  /// poll to naturally clear it (e.g. they've already moved away or read it).
  void dismiss() {
    state = null;
  }

  Future<void> _checkOnce() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final risks = await ref.read(safetyRepositoryProvider).fetchNearbyRisks(
            lat: position.latitude,
            lng: position.longitude,
            radiusMeters: _alertRadiusMeters,
          );

      if (risks.isEmpty) {
        state = null;
        return;
      }

      final closest = risks.first;
      // Only surface a fresh banner when the closest risk changes, so the
      // user isn't re-shown the same warning every 45 seconds while standing
      // still near the same spot.
      if (closest.id != _lastWarnedPinId) {
        _lastWarnedPinId = closest.id;
        state = closest;
      }
    } catch (_) {
      // Best-effort background check — a transient GPS/network failure
      // shouldn't surface an error to the user.
    }
  }
}

final proximityAlertControllerProvider = NotifierProvider<ProximityAlertController, RiskPin?>(
  ProximityAlertController.new,
);
