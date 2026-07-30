import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/media/media_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

/// Pick-photos-from-camera-or-gallery grid used by review, pin, and
/// risk-report submission flows. Each photo is uploaded to our backend
/// (which forwards to Cloudinary) as soon as it's picked, so [urls] always
/// reflects what's actually been uploaded — the parent form just reads
/// [urls] when it submits, no separate "upload now" step needed.
class PhotoPickerGrid extends ConsumerStatefulWidget {
  const PhotoPickerGrid({
    super.key,
    required this.purpose,
    required this.urls,
    required this.onChanged,
    this.maxPhotos = 6,
  });

  final MediaPurpose purpose;
  final List<String> urls;
  final ValueChanged<List<String>> onChanged;
  final int maxPhotos;

  @override
  ConsumerState<PhotoPickerGrid> createState() => _PhotoPickerGridState();
}

class _PhotoPickerGridState extends ConsumerState<PhotoPickerGrid> {
  bool _isUploading = false;

  Future<void> _pickAndUpload(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90, maxWidth: 2000);
    if (picked == null || !mounted) return;

    setState(() => _isUploading = true);
    try {
      final uploaded = await ref.read(mediaRepositoryProvider).upload(picked.path, widget.purpose);
      widget.onChanged([...widget.urls, uploaded.url]);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).photoUploadError)),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _showSourcePicker() async {
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.photoSourceCamera),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.photoSourceGallery),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _pickAndUpload(source);
  }

  void _removePhoto(String url) {
    widget.onChanged(widget.urls.where((u) => u != url).toList());
    ref.read(mediaRepositoryProvider).delete(url); // best-effort, fire-and-forget
  }

  @override
  Widget build(BuildContext context) {
    final canAddMore = widget.urls.length < widget.maxPhotos;

    return SizedBox(
      height: 76,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final url in widget.urls) ...[
            _PhotoThumbnail(url: url, onRemove: () => _removePhoto(url)),
            const SizedBox(width: 8),
          ],
          if (canAddMore)
            _AddPhotoButton(isLoading: _isUploading, onTap: _isUploading ? null : _showSourcePicker),
        ],
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.url, required this.onRemove});

  final String url;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            width: 68,
            height: 68,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 68,
              height: 68,
              color: AppColors.yellowPale,
              child: const Icon(Icons.image_not_supported_outlined, size: 20),
            ),
          ),
        ),
        Positioned(
          top: -4,
          right: -4,
          // 32x32 tap target (vs. the 20px visual badge) — as large as fits
          // without clipping against the row/thumbnail bounds or overlapping
          // the next photo in the strip.
          child: GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: AppColors.yellowPale.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.pinkDark.withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.add_a_photo_outlined, color: AppColors.pinkDark),
      ),
    );
  }
}
