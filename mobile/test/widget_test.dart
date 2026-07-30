import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asean_go_mobile/main.dart';

void main() {
  // flutter_secure_storage talks to native code over a MethodChannel, which
  // isn't available in the widget-test harness. Stub it so reads resolve to
  // "no stored token" instead of hanging forever.
  const secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureStorageChannel, (call) async {
    if (call.method == 'read') return null;
    return null;
  });

  testWidgets('shows the login screen when unauthenticated', (WidgetTester tester) async {
    // Default test locale is en_US; the app's supported locales are th/en with
    // th as the source, so pin en explicitly to make the assertion locale-independent.
    tester.platformDispatcher.localeTestValue = const Locale('en');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);

    await tester.pumpWidget(const ProviderScope(child: AseanGoApp()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to AseanGo'), findsOneWidget);
    expect(find.text("Let's go"), findsOneWidget);
  });
}
