import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/providers.dart';
import '../data/schedule_model.dart';
import '../data/schedule_repository.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository(ref.watch(apiClientProvider));
});

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

final selectedScheduleDateProvider = StateProvider<DateTime>((ref) => _dateOnly(DateTime.now()));

class ScheduleController extends AsyncNotifier<List<ScheduleItem>> {
  @override
  Future<List<ScheduleItem>> build() async {
    final date = ref.watch(selectedScheduleDateProvider);
    return ref.read(scheduleRepositoryProvider).fetchAll(date: date);
  }

  Future<void> refresh() async {
    final date = ref.read(selectedScheduleDateProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(scheduleRepositoryProvider).fetchAll(date: date));
  }

  /// Returns null on success, or the error thrown (409 duplicate / 404 pin /
  /// 400 invalid time range) for the caller to translate into a message.
  Future<Object?> addItem({
    required String pinId,
    required DateTime scheduledDate,
    String? startTime,
    String? endTime,
    String? note,
  }) async {
    try {
      final item = await ref.read(scheduleRepositoryProvider).addItem(
            pinId: pinId,
            scheduledDate: scheduledDate,
            startTime: startTime,
            endTime: endTime,
            note: note,
          );
      final current = state.valueOrNull;
      if (current != null && _dateOnly(scheduledDate) == ref.read(selectedScheduleDateProvider)) {
        state = AsyncData([...current, item]);
      }
      return null;
    } catch (e) {
      return e;
    }
  }

  Future<bool> removeItem(String itemId) async {
    final current = state.valueOrNull;
    if (current == null) return false;
    try {
      await ref.read(scheduleRepositoryProvider).removeItem(itemId);
      state = AsyncData(current.where((item) => item.id != itemId).toList());
      return true;
    } catch (_) {
      return false;
    }
  }
}

final scheduleControllerProvider = AsyncNotifierProvider<ScheduleController, List<ScheduleItem>>(
  ScheduleController.new,
);
