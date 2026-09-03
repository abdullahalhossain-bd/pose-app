import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_visual_director/features/camera/presentation/widgets/permission_request_view.dart';

void main() {
  group('PermissionRequestView', () {
    testWidgets('shows an "Allow" action and invokes onRetry when tapped',
        (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: PermissionRequestView(onRetry: () => retried = true),
        ),
      );

      expect(find.text('Allow Camera Access'), findsOneWidget);
      expect(find.text('Open Settings'), findsNothing);

      await tester.tap(find.text('Allow Camera Access'));
      await tester.pump();

      expect(retried, true);
    });

    testWidgets('shows "Open Settings" instead of retry when permanently denied',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: PermissionRequestView(
            onRetry: () {},
            permanentlyDenied: true,
          ),
        ),
      );

      expect(find.text('Open Settings'), findsOneWidget);
      expect(find.text('Allow Camera Access'), findsNothing);
    });

    testWidgets('explains that processing is on-device, not uploaded',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: PermissionRequestView(onRetry: () {}),
        ),
      );

      expect(find.textContaining('device'), findsOneWidget);
    });
  });
}
