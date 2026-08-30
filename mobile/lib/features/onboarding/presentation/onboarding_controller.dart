import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether onboarding has been dismissed (Skip or Get Started) in this app
/// session. Intentionally in-memory only — the carousel is meant to greet
/// every fresh launch, not just the first-ever install, so there's nothing
/// to persist across restarts.
final onboardingDismissedProvider = StateProvider<bool>((ref) => false);
