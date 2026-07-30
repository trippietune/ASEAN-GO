import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/safety_indicator.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../safety/presentation/report_risk_dialog.dart';
import '../../safety/presentation/risk_report_card.dart';
import '../../safety/presentation/risk_reports_controller.dart';
import '../data/pin_model.dart';
import 'map_controller.dart';
import 'review_card.dart';
import 'reviews_controller.dart';
import 'star_rating.dart';
import 'write_review_dialog.dart';

class PinDetailScreen extends ConsumerStatefulWidget {
  const PinDetailScreen({super.key, required this.pin});

  final VerifiedPin pin;

  @override
  ConsumerState<PinDetailScreen> createState() => _PinDetailScreenState();
}

class _PinDetailScreenState extends ConsumerState<PinDetailScreen> {
  bool _checkingIn = false;

  Future<void> _checkIn() async {
    setState(() => _checkingIn = true);
    final l10n = AppLocalizations.of(context);
    try {
      final result = await ref.read(pinsRepositoryProvider).checkIn(widget.pin.id);
      if (!mounted) return;
      ref.read(authControllerProvider.notifier).applyXpGain(xp: result.xp, level: result.level);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pinDetailCheckInSuccess(result.xpAwarded))),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final message = e.response?.statusCode == 409
          ? l10n.pinDetailCheckInAlreadyDone
          : l10n.pinDetailCheckInError;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }

  void _navigate() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).pinDetailNavigatePlaceholder)),
    );
  }

  Future<void> _deleteReview() async {
    final success = await ref.read(reviewsControllerProvider(widget.pin.id).notifier).deleteMyReview();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? l10n.pinDetailReviewDeleted : l10n.pinDetailReviewDeleteError)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pin = widget.pin;
    final authState = ref.watch(authControllerProvider);
    final myUserId = authState is AuthAuthenticated ? authState.user.id : null;
    final reviewsAsync = ref.watch(reviewsControllerProvider(pin.id));
    final riskReportsAsync = ref.watch(riskReportsControllerProvider(pin.id));
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(pin.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${pin.category} · ${pin.city ?? pin.country}'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        StarRating(rating: pin.averageRating),
                        const SizedBox(width: 6),
                        Text(
                          pin.reviewCount > 0
                              ? l10n.pinDetailRatingSummary(pin.averageRating.toStringAsFixed(1), pin.reviewCount)
                              : l10n.pinDetailNoReviews,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                    if (pin.isVerified) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified, size: 14, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              l10n.pinDetailVerifiedBadge,
                              style: const TextStyle(color: AppColors.greyDark, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SafetyIndicator(score: pin.safetyScore),
            ],
          ),
          if (pin.isScamAlert) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pin.scamAlertMessage ?? l10n.pinDetailScamAlertDefault,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (pin.description != null) ...[
            const SizedBox(height: 12),
            Text(pin.description!),
          ],
          if (pin.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: pin.photoUrls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    pin.photoUrls[index],
                    width: 120,
                    height: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 120,
                      height: 96,
                      color: AppColors.yellowPale,
                      child: const Icon(Icons.image_not_supported_outlined, size: 24),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _navigate,
                  icon: const Icon(Icons.directions),
                  label: Text(l10n.pinDetailNavigateButton),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientButton(
                  label: l10n.pinDetailCheckInButton,
                  icon: Icons.check_circle_outline,
                  isLoading: _checkingIn,
                  onPressed: _checkingIn ? null : _checkIn,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.pinDetailReviewsSectionTitle,
                style: TextStyle(color: AppColors.pinkDark, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () {
                  final mine = reviewsAsync.valueOrNull?.where((r) => r.userId == myUserId).firstOrNull;
                  showWriteReviewDialog(context, pinId: pin.id, existing: mine);
                },
                icon: const Icon(Icons.rate_review_outlined, size: 18),
                label: Text(l10n.pinDetailWriteReviewButton),
              ),
            ],
          ),
          const SizedBox(height: 8),
          reviewsAsync.when(
            loading: () => const Center(
              child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
            ),
            error: (err, _) => EmptyStateWidget(
              icon: Icons.error_outline,
              message: l10n.pinDetailReviewsLoadError,
              onRetry: () => ref.read(reviewsControllerProvider(pin.id).notifier).refresh(),
            ),
            data: (reviews) {
              if (reviews.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.rate_review_outlined,
                  message: l10n.pinDetailReviewsEmpty,
                );
              }
              return Column(
                children: [
                  for (final review in reviews) ...[
                    ReviewCard(
                      review: review,
                      isMine: review.userId == myUserId,
                      onDelete: review.userId == myUserId ? _deleteReview : null,
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.pinDetailRiskReportsSectionTitle,
                style: TextStyle(color: AppColors.pinkDark, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => showReportRiskDialog(context, pinId: pin.id),
                icon: const Icon(Icons.report_gmailerrorred_outlined, size: 18),
                label: Text(l10n.pinDetailReportButton),
              ),
            ],
          ),
          const SizedBox(height: 8),
          riskReportsAsync.when(
            loading: () => const Center(
              child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
            ),
            error: (err, _) => EmptyStateWidget(
              icon: Icons.error_outline,
              message: l10n.pinDetailRiskReportsLoadError,
              onRetry: () => ref.read(riskReportsControllerProvider(pin.id).notifier).refresh(),
            ),
            data: (reports) {
              if (reports.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.shield_outlined,
                  message: l10n.pinDetailRiskReportsEmpty,
                );
              }
              return Column(
                children: [
                  for (final report in reports) ...[
                    RiskReportCard(report: report),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
