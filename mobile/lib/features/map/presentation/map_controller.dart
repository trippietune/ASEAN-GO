import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/api/providers.dart';
import '../data/pin_model.dart';
import '../data/pins_repository.dart';
import '../data/pin_suggestions_repository.dart';

final pinsRepositoryProvider = Provider<PinsRepository>((ref) {
  return PinsRepository(ref.watch(apiClientProvider));
});

final pinSuggestionsRepositoryProvider = Provider<PinSuggestionsRepository>((ref) {
  return PinSuggestionsRepository(ref.watch(apiClientProvider));
});

// Bangkok as a sane fallback center when location permission is unavailable.
const _fallbackLat = 13.7563;
const _fallbackLng = 100.5018;

Future<Position?> _resolvePosition() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return null;

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    return null;
  }
  return Geolocator.getCurrentPosition();
}

class MapCenter {
  const MapCenter({required this.lat, required this.lng, required this.isRealLocation});

  final double lat;
  final double lng;
  final bool isRealLocation;
}

final currentPositionProvider = FutureProvider.autoDispose<MapCenter>((ref) async {
  final position = await _resolvePosition();
  if (position == null) {
    return const MapCenter(lat: _fallbackLat, lng: _fallbackLng, isRealLocation: false);
  }
  return MapCenter(lat: position.latitude, lng: position.longitude, isRealLocation: true);
});

final nearbyPinsProvider = FutureProvider.autoDispose<List<VerifiedPin>>((ref) async {
  final center = await ref.watch(currentPositionProvider.future);
  return ref.watch(pinsRepositoryProvider).fetchNearby(lat: center.lat, lng: center.lng);
});

enum MapFilter { all, safe, checkpoint, quest, recommended }

final mapFilterProvider = StateProvider.autoDispose<MapFilter>((ref) => MapFilter.all);

bool matchesMapFilter(VerifiedPin pin, MapFilter filter) {
  return switch (filter) {
    MapFilter.all => true,
    MapFilter.safe => pin.safetyScore >= 70,
    MapFilter.checkpoint => pin.isCheckpoint,
    MapFilter.quest => pin.hasActiveQuest,
    MapFilter.recommended => pin.isRecommended,
  };
}

final filteredPinsProvider = Provider.autoDispose<AsyncValue<List<VerifiedPin>>>((ref) {
  final pinsAsync = ref.watch(nearbyPinsProvider);
  final filter = ref.watch(mapFilterProvider);
  return pinsAsync.whenData((pins) => pins.where((pin) => matchesMapFilter(pin, filter)).toList());
});

final favoritePinsProvider = FutureProvider.autoDispose<List<VerifiedPin>>((ref) async {
  return ref.watch(pinsRepositoryProvider).fetchFavorites();
});
