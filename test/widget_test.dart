import 'package:flutter_test/flutter_test.dart';
import 'package:pose/main.dart';

void main() {
  testWidgets('Pose dashboard renders core navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const PoseApp());
    expect(find.text('Ready to move?'), findsOneWidget);
    expect(find.text('Start pose check'), findsOneWidget);
    expect(find.text('Workouts'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
