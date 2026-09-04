import 'package:flutter_test/flutter_test.dart';
import 'package:pose/main.dart';

void main() {
  testWidgets('Pose dashboard renders core navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const PoseApp());
    expect(find.text('Ready to move?'), findsOneWidget);
    expect(find.text('Check my form'), findsOneWidget);
    expect(find.text('Train'), findsWidgets);
    expect(find.text('Progress'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);
  });
}
