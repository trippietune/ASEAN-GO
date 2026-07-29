import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import 'map_controller.dart';
import 'pin_detail_screen.dart';
import 'submit_pin_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  String _emojiFor(String category) {
    switch (category) {
      case 'food':
        return '🍜';
      case 'shop':
        return '🛍️';
      case 'attraction':
        return '📸';
      case 'transport':
        return '🚌';
      case 'lodging':
        return '🏡';
      default:
        return '🌸';
    }
  }

  Future<void> _recenter() async {
    final center = await ref.read(currentPositionProvider.future);
    _mapController.move(LatLng(center.lat, center.lng), 15);
    if (!center.isRealLocation && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('หาตำแหน่งคุณไม่เจอเลย ขอแสดงจุดเริ่มต้นแทนนะ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinsAsync = ref.watch(nearbyPinsProvider);
    final centerAsync = ref.watch(currentPositionProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.white.withValues(alpha: 0.85),
        elevation: 0,
        title: const Text('จุดน่าไปแถวนี้ 🌸'),
      ),
      body: Stack(
        children: [
          pinsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('ยังโหลดจุดใกล้เคียงไม่ได้เลย ลองใหม่อีกทีนะ\n$err', textAlign: TextAlign.center),
              ),
            ),
            data: (pins) {
              final center = centerAsync.valueOrNull;
              final initialCenter =
                  center != null ? LatLng(center.lat, center.lng) : const LatLng(13.7563, 100.5018);

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(initialCenter: initialCenter, initialZoom: 14),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.aseango.asean_go_mobile',
                  ),
                  MarkerLayer(
                    markers: [
                      for (final pin in pins)
                        Marker(
                          point: LatLng(pin.lat, pin.lng),
                          width: 44,
                          height: 44,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => PinDetailScreen(pin: pin)),
                            ),
                            child: _PinMarker(
                              emoji: _emojiFor(pin.category),
                              color: AppColors.safetyScoreColor(pin.safetyScore),
                              reportCount: pin.reportCount,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
          const Positioned(left: 16, bottom: 16, child: _SafetyLegend()),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'submit-pin',
            backgroundColor: AppColors.pinkDark,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('เพิ่มจุด'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SubmitPinScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _RoundIconButton(icon: Icons.my_location, onPressed: _recenter, heroTag: 'recenter'),
          const SizedBox(height: 12),
          _RoundIconButton(
            icon: Icons.refresh,
            heroTag: 'refresh',
            onPressed: () {
              ref.invalidate(currentPositionProvider);
              ref.invalidate(nearbyPinsProvider);
            },
          ),
        ],
      ),
    );
  }
}

/// A soft circular badge around a place-category emoji, tinted by safety
/// score — friendlier than a hard teardrop pin shape with a Material icon.
class _PinMarker extends StatelessWidget {
  const _PinMarker({required this.emoji, required this.color, this.reportCount = 0});

  final String emoji;
  final Color color;
  final int reportCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 18)),
        ),
        if (reportCount > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 16),
              child: Text(
                '$reportCount',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onPressed, required this.heroTag});

  final IconData icon;
  final VoidCallback onPressed;
  final Object heroTag;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: onPressed,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.pink,
      elevation: 3,
      child: Icon(icon),
    );
  }
}

class _SafetyLegend extends StatelessWidget {
  const _SafetyLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LegendRow(color: AppColors.success, label: 'ปลอดภัย 🌸'),
          SizedBox(height: 4),
          _LegendRow(color: AppColors.warning, label: 'ระวังหน่อยนะ 🌱'),
          SizedBox(height: 4),
          _LegendRow(color: AppColors.danger, label: 'ควรระวังมากๆ 🍂'),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
