import 'package:ai_visual_director/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty', () {
      expect(Validators.email(null), 'Email is required');
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email('   '), 'Email is required');
    });
    test('rejects malformed', () {
      expect(Validators.email('plain'), 'Enter a valid email');
      expect(Validators.email('a@b'), 'Enter a valid email');
      expect(Validators.email('a@b.c'), 'Enter a valid email');
    });
    test('accepts valid', () {
      expect(Validators.email('a@b.com'), isNull);
      expect(Validators.email('  user@example.io  '), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects short', () {
      expect(Validators.password('Ab1'), 'At least 8 characters');
    });
    test('requires uppercase', () {
      expect(Validators.password('abcdefg1'), 'Add an uppercase letter');
    });
    test('requires digit', () {
      expect(Validators.password('Abcdefgh'), 'Add a number');
    });
    test('accepts valid', () {
      expect(Validators.password('Abcdefg1'), isNull);
    });
  });

  group('Validators.required', () {
    test('rejects empty', () {
      expect(Validators.required(null), 'Field is required');
      expect(Validators.required(''), 'Field is required');
    });
    test('accepts non-empty', () {
      expect(Validators.required('x'), isNull);
    });
    test('uses custom label', () {
      expect(Validators.required('', label: 'Name'), 'Name is required');
    });
  });
}
