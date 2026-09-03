import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_visual_director/features/camera/presentation/widgets/guidance_overlay.dart';
import 'package:ai_visual_director/features/guidance/domain/guidance_message.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('GuidanceOverlay', () {
    testWidgets('renders nothing for GuidanceMessage.none', (tester) async {
      await tester.pumpWidget(
        _wrap(const GuidanceOverlay(message: GuidanceMessage.none)),
      );
      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.text(''), findsNothing);
    });

    testWidgets('renders the Bengali guidance text for a correction message',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const GuidanceOverlay(message: GuidanceMessage.lowConfidence)),
      );
      expect(find.text(GuidanceMessage.lowConfidence.textBn), findsOneWidget);
    });

    testWidgets('shows a check icon for a confirmation message', (tester) async {
      await tester.pumpWidget(
        _wrap(const GuidanceOverlay(message: GuidanceMessage.holdPerfect)),
      );
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text(GuidanceMessage.holdPerfect.textBn), findsOneWidget);
    });

    testWidgets('shows a direction icon for an active correction, not a check',
        (tester) async {
      const correction = GuidanceMessage(
        state: PoseTrackingState.guidance,
        category: GuidanceCategory.position,
        textEn: 'Move slightly left',
        textBn: 'একটু বামে যান',
      );
      await tester.pumpWidget(_wrap(const GuidanceOverlay(message: correction)));
      expect(find.byIcon(Icons.navigation_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    });
  });
}
