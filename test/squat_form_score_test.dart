import 'package:flutter_test/flutter_test.dart';
import 'package:pose/core/pose/squat_form_score.dart';

void main() {
  test('ideal squat depth scores excellent', () {
    final result = SquatFormScore.fromKneeAngle(95);
    expect(result.score, 100);
    expect(result.depthScore, 100);
    expect(result.label, 'Excellent');
  });

  test('shallow squat is scored lower and asks for more depth', () {
    final result = SquatFormScore.fromKneeAngle(130);
    expect(result.score, lessThan(100));
    expect(result.feedback, contains('deeper'));
  });

  test('very deep squat is not rewarded as perfect', () {
    final result = SquatFormScore.fromKneeAngle(60);
    expect(result.score, lessThan(100));
    expect(result.feedback, contains('controlled'));
  });

  test('score boundaries produce stable labels', () {
    expect(SquatFormScore.fromKneeAngle(120).label, 'Good');
    expect(SquatFormScore.fromKneeAngle(140).label, 'Needs work');
  });
}
