import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roamwise/main.dart';

void main() {
  testWidgets('Splash Screen smoke test', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: RoamWiseApp(),
      ),
    );

    // Verify that our Splash Screen renders the app name.
    expect(find.text('RoamWise'), findsOneWidget);

    // Advance time to allow the splash screen's delayed transition timer to fire and resolve
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
