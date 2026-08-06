import 'package:flutter_test/flutter_test.dart';
import 'package:roamwise/main.dart';

void main() {
  testWidgets('Splash Screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RoamWiseApp());

    // Verify that our Splash Screen renders the app name.
    expect(find.text('RoamWise'), findsOneWidget);
  });
}

