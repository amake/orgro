// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts_lite.dart';
import 'package:orgro/main.dart';

void main() {
  GoogleFontsLite.config.allowRuntimeFetching = false;

  testWidgets('Instantiate app test', (tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(buildApp(isTest: true));
    // Flush the asynchronous system-font notification before teardown.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  });
}
