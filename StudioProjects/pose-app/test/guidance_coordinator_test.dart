import 'package:flutter_test/flutter_test.dart';
import 'package:ai_visual_director/features/composition/domain/composition_message.dart';
import 'package:ai_visual_director/features/guidance/application/guidance_coordinator.dart';
import 'package:ai_visual_director/features/guidance/domain/guidance_message.dart';
import 'package:ai_visual_director/features/lighting/domain/lighting_message.dart';

void main() {
  const poseCorrection = GuidanceMessage(
    state: PoseTrackingState.guidance,
    category: GuidanceCategory.position,
    textEn: 'Move slightly left',
    textBn: 'একটু বামে যান',
  );

  const faceCamera = GuidanceMessage(
    state: PoseTrackingState.guidance,
    category: GuidanceCategory.attention,
    textEn: 'Face the camera',
    textBn: 'ক্যামেরার দিকে তাকান',
  );

  GuidanceMessage merge({
    GuidanceMessage poseGuidance = GuidanceMessage.holdPerfect,
    GuidanceMessage? attentionGuidance,
    CompositionMessage compositionGuidance = CompositionMessage.good,
    LightingMessage lightingGuidance = LightingMessage.good,
  }) {
    return mergeGuidance(
      poseGuidance: poseGuidance,
      attentionGuidance: attentionGuidance,
      compositionGuidance: compositionGuidance,
      lightingGuidance: lightingGuidance,
    );
  }

  group('mergeGuidance priority ordering', () {
    test('an active pose correction beats everything else', () {
      final result = merge(
        poseGuidance: poseCorrection,
        attentionGuidance: faceCamera,
        compositionGuidance: CompositionMessage.insufficientHeadroom,
        lightingGuidance: LightingMessage.tooDark,
      );
      expect(result, poseCorrection);
    });

    test('searching for a person beats attention/composition/lighting', () {
      final result = merge(
        poseGuidance: GuidanceMessage.searching,
        attentionGuidance: faceCamera,
        compositionGuidance: CompositionMessage.insufficientHeadroom,
        lightingGuidance: LightingMessage.tooDark,
      );
      expect(result.state, PoseTrackingState.searching);
    });

    test('attention (face the camera) beats composition and lighting', () {
      final result = merge(
        attentionGuidance: faceCamera,
        compositionGuidance: CompositionMessage.insufficientHeadroom,
        lightingGuidance: LightingMessage.tooDark,
      );
      expect(result.category, GuidanceCategory.attention);
      expect(result.textEn, 'Face the camera');
    });

    test('composition beats lighting when both are bad', () {
      final result = merge(
        compositionGuidance: CompositionMessage.excessiveHeadroom,
        lightingGuidance: LightingMessage.tooBright,
      );
      expect(result.category, GuidanceCategory.composition);
    });

    test('lighting surfaces when pose/attention/composition are all fine', () {
      final result = merge(lightingGuidance: LightingMessage.tooDark);
      expect(result.category, GuidanceCategory.lighting);
    });

    test('pose confirmation is shown as-is when everything is good', () {
      final result = merge();
      expect(result, GuidanceMessage.holdPerfect);
    });

    test('a secondary nudge preserves the underlying hold state so the capture ring stays lit', () {
      final result = merge(
        poseGuidance: GuidanceMessage.holdPerfect,
        lightingGuidance: LightingMessage.tooDark,
      );
      expect(result.state, PoseTrackingState.hold);
    });

    test('unknown composition/lighting readings (not yet sampled) never override a good pose', () {
      final result = merge(
        compositionGuidance: CompositionMessage.unknown,
        lightingGuidance: LightingMessage.unknown,
      );
      expect(result, GuidanceMessage.holdPerfect);
    });
  });
}
