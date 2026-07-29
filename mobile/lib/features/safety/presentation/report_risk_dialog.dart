import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/photo_picker_grid.dart';
import '../data/risk_report_model.dart';
import 'risk_reports_controller.dart';

Future<void> showReportRiskDialog(BuildContext context, {required String pinId}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => ReportRiskDialog(pinId: pinId),
  );
}

class ReportRiskDialog extends ConsumerStatefulWidget {
  const ReportRiskDialog({super.key, required this.pinId});

  final String pinId;

  @override
  ConsumerState<ReportRiskDialog> createState() => _ReportRiskDialogState();
}

class _ReportRiskDialogState extends ConsumerState<ReportRiskDialog> {
  RiskSeverity _severity = RiskSeverity.caution;
  final _descriptionController = TextEditingController();
  List<String> _photoUrls = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาอธิบายเหตุการณ์ที่พบหน่อยนะ')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final error = await ref.read(riskReportsControllerProvider(widget.pinId).notifier).submitReport(
          severity: _severity,
          description: description,
          photoUrls: _photoUrls,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'ขอบคุณที่ช่วยเตือนนักเดินทางคนอื่นนะ 🍃')),
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
            'รายงานพื้นที่เสี่ยง',
            style: TextStyle(color: AppColors.pinkDark, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'ช่วยเตือนนักเดินทางคนอื่นว่าจุดนี้ควรระวังอะไร',
            style: TextStyle(color: AppColors.greyDark.withValues(alpha: 0.7), fontSize: 12),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final severity in RiskSeverity.values)
                ChoiceChip(
                  label: Text(severity.label),
                  selected: _severity == severity,
                  onSelected: (_) => setState(() => _severity = severity),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            maxLength: 1000,
            decoration: const InputDecoration(
              hintText: 'เช่น มีคนเรียกเก็บเงินเกินราคา, ทางเดินมืดตอนกลางคืน...',
            ),
          ),
          Text(
            'แนบรูปภาพ (ถ้ามี)',
            style: TextStyle(color: AppColors.greyDark.withValues(alpha: 0.7), fontSize: 12),
          ),
          const SizedBox(height: 8),
          PhotoPickerGrid(
            purpose: MediaPurpose.riskReportPhoto,
            urls: _photoUrls,
            onChanged: (urls) => setState(() => _photoUrls = urls),
          ),
          const SizedBox(height: 12),
          GradientButton(
            label: 'ส่งรายงาน',
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
