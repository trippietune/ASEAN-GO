import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/photo_picker_grid.dart';
import 'map_controller.dart';

const _categories = [
  ('food', '🍜', 'ร้านอาหาร'),
  ('shop', '🛍️', 'ร้านค้า'),
  ('attraction', '📸', 'สถานที่ท่องเที่ยว'),
  ('transport', '🚌', 'การเดินทาง'),
  ('lodging', '🏡', 'ที่พัก'),
  ('other', '🌸', 'อื่นๆ'),
];

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
        const SnackBar(content: Text('ส่งจุดใหม่แล้ว รอทีมงานตรวจสอบก่อนนะ 🌸')),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ส่งจุดใหม่ไม่สำเร็จ ลองใหม่อีกทีนะ')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มจุดใหม่')),
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
                      child: const Text('ลากแผนที่เพื่อปักหมุด', style: TextStyle(fontSize: 11)),
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
                      decoration: const InputDecoration(labelText: 'ชื่อสถานที่', prefixIcon: Icon(Icons.place_outlined)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อสถานที่' : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'หมวดหมู่',
                      style: TextStyle(color: AppColors.greyDark.withValues(alpha: 0.7), fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (value, emoji, label) in _categories)
                          ChoiceChip(
                            label: Text('$emoji $label'),
                            selected: _category == value,
                            onSelected: (_) => setState(() => _category = value),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'เมือง (ถ้ามี)', prefixIcon: Icon(Icons.location_city_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      maxLength: 2000,
                      decoration: const InputDecoration(hintText: 'บอกเล่ารายละเอียดสถานที่นี้หน่อยนะ'),
                    ),
                    Text(
                      'แนบรูปภาพ',
                      style: TextStyle(color: AppColors.greyDark.withValues(alpha: 0.7), fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    PhotoPickerGrid(
                      purpose: MediaPurpose.pinPhoto,
                      urls: _photoUrls,
                      onChanged: (urls) => setState(() => _photoUrls = urls),
                    ),
                    const SizedBox(height: 20),
                    GradientButton(
                      label: 'ส่งจุดนี้',
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
