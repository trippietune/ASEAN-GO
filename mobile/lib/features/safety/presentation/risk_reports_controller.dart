import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/risk_report_model.dart';
import 'proximity_alert_controller.dart';

/// Community risk reports for a single pin, keyed by pin ID.
class RiskReportsController extends FamilyAsyncNotifier<List<RiskReport>, String> {
  @override
  Future<List<RiskReport>> build(String pinId) {
    return ref.read(safetyRepositoryProvider).fetchRiskReports(pinId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(safetyRepositoryProvider).fetchRiskReports(arg));
  }

  /// Returns null on success, or an error message for the caller to show.
  Future<String?> submitReport({
    required RiskSeverity severity,
    required String description,
    List<String> photoUrls = const [],
  }) async {
    try {
      final report = await ref.read(safetyRepositoryProvider).submitRiskReport(
            arg,
            severity: severity,
            description: description,
            photoUrls: photoUrls,
          );
      final current = state.valueOrNull ?? [];
      state = AsyncData([report, ...current]);
      return null;
    } catch (_) {
      return 'ส่งรายงานไม่สำเร็จ ลองใหม่อีกทีนะ';
    }
  }
}

final riskReportsControllerProvider =
    AsyncNotifierProviderFamily<RiskReportsController, List<RiskReport>, String>(
  RiskReportsController.new,
);
