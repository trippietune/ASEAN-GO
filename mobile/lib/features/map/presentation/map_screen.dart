import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/pin_model.dart';
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
  bool _legendVisible = true;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  IconData _iconFor(String category) {
    switch (category) {
      case 'food':
        return Icons.restaurant;
      case 'shop':
        return Icons.storefront;
      case 'attraction':
        return Icons.photo_camera;
      case 'transport':
        return Icons.directions_bus;
      case 'lodging':
        return Icons.hotel;
      default:
        return Icons.place;
    }
  }

  Future<void> _recenter() async {
    final center = await ref.read(currentPositionProvider.future);
    _mapController.move(LatLng(center.lat, center.lng), 15);
    if (!center.isRealLocation && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).mapLocationNotFound)),
      );
    }
  }

  void _openPin(VerifiedPin pin) {
    if (pin.isCheckpoint) {
      _showCheckpointSheet(pin);
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => PinDetailScreen(pin: pin)));
    }
  }

  void _showCheckpointSheet(VerifiedPin pin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _CheckpointSheet(pin: pin),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pinsAsync = ref.watch(filteredPinsProvider);
    final centerAsync = ref.watch(currentPositionProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.white.withValues(alpha: 0.85),
        elevation: 0,
        title: Text(l10n.mapNearbyPinsTitle),
      ),
      body: Stack(
        children: [
          pinsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.mapLoadPinsError(err.toString()), textAlign: TextAlign.center),
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
                          width: 48,
                          height: 48,
                          child: GestureDetector(
                            onTap: () => _openPin(pin),
                            child: _PinMarker(
                              icon: _iconFor(pin.category),
                              color: AppColors.safetyScoreColor(pin.safetyScore),
                              reportCount: pin.reportCount,
                              isCheckpoint: pin.isCheckpoint,
                              hasActiveQuest: pin.hasActiveQuest,
                              isRecommended: pin.isRecommended,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: _legendVisible
                ? _MapLegend(l10n: l10n, onHide: () => setState(() => _legendVisible = false))
                : _LegendToggleButton(l10n: l10n, onShow: () => setState(() => _legendVisible = true)),
          ),
          Positioned(top: 100, left: 0, right: 0, child: _MapFilterBar(l10n: l10n)),
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
            label: Text(l10n.mapAddPinLabel),
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

/// A circular badge around a place-category icon, tinted by safety score.
/// Checkpoint/quest/recommended status is layered on as small corner badges
/// rather than replacing the safety color, so the most important signal
/// (is this place safe?) is never hidden behind a "recommended" star.
class _PinMarker extends StatelessWidget {
  const _PinMarker({
    required this.icon,
    required this.color,
    this.reportCount = 0,
    this.isCheckpoint = false,
    this.hasActiveQuest = false,
    this.isRecommended = false,
  });

  final IconData icon;
  final Color color;
  final int reportCount;
  final bool isCheckpoint;
  final bool hasActiveQuest;
  final bool isRecommended;

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
          child: Icon(icon, size: 18, color: Colors.white),
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
          )
        // Only one corner badge shows at a time (priority: checkpoint > quest
        // > recommended) to avoid crowding a 48x48 marker with multiple tiny
        // icons — checkpoint and quest are actionable right now, recommended
        // is just a hint, so it yields to the other two when a pin is more
        // than one of these at once.
        else if (isCheckpoint)
          _CornerBadge(color: AppColors.info, icon: Icons.flag)
        else if (hasActiveQuest)
          _CornerBadge(color: AppColors.questPurple, icon: Icons.auto_awesome)
        else if (isRecommended)
          _CornerBadge(color: AppColors.yellowDark, icon: Icons.star),
      ],
    );
  }
}

class _CornerBadge extends StatelessWidget {
  const _CornerBadge({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -4,
      right: -4,
      child: Container(
        width: 16,
        height: 16,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
        child: Icon(icon, size: 9, color: Colors.white),
      ),
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

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.l10n, required this.onHide});

  final AppLocalizations l10n;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LegendRow(color: AppColors.success, icon: Icons.circle, label: l10n.mapSafetyLegendSafe),
          const SizedBox(height: 4),
          _LegendRow(color: AppColors.warning, icon: Icons.circle, label: l10n.mapSafetyLegendCaution),
          const SizedBox(height: 4),
          _LegendRow(color: AppColors.danger, icon: Icons.circle, label: l10n.mapSafetyLegendDanger),
          const SizedBox(height: 4),
          _LegendRow(color: AppColors.info, icon: Icons.flag, label: l10n.mapLegendCheckpoint),
          const SizedBox(height: 4),
          _LegendRow(color: AppColors.questPurple, icon: Icons.auto_awesome, label: l10n.mapLegendQuest),
          const SizedBox(height: 4),
          _LegendRow(color: AppColors.yellowDark, icon: Icons.star, label: l10n.mapLegendRecommended),
          const SizedBox(height: 4),
          InkWell(
            onTap: onHide,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                l10n.mapLegendToggleHide,
                style: TextStyle(fontSize: 11, color: AppColors.pinkDark, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendToggleButton extends StatelessWidget {
  const _LegendToggleButton({required this.l10n, required this.onShow});

  final AppLocalizations l10n;
  final VoidCallback onShow;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onShow,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.pinkDark),
              const SizedBox(width: 6),
              Text(l10n.mapLegendToggleShow, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.icon, required this.label});

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _MapFilterBar extends ConsumerWidget {
  const _MapFilterBar({required this.l10n});

  final AppLocalizations l10n;

  String _labelFor(MapFilter filter) {
    return switch (filter) {
      MapFilter.all => l10n.mapFilterAll,
      MapFilter.safe => l10n.mapFilterSafe,
      MapFilter.checkpoint => l10n.mapFilterCheckpoint,
      MapFilter.quest => l10n.mapFilterQuest,
      MapFilter.recommended => l10n.mapFilterRecommended,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(mapFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final filter in MapFilter.values) ...[
            ChoiceChip(
              label: Text(_labelFor(filter)),
              selected: selected == filter,
              onSelected: (_) => ref.read(mapFilterProvider.notifier).state = filter,
              backgroundColor: Colors.white.withValues(alpha: 0.92),
              selectedColor: AppColors.pinkLight,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected == filter ? AppColors.pinkDark : AppColors.greyDark,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _CheckpointSheet extends ConsumerStatefulWidget {
  const _CheckpointSheet({required this.pin});

  final VerifiedPin pin;

  @override
  ConsumerState<_CheckpointSheet> createState() => _CheckpointSheetState();
}

class _CheckpointSheetState extends ConsumerState<_CheckpointSheet> {
  bool _checkingIn = false;

  Future<void> _checkIn() async {
    setState(() => _checkingIn = true);
    final l10n = AppLocalizations.of(context);
    try {
      final result = await ref.read(pinsRepositoryProvider).checkIn(widget.pin.id);
      if (!mounted) return;
      ref.read(authControllerProvider.notifier).applyXpGain(xp: result.xp, level: result.level);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mapCheckpointCheckInSuccess(result.xpAwarded))),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final message = e.response?.statusCode == 409
          ? l10n.mapCheckpointAlreadyDoneToday
          : l10n.mapCheckpointCheckInError;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag, color: AppColors.info),
                const SizedBox(width: 8),
                Text(l10n.mapCheckpointSheetTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(widget.pin.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              l10n.mapCheckpointSheetDescription,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _checkingIn ? null : _checkIn,
                icon: _checkingIn
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline),
                label: Text(l10n.mapCheckpointCheckInButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
