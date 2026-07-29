import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../data/safety_repository.dart';
import 'proximity_alert_controller.dart';

/// Wraps the SOS lifecycle: trigger (gets GPS + POSTs to backend) and resolve.
/// State is the currently-active SOS event, or null when there isn't one.
class SosController extends AsyncNotifier<SosEvent?> {
  @override
  Future<SosEvent?> build() {
    return ref.read(safetyRepositoryProvider).fetchActiveSos();
  }

  /// Gets the current GPS fix and sends it to the backend. Throws on
  /// location-permission failures or network errors so the caller (a
  /// confirm dialog) can show an error instead of silently doing nothing.
  Future<void> trigger() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('กรุณาเปิดตำแหน่ง (GPS) ก่อนส่งสัญญาณขอความช่วยเหลือ');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('ต้องอนุญาตให้เข้าถึงตำแหน่งก่อนส่ง SOS');
      }

      final position = await Geolocator.getCurrentPosition();
      return ref.read(safetyRepositoryProvider).triggerSos(
            lat: position.latitude,
            lng: position.longitude,
          );
    });
  }

  Future<void> resolve() async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(safetyRepositoryProvider).resolveSos(current.id);
      return null;
    });
  }
}

final sosControllerProvider = AsyncNotifierProvider<SosController, SosEvent?>(
  SosController.new,
);
