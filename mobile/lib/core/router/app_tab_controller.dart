import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index into AppShell's bottom nav (Home, Map, Quests, Schedule, Profile).
/// Lets other screens (e.g. Home's quick actions) switch tabs without a
/// Navigator push.
final selectedTabProvider = StateProvider<int>((ref) => 0);
