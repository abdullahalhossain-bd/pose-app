import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pose_detection/flutter_pose_detection.dart';
import '../../core/pose/pose_landmark.dart';
import '../../core/exercise/exercise_definition.dart';
import '../../core/exercise/exercise_registry.dart';
import '../../core/exercise/exercise_catalog.dart';
import 'session_complete_page.dart';

const _purple = Color(0xFF6C5CE7);
const _ink = Color(0xFF17151F);

class LiveExerciseCheckPage extends StatefulWidget {
  final String exerciseId;
  const LiveExerciseCheckPage({super.key, required this.exerciseId});
  @override State<LiveExerciseCheckPage> createState() => _LiveExerciseCheckPageState();
}

class _LiveExerciseCheckPageState extends State<LiveExerciseCheckPage> with WidgetsBindingObserver {
  CameraController? camera;
  NpuPoseDetector? detector;
  ExerciseAnalyzer? analyzer;
  Future<void>? ready;
  bool running = false, busy = false, front = true;
  String status = 'READY';
  ExerciseFeedback? feedback;
  dynamic pose;
  int reps = 0;
  final List<int> repScores = [];

  ExerciseCatalogItem get exercise => exerciseById(widget.exerciseId);
  bool get hasDetection => pose != null;

  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    analyzer = ExerciseRegistry.create(widget.exerciseId);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      await camera?.dispose();
      final cams = await availableCameras();
      if (cams.isEmpty) throw Exception('No camera found');
      final selected = cams.firstWhere((c) => c.lensDirection == (front ? CameraLensDirection.front : CameraLensDirection.back), orElse: () => cams.first);
      final c = CameraController(selected, ResolutionPreset.medium, enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420);
      final f = c.initialize();
      if (mounted) setState(() { camera = c; ready = f; status = 'READY'; });
      await f;
    } catch (_) {
      if (mounted) setState(() => status = 'CAMERA ERROR');
    }
  }

  Future<void> _initDetector() async {
    detector ??= NpuPoseDetector(config: PoseDetectorConfig.realtime());
    if (!detector!.isInitialized) await detector!.initialize();
  }

  List<PosePoint> _points(Iterable<dynamic> landmarks) => landmarks.map<PosePoint>((x) => PosePoint(
    name: x.type.toString().split('.').last,
    x: (x.x as num).toDouble(),
    y: (x.y as num).toDouble(),
    confidence: (x.confidence as num?)?.toDouble() ?? 1,
  )).toList();

  Future<void> _start() async {
    final c = camera;
    if (c == null || !c.value.isInitialized || running) return;
    analyzer!.reset();
    repScores.clear();
    reps = 0;
    setState(() { running = true; status = 'FIND YOUR BODY'; feedback = null; pose = null; });
    try {
      await _initDetector();
      await c.startImageStream(_onFrame);
    } catch (_) {
      if (mounted) setState(() { running = false; status = 'ERROR'; });
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    if (!running || busy || detector == null) return;
    busy = true;
    try {
      final result = await detector!.processFrame(
        planes: image.planes.map((p) => {'bytes': p.bytes, 'bytesPerRow': p.bytesPerRow, 'bytesPerPixel': p.bytesPerPixel}).toList(),
        width: image.width, height: image.height, format: 'yuv420', rotation: camera?.description.sensorOrientation ?? 90,
      );
      if (!result.hasPoses) {
        if (mounted) setState(() { status = 'FIND YOUR BODY'; pose = null; });
        return;
      }
      final p = result.firstPose!;
      final points = _points(p.getVisibleLandmarks(threshold: .55));
      if (points.length < 6) {
        if (mounted) setState(() { status = 'LOW CONFIDENCE'; pose = p; });
        return;
      }
      final out = analyzer!.analyze(points);
      if (out.validRep) { reps++; repScores.add(out.score.clamp(0, 100)); }
      if (mounted) setState(() { pose = p; feedback = out; status = out.validRep ? 'REP COMPLETE' : out.score >= 75 ? 'GOOD FORM' : 'KEEP MOVING'; });
    } catch (_) {
      if (mounted) setState(() => status = 'DETECTING');
    } finally { busy = false; }
  }

  Future<void> _stop({bool summary = true}) async {
    if (!running) return;
    if (camera?.value.isStreamingImages == true) await camera!.stopImageStream();
    setState(() { running = false; status = summary ? 'SESSION COMPLETE' : 'PAUSED'; });
    if (!summary || !mounted) return;
    final scores = List<int>.from(repScores);
    final avg = scores.isEmpty ? (feedback?.score ?? 0) : (scores.reduce((a, b) => a + b) / scores.length).round();
    final best = scores.isEmpty ? avg : scores.reduce((a, b) => a > b ? a : b);
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => SessionCompletePage(exercise: widget.exerciseId, reps: scores.length, score: avg, bestScore: best, repScores: scores)));
  }

  @override void didChangeAppLifecycleState(AppLifecycleState s) { if (s != AppLifecycleState.resumed && running) _stop(summary: false); }
  @override void dispose() { WidgetsBinding.instance.removeObserver(this); camera?.dispose(); detector?.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final c = camera;
    final f = feedback;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(fit: StackFit.expand, children: [
        if (c != null && ready != null)
          FutureBuilder<void>(future: ready, builder: (_, s) => s.connectionState == ConnectionState.done && !s.hasError ? CameraPreview(c) : const Center(child: CircularProgressIndicator()))
        else const Center(child: CircularProgressIndicator()),
        const Positioned.fill(child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xAA000000), Color(0x05000000), Color(0xE6000000)]))))),
        SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(14, 8, 14, 0), child: Row(children: [
          _GlassButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(exercise.name, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)), const Text('Live form coaching', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600))])),
          _GlassButton(icon: Icons.flip_camera_android_rounded, onTap: running ? null : () async { front = !front; await _initCamera(); }),
        ]))),
        Positioned(top: 92, left: 0, right: 0, child: Center(child: _StatusPill(status: status))),
        if (!running)
          Positioned(top: 142, left: 22, right: 22, child: _SetupCard(exercise: exercise, tips: analyzer?.setupTips ?? const [])),
        if (running && !hasDetection)
          Positioned(top: 150, left: 28, right: 28, child: _CoachHint(icon: Icons.accessibility_new_rounded, text: 'Step into frame so your whole body is visible.')),
        if (running && hasDetection)
          Positioned(top: 150, left: 28, right: 28, child: _FramingGuide()),
        Positioned(left: 14, right: 14, bottom: 14, child: _LivePanel(
          reps: reps, score: f?.score, phase: f?.phase.name, message: f?.messages.isNotEmpty == true ? f!.messages.first : (running ? 'Follow the movement cues.' : 'Set your position, then start your session.'),
          running: running, cameraReady: c?.value.isInitialized == true, exerciseName: exercise.name, onAction: running ? _stop : _start,
        )),
      ]),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon; final VoidCallback? onTap;
  const _GlassButton({required this.icon, required this.onTap});
  @override Widget build(BuildContext c) => Semantics(button: true, label: 'Camera control', child: Container(decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white24)), child: IconButton(onPressed: onTap, icon: Icon(icon, color: Colors.white))));
}

class _StatusPill extends StatelessWidget {
  final String status; const _StatusPill({required this.status});
  @override Widget build(BuildContext c) => Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white24)), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 7, height: 7, decoration: BoxDecoration(color: status == 'REP COMPLETE' ? Colors.white : _purple, shape: BoxShape.circle)), const SizedBox(width: 8), Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.1))]));
}

class _SetupCard extends StatelessWidget {
  final ExerciseCatalogItem exercise; final List<String> tips;
  const _SetupCard({required this.exercise, required this.tips});
  @override Widget build(BuildContext c) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: _purple.withOpacity(.28), borderRadius: BorderRadius.circular(12)), child: Icon(exercise.icon, color: Colors.white)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('SET YOUR POSITION', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2)), const SizedBox(height: 3), Text(exercise.description, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))]))]), const SizedBox(height: 14), ...tips.take(3).map((t) => Padding(padding: const EdgeInsets.only(bottom: 7), child: Row(children: [const Icon(Icons.check_circle_outline_rounded, color: Colors.white70, size: 16), const SizedBox(width: 8), Expanded(child: Text(t, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.25)))]))) ]));
}

class _CoachHint extends StatelessWidget { final IconData icon; final String text; const _CoachHint({required this.icon, required this.text}); @override Widget build(BuildContext c) => Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white12)), child: Row(children: [Icon(icon, color: Colors.white70, size: 20), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)))])); }
class _FramingGuide extends StatelessWidget { const _FramingGuide(); @override Widget build(BuildContext c) => IgnorePointer(child: CustomPaint(size: const Size(double.infinity, 220), painter: _GuidePainter())); }
class _GuidePainter extends CustomPainter { @override void paint(Canvas canvas, Size size) { final p = Paint()..color = Colors.white54..style = PaintingStyle.stroke..strokeWidth = 1.5; final r = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: size.width * .56, height: size.height * .88), const Radius.circular(26)); canvas.drawRRect(r, p); } @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false; }

class _LivePanel extends StatelessWidget {
  final int reps; final int? score; final String? phase, message, exerciseName; final bool running, cameraReady; final VoidCallback onAction;
  const _LivePanel({required this.reps, required this.score, required this.phase, required this.message, required this.running, required this.cameraReady, required this.exerciseName, required this.onAction});
  @override Widget build(BuildContext c) => Container(padding: const EdgeInsets.fromLTRB(16, 15, 16, 15), decoration: BoxDecoration(color: const Color(0xF21A1922), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white12), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 10))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [_Metric('REPS', '$reps'), const SizedBox(width: 9), _Metric('SCORE', score == null ? '—' : '$score'), const SizedBox(width: 9), _Metric('PHASE', phase == null ? 'Ready' : phase!.replaceAll('_', ' '))]),
    const SizedBox(height: 13),
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 7, height: 7, margin: const EdgeInsets.only(top: 6), decoration: const BoxDecoration(color: _purple, shape: BoxShape.circle)), const SizedBox(width: 9), Expanded(child: Text(message ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.35, fontWeight: FontWeight.w700)))]),
    const SizedBox(height: 14),
    SizedBox(width: double.infinity, height: 53, child: FilledButton.icon(onPressed: cameraReady ? onAction : null, icon: Icon(running ? Icons.stop_rounded : Icons.play_arrow_rounded), label: Text(running ? 'Finish session' : 'Start $exerciseName', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)), style: FilledButton.styleFrom(backgroundColor: _purple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))))),
  ]));
}

class _Metric extends StatelessWidget { final String label, value; const _Metric(this.label, this.value); @override Widget build(BuildContext c) => Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 11), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)), child: Column(children: [Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: .6))]))); }
