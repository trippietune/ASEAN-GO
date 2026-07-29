import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/providers.dart';
import '../data/settings_model.dart';
import '../data/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(apiClientProvider));
});

final notificationSettingsProvider =
    AsyncNotifierProvider<NotificationSettingsController, NotificationSettings>(
  NotificationSettingsController.new,
);

class NotificationSettingsController extends AsyncNotifier<NotificationSettings> {
  @override
  Future<NotificationSettings> build() {
    return ref.read(settingsRepositoryProvider).fetchNotificationSettings();
  }

  Future<void> save(NotificationSettings settings) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(settingsRepositoryProvider).updateNotificationSettings(settings),
    );
  }
}

final privacySettingsProvider = AsyncNotifierProvider<PrivacySettingsController, PrivacySettings>(
  PrivacySettingsController.new,
);

class PrivacySettingsController extends AsyncNotifier<PrivacySettings> {
  @override
  Future<PrivacySettings> build() {
    return ref.read(settingsRepositoryProvider).fetchPrivacySettings();
  }

  Future<void> save(PrivacySettings settings) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(settingsRepositoryProvider).updatePrivacySettings(settings),
    );
  }
}
