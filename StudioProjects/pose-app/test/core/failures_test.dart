import 'package:ai_visual_director/core/error/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Failures', () {
    test('each Failure carries message + code', () {
      const f1 = NetworkFailure();
      expect(f1.message, isNotEmpty);
      expect(f1.code, 'network');

      const f2 = ServerFailure(message: 'boom', statusCode: 500);
      expect(f2.code, 'server');
      expect(f2.statusCode, 500);

      const f3 = ValidationFailure(message: 'bad', errors: {'a': 'b'});
      expect(f3.errors, {'a': 'b'});
    });

    test('toString includes runtimeType + code', () {
      const f = AuthFailure();
      expect(f.toString(), contains('AuthFailure'));
      expect(f.toString(), contains('auth'));
    });
  });
}
