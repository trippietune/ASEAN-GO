import 'dart:async';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/api/api_client.dart' show currentApiLocale, scaffoldMessengerKey;
import 'core/error/app_error_logger.dart';
import 'core/localization/locale_controller.dart';
import 'core/router/app_shell.dart';
import 'core/router/splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/onboarding/presentation/onboarding_controller.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'l10n/generated/app_localizations.dart';

void main() {
  // Widget-tree build/layout/paint errors (e.g. a bad null-check inside a
  // build method) go through FlutterError.onError; everything else —
  // unawaited Future rejections, errors thrown from timers/microtasks
  // outside a build — only surfaces through the zone's error handler.
  // Both are needed; neither alone covers every crash source.
  FlutterError.onError = (details) {
    AppErrorLogger.record(details.exception, details.stack, context: 'FlutterError');
    FlutterError.presentError(details);
  };

  runZonedGuarded(
    () => runApp(const ProviderScope(child: AseanGoApp())),
    (error, stackTrace) => AppErrorLogger.record(error, stackTrace, context: 'Uncaught'),
  );
}

class AseanGoApp extends ConsumerWidget {
  const AseanGoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final themeMode = ref.watch(themeControllerProvider);
    final locale = ref.watch(localeControllerProvider);
    final onboardingDismissed = ref.watch(onboardingDismissedProvider);

    // Keeps the API client's error-message locale (read outside the widget
    // tree, where AppLocalizations.of(context) isn't reachable) in sync with
    // whatever MaterialApp will actually resolve: the explicit override when
    // set, otherwise the best match to the device locale, mirroring
    // MaterialApp's own "follow system" resolution.
    currentApiLocale = locale != null && AppLocalizations.supportedLocales.contains(locale)
        ? locale
        : AppLocalizations.supportedLocales.firstWhere(
            (l) => l.languageCode == PlatformDispatcher.instance.locale.languageCode,
            orElse: () => AppLocalizations.supportedLocales.first,
          );

    return MaterialApp(
      title: 'ASEAN GO',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: buildAppTheme(brightness: Brightness.light),
      darkTheme: buildAppTheme(brightness: Brightness.dark),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: switch (authState) {
        AuthAuthenticated() => const AppShell(),
        AuthUnauthenticated() => onboardingDismissed ? const LoginScreen() : const OnboardingScreen(),
        AuthInitial() || AuthLoading() => const SplashScreen(),
      },
    );
  }
}
