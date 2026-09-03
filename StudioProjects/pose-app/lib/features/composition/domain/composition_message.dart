/// Coarse composition classification for v1. Scoped deliberately narrow:
/// headroom only. See CompositionAnalyzer's class doc for why rule-of-
/// thirds horizontal placement, symmetry, and horizon alignment are
/// explicitly NOT in this version rather than half-implemented.
enum CompositionCondition {
  unknown,
  insufficientHeadroom,
  excessiveHeadroom,
  good,
}

class CompositionMessage {
  final CompositionCondition condition;
  final String textEn;
  final String textBn;

  const CompositionMessage({
    required this.condition,
    required this.textEn,
    required this.textBn,
  });

  static const CompositionMessage unknown = CompositionMessage(
    condition: CompositionCondition.unknown,
    textEn: '',
    textBn: '',
  );

  static const CompositionMessage good = CompositionMessage(
    condition: CompositionCondition.good,
    textEn: '',
    textBn: '',
  );

  static const CompositionMessage insufficientHeadroom = CompositionMessage(
    condition: CompositionCondition.insufficientHeadroom,
    textEn: "Lower the camera slightly",
    textBn: "ক্যামেরা একটু নিচু করুন",
  );

  static const CompositionMessage excessiveHeadroom = CompositionMessage(
    condition: CompositionCondition.excessiveHeadroom,
    textEn: "Raise the camera slightly",
    textBn: "ক্যামেরা একটু উঁচু করুন",
  );
}
