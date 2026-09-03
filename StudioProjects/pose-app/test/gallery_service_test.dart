import 'package:flutter_test/flutter_test.dart';
import 'package:ai_visual_director/features/gallery/data/gallery_service.dart';

void main() {
  group('parseCaptureTimestamp', () {
    test('parses a well-formed capture filename', () {
      final result = parseCaptureTimestamp('avd_1700000000000.jpg');
      expect(result, DateTime.fromMillisecondsSinceEpoch(1700000000000));
    });

    test('returns null for a file without the avd_ prefix', () {
      expect(parseCaptureTimestamp('IMG_1234.jpg'), isNull);
    });

    test('returns null for a file without the .jpg suffix', () {
      expect(parseCaptureTimestamp('avd_1700000000000.png'), isNull);
    });

    test('returns null when the timestamp segment is not a valid integer', () {
      expect(parseCaptureTimestamp('avd_not_a_number.jpg'), isNull);
    });

    test('returns null for an unrelated file like .DS_Store', () {
      expect(parseCaptureTimestamp('.DS_Store'), isNull);
    });
  });
}
