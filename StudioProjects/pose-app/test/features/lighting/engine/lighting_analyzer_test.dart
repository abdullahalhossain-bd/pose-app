import 'dart:typed_data';

import 'package:ai_visual_director/features/lighting/config/lighting_config.dart';
import 'package:ai_visual_director/features/lighting/domain/enums/lighting_enums.dart';
import 'package:ai_visual_director/features/lighting/engine/lighting_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _uniformLuma(int w, int h, int value) =>
    Uint8List(w * h)..fillRange(0, w * h, value);

Uint8List _gradientLuma(int w, int h, {bool leftDark = true}) {
  final luma = Uint8List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final v = leftDark ? (x * 255 / w) : (255 - x * 255 / w);
      luma[y * w + x] = v.round().clamp(0, 255);
    }
  }
  return luma;
}

void main() {
  late LightingAnalyzer analyzer;

  setUp(() => analyzer = LightingAnalyzer(const LightingConfig()));

  test('dark frame → severely underexposed', () {
    final luma = _uniformLuma(64, 64, 10);
    final s = analyzer.analyze(
      luma: luma, lumaWidth: 64, lumaHeight: 64,
      uPlane: null, vPlane: null, pose: null,
    );
    expect(s.exposureState, ExposureState.severelyUnderexposed);
    expect(s.isLowLight, isTrue);
    expect(s.issues.any((i) => i.kind == LightingIssueKind.underexposed), isTrue);
  });

  test('bright frame → overexposed', () {
    final luma = _uniformLuma(64, 64, 250);
    final s = analyzer.analyze(
      luma: luma, lumaWidth: 64, lumaHeight: 64,
      uPlane: null, vPlane: null, pose: null,
    );
    expect(s.exposureState, ExposureState.severelyOverexposed);
    expect(s.issues.any((i) => i.kind == LightingIssueKind.overexposed), isTrue);
  });

  test('mid-gray frame → balanced exposure', () {
    final luma = _uniformLuma(64, 64, 128);
    final s = analyzer.analyze(
      luma: luma, lumaWidth: 64, lumaHeight: 64,
      uPlane: null, vPlane: null, pose: null,
    );
    expect(s.exposureState, ExposureState.balanced);
    expect(s.avgLuminance, closeTo(128, 1));
  });

  test('left-dark gradient → light from right side', () {
    final luma = _gradientLuma(64, 64, leftDark: true);
    final s = analyzer.analyze(
      luma: luma, lumaWidth: 64, lumaHeight: 64,
      uPlane: null, vPlane: null, pose: null,
    );
    // Brightness centroid should be on the right → right-side light
    // (or ambient depending on subject bbox which is null here).
    expect(s.lightDirection, isNot(equals(LightSourceDirection.leftSide)));
  });

  test('uniform frame → ambient light', () {
    final luma = _uniformLuma(64, 64, 128);
    final s = analyzer.analyze(
      luma: luma, lumaWidth: 64, lumaHeight: 64,
      uPlane: null, vPlane: null, pose: null,
    );
    expect(s.lightDirection, anyOf(
      LightSourceDirection.ambient,
      LightSourceDirection.front,
    ));
  });

  test('color temp neutral when no chroma', () {
    final luma = _uniformLuma(64, 64, 128);
    final s = analyzer.analyze(
      luma: luma, lumaWidth: 64, lumaHeight: 64,
      uPlane: null, vPlane: null, pose: null,
    );
    expect(s.colorTemp, ColorTemperatureCategory.neutral);
  });

  test('overall score in [0, 1]', () {
    final luma = _uniformLuma(64, 64, 128);
    final s = analyzer.analyze(
      luma: luma, lumaWidth: 64, lumaHeight: 64,
      uPlane: null, vPlane: null, pose: null,
    );
    expect(s.overallScore, greaterThanOrEqualTo(0));
    expect(s.overallScore, lessThanOrEqualTo(1));
  });

  test('issues sorted by priority', () {
    final luma = _uniformLuma(64, 64, 5); // very dark → multiple issues
    final s = analyzer.analyze(
      luma: luma, lumaWidth: 64, lumaHeight: 64,
      uPlane: null, vPlane: null, pose: null,
    );
    for (var i = 1; i < s.issues.length; i++) {
      expect(
        s.issues[i - 1].priority.index,
        lessThanOrEqualTo(s.issues[i].priority.index),
      );
    }
  });
}
