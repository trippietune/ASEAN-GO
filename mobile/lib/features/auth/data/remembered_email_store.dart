import 'package:shared_preferences/shared_preferences.dart';

const _rememberedEmailKey = 'remembered_email';

/// Persists the last-used login email when "remember me" is checked, so the
/// email field can be pre-filled next time — this is a UX convenience only,
/// not session persistence (the actual session token lives in secure storage
/// via [ApiClient] regardless of this setting).
class RememberedEmailStore {
  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_rememberedEmailKey);
  }

  Future<void> save(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rememberedEmailKey, email);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberedEmailKey);
  }
}
