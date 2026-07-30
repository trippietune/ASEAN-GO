import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/photo_picker_grid.dart';
import '../data/risk_report_model.dart';
import 'risk_reports_controller.dart';

/// Localized label for a risk severity, used at UI display seams since the
/// model itself (data/risk_report_model.dart) has no BuildContext.
String riskSeverityLabel(AppLocalizations l10n, RiskSeverity severity) {
  switch (severity) {
    case RiskSeverity.caution:
      return l10n.riskSeverityCaution;
    case RiskSeverity.warning:
      return l10n.riskSeverityWarning;
    case RiskSeverity.danger:
      return l10n.riskSeverityDanger;
  }
}

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
    final l10n = AppLocalizations.of(context);
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportRiskDescriptionRequired)),
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
      SnackBar(content: Text(error ?? l10n.reportRiskThanksMessage)),
    );
    if (error == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            l10n.reportRiskTitle,
            style: TextStyle(color: AppColors.pinkDark, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.reportRiskSubtitle,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final severity in RiskSeverity.values)
                ChoiceChip(
                  label: Text(riskSeverityLabel(l10n, severity)),
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
            decoration: InputDecoration(
              hintText: l10n.reportRiskDescriptionHint,
            ),
          ),
          Text(
            l10n.reportRiskAttachPhotos,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12),
          ),
          const SizedBox(height: 8),
          PhotoPickerGrid(
            purpose: MediaPurpose.riskReportPhoto,
            urls: _photoUrls,
            onChanged: (urls) => setState(() => _photoUrls = urls),
          ),
          const SizedBox(height: 12),
          GradientButton(
            label: l10n.reportRiskSubmitButton,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
