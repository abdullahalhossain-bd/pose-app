// Smoke test for the real app shell. Camera hardware isn't available in
// the widget-test environment, so this only verifies the app boots into
// a loading state without throwing — it does not exercise camera, pose
// detection, or the onboarding flow itself. See docs/TESTING_STRATEGY.md
// for the fuller unit-test plan around GuidanceEngine, which does not
// need a device.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_visual_director/main.dart';

void main() {
  testWidgets('App boots without throwing and shows a loading state',
      (WidgetTester tester) async {
    // The root gate reads onboarding-completion state via
    // SharedPreferences before deciding whether to show onboarding or
    // the camera — mock it so the test doesn't hit a real platform
    // channel (which doesn't exist in the widget-test environment).
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(child: AiVisualDirectorApp()),
    );

    // Before the onboarding-completion check (and, if past that, the
    // camera permission/init) resolves, we expect a loading spinner —
    // never a blank screen (spec §15).
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
