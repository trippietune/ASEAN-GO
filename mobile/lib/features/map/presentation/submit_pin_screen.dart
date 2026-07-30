import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/photo_picker_grid.dart';
import 'map_controller.dart';

typedef _CategoryOption = (String, IconData, String Function(AppLocalizations));

const _categories = <_CategoryOption>[
  ('food', Icons.restaurant, _foodLabel),
  ('shop', Icons.storefront, _shopLabel),
  ('attraction', Icons.photo_camera, _attractionLabel),
  ('transport', Icons.directions_bus, _transportLabel),
  ('lodging', Icons.hotel, _lodgingLabel),
  ('other', Icons.place, _otherLabel),
];

String _foodLabel(AppLocalizations l10n) => l10n.mapCategoryFood;
String _shopLabel(AppLocalizations l10n) => l10n.mapCategoryShop;
String _attractionLabel(AppLocalizations l10n) => l10n.mapCategoryAttraction;
String _transportLabel(AppLocalizations l10n) => l10n.mapCategoryTransport;
String _lodgingLabel(AppLocalizations l10n) => l10n.mapCategoryLodging;
String _otherLabel(AppLocalizations l10n) => l10n.mapCategoryOther;

/// Submits a new pin candidate — the pin starts unverified pending admin
/// review (see backend POST /pins). Location is picked via a center-screen
/// crosshair over a draggable map, which is simpler and less error-prone on
/// a phone than long-press placement.
class SubmitPinScreen extends ConsumerStatefulWidget {
  const SubmitPinScreen({super.key});

  @override
  ConsumerState<SubmitPinScreen> createState() => _SubmitPinScreenState();
}

class _SubmitPinScreenState extends ConsumerState<SubmitPinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _mapController = MapController();

  String _category = _categories.first.$1;
  LatLng _pickedLocation = const LatLng(13.7563, 100.5018);
  List<String> _photoUrls = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _centerOnCurrentLocation();
  }

  Future<void> _centerOnCurrentLocation() async {
    final center = await ref.read(currentPositionProvider.future);
    final location = LatLng(center.lat, center.lng);
    setState(() => _pickedLocation = location);
    _mapController.move(location, 15);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(pinsRepositoryProvider).createPin(
            name: _nameController.text.trim(),
            category: _category,
            country: 'Thailand',
            lat: _pickedLocation.latitude,
            lng: _pickedLocation.longitude,
            description: _descriptionController.text.trim(),
            city: _cityController.text.trim(),
            photoUrls: _photoUrls,
          );
      if (!mounted) return;
      ref.invalidate(nearbyPinsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).submitPinSuccess)),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).submitPinError)),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.submitPinTitle)),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 220,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _pickedLocation,
                        initialZoom: 15,
                        onPositionChanged: (position, hasGesture) {
                          final center = position.center;
                          if (hasGesture) setState(() => _pickedLocation = center);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.aseango.asean_go_mobile',
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.location_on, size: 40, color: AppColors.pinkDark),
                  Positioned(
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(l10n.submitPinDragMapHint, style: const TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: l10n.submitPinNameLabel, prefixIcon: const Icon(Icons.place_outlined)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? l10n.submitPinNameValidator : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.submitPinCategoryLabel,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (value, icon, label) in _categories)
                          ChoiceChip(
                            avatar: Icon(icon, size: 18),
                            label: Text(label(l10n)),
                            selected: _category == value,
                            onSelected: (_) => setState(() => _category = value),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(labelText: l10n.submitPinCityLabel, prefixIcon: const Icon(Icons.location_city_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      maxLength: 2000,
                      decoration: InputDecoration(hintText: l10n.submitPinDescriptionHint),
                    ),
                    Text(
                      l10n.submitPinAttachPhotos,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    PhotoPickerGrid(
                      purpose: MediaPurpose.pinPhoto,
                      urls: _photoUrls,
                      onChanged: (urls) => setState(() => _photoUrls = urls),
                    ),
                    const SizedBox(height: 20),
                    GradientButton(
                      label: l10n.submitPinSubmitButton,
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : _submit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
