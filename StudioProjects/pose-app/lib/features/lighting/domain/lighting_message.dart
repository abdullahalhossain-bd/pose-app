/// Coarse lighting classification. Kept small on purpose — v1 only
/// distinguishes "too dark", "too bright", and "fine", not direction,
/// color temperature, or backlighting (see LightingReading's class doc).
enum LightingCondition { unknown, tooDark, tooBright, good }

/// Human-facing lighting guidance, shaped like GuidanceMessage's text
/// fields so the UI's existing rendering (guidance_overlay.dart) can
/// display either without a parallel widget.
class LightingMessage {
  final LightingCondition condition;
  final String textEn;
  final String textBn;

  const LightingMessage({
    required this.condition,
    required this.textEn,
    required this.textBn,
  });

  static const LightingMessage unknown = LightingMessage(
    condition: LightingCondition.unknown,
    textEn: '',
    textBn: '',
  );

  static const LightingMessage good = LightingMessage(
    condition: LightingCondition.good,
    textEn: '',
    textBn: '',
  );

  static const LightingMessage tooDark = LightingMessage(
    condition: LightingCondition.tooDark,
    textEn: "Find more light",
    textBn: "আরেকটু আলোর দিকে যান",
  );

  static const LightingMessage tooBright = LightingMessage(
    condition: LightingCondition.tooBright,
    textEn: "Too much light — try facing away from it",
    textBn: "আলো বেশি — একটু অন্যদিকে ঘুরুন",
  );
}
