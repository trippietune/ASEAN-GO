import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/photo_picker_grid.dart';
import '../data/review_model.dart';
import 'reviews_controller.dart';
import 'star_rating.dart';

Future<void> showWriteReviewDialog(BuildContext context, {required String pinId, Review? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => WriteReviewDialog(pinId: pinId, existing: existing),
  );
}

class WriteReviewDialog extends ConsumerStatefulWidget {
  const WriteReviewDialog({super.key, required this.pinId, this.existing});

  final String pinId;
  final Review? existing;

  @override
  ConsumerState<WriteReviewDialog> createState() => _WriteReviewDialogState();
}

class _WriteReviewDialogState extends ConsumerState<WriteReviewDialog> {
  late int _rating;
  late final TextEditingController _commentController;
  late List<String> _photoUrls;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.existing?.rating ?? 5;
    _commentController = TextEditingController(text: widget.existing?.comment ?? '');
    _photoUrls = List.of(widget.existing?.photoUrls ?? const []);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final error = await ref.read(reviewsControllerProvider(widget.pinId).notifier).submitReview(
          rating: _rating,
          comment: _commentController.text.trim(),
          photoUrls: _photoUrls,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'ขอบคุณสำหรับรีวิวนะ! 🌸')),
    );
    if (error == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existing != null ? 'แก้ไขรีวิวของคุณ' : 'เล่าประสบการณ์ให้ฟังหน่อยนะ',
            style: TextStyle(color: AppColors.pinkDark, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          StarRatingInput(rating: _rating, onChanged: (r) => setState(() => _rating = r)),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            maxLines: 3,
            maxLength: 2000,
            decoration: const InputDecoration(
              hintText: 'เป็นยังไงบ้าง? บอกเล่าให้เพื่อนๆ ฟังหน่อยนะ',
            ),
          ),
          Text(
            'แนบรูปภาพ',
            style: TextStyle(color: AppColors.greyDark.withValues(alpha: 0.7), fontSize: 12),
          ),
          const SizedBox(height: 8),
          PhotoPickerGrid(
            purpose: MediaPurpose.reviewPhoto,
            urls: _photoUrls,
            onChanged: (urls) => setState(() => _photoUrls = urls),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: widget.existing != null ? 'บันทึกการแก้ไข' : 'ส่งรีวิว',
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
