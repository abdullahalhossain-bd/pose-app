import 'package:flutter/foundation.dart';

/// Pose-specific AI states. Extends the core [AiState] tree by
/// adding pose-tracking semantics that the Day 8 base states didn't
/// model.
///
/// These are emitted by [PoseStateController] which the pipeline
/// calls after every inference. The Day 8 [AiState] tree stays intact
/// for non-pose AI features (scene detection, etc.) that come later.
sealed class PoseState {
  const PoseState();

  /// Whether the skeleton overlay should render.
  bool get rendersSkeleton => false;

  /// Whether the user can capture right now.
  bool get canCapture => false;

  String get label;
}

class PoseIdle extends PoseState {
  const PoseIdle();
  @override
  String get label => 'Idle';
}

class PoseSearching extends PoseState {
  const PoseSearching();
  @override
  String get label => 'Searching for person…';
}

class PosePersonFound extends PoseState {
  const PosePersonFound({required this.confidence});
  final double confidence;
  @override
  bool get rendersSkeleton => true;
  @override
  String get label => 'Person found';
}

class PoseTracking extends PoseState {
  const PoseTracking({required this.trackId, required this.confidence});
  final int trackId;
  final double confidence;
  @override
  bool get rendersSkeleton => true;
  @override
  String get label => 'Tracking #$trackId';
}

class PoseLostTracking extends PoseState {
  const PoseLostTracking({required this.sinceEpoch});
  final int sinceEpoch;
  @override
  String get label => 'Lost tracking — reacquiring…';
}

class PoseLowConfidence extends PoseState {
  const PoseLowConfidence({required this.confidence});
  final double confidence;
  @override
  bool get rendersSkeleton => true;
  @override
  String get label => 'Low confidence';
}

class PoseReady extends PoseState {
  const PoseReady({required this.trackId, required this.confidence});
  final int trackId;
  final double confidence;
  @override
  bool get rendersSkeleton => true;
  @override
  bool get canCapture => true;
  @override
  String get label => 'Ready';
}

class PoseNoPerson extends PoseState {
  const PoseNoPerson();
  @override
  String get label => 'No person in frame';
}

class PoseError extends PoseState {
  const PoseError({required this.message, this.canRetry = true});
  final String message;
  final bool canRetry;
  @override
  String get label => 'Error: $message';
}

/// Pose-specific edge-case flags surfaced alongside the state.
@immutable
class PoseContext {
  const PoseContext({
    this.tooClose = false,
    this.tooFar = false,
    this.partialBody = false,
    this.occluded = false,
    this.multiplePeople = false,
    this.lowLight = false,
  });

  final bool tooClose;
  final bool tooFar;
  final bool partialBody;
  final bool occluded;
  final bool multiplePeople;
  final bool lowLight;

  bool get isOk =>
      !tooClose &&
      !tooFar &&
      !partialBody &&
      !occluded &&
      !multiplePeople &&
      !lowLight;

  PoseContext copyWith({
    bool? tooClose,
    bool? tooFar,
    bool? partialBody,
    bool? occluded,
    bool? multiplePeople,
    bool? lowLight,
  }) =>
      PoseContext(
        tooClose: tooClose ?? this.tooClose,
        tooFar: tooFar ?? this.tooFar,
        partialBody: partialBody ?? this.partialBody,
        occluded: occluded ?? this.occluded,
        multiplePeople: multiplePeople ?? this.multiplePeople,
        lowLight: lowLight ?? this.lowLight,
      );
}
