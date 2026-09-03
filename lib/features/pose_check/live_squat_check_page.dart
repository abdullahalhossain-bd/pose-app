import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pose_detection/flutter_pose_detection.dart';

class LiveSquatCheckPage extends StatefulWidget {
  const LiveSquatCheckPage({super.key});
  @override
  State<LiveSquatCheckPage> createState() => _LiveSquatCheckPageState();
}

class _LiveSquatCheckPageState extends State<LiveSquatCheckPage> with WidgetsBindingObserver {
  CameraController? camera;
  NpuPoseDetector? detector;
  Future<void>? cameraReady;
  bool running = false, busy = false, front = true;
  int reps = 0, frames = 0;
  String status = 'READY', phase = 'Standing';
  String feedback = 'Stand sideways and keep your whole body in frame.';
  double? knee;
  String? error;

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); initCamera(); }

  Future<void> initCamera() async {
    try {
      await camera?.dispose();
      final list = await availableCameras();
      if (list.isEmpty) throw CameraException('NoCamera', 'No camera found.');
      final selected = list.firstWhere((c) => c.lensDirection == (front ? CameraLensDirection.front : CameraLensDirection.back), orElse: () => list.first);
      final c = CameraController(selected, ResolutionPreset.medium, enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420);
      final ready = c.initialize();
      if (mounted) setState(() { camera = c; cameraReady = ready; error = null; });
      await ready;
    } on CameraException catch (e) { if (mounted) setState(() => error = e.description ?? 'Camera could not start.'); }
  }

  Future<void> initDetector() async {
    if (detector != null) return;
    final d = NpuPoseDetector(config: PoseDetectorConfig.realtime());
    await d.initialize();
    detector = d;
  }

  Future<void> start() async {
    final c = camera;
    if (c == null || !c.value.isInitialized || running) return;
    try {
      setState(() { error = null; status = 'GETTING READY'; reps = 0; frames = 0; phase = 'Standing'; knee = null; });
      await initDetector();
      setState(() { running = true; status = 'MOVE'; feedback = 'Lower down with control.'; });
      await c.startImageStream(onFrame);
    } catch (e) { if (mounted) setState(() { running = false; error = 'Pose detection could not start: $e'; }); }
  }

  Future<void> onFrame(CameraImage image) async {
    if (!running || busy || detector == null) return;
    busy = true; frames++;
    try {
      final planes = image.planes.map((p) => <String, dynamic>{'bytes': p.bytes, 'bytesPerRow': p.bytesPerRow, 'bytesPerPixel': p.bytesPerPixel}).toList();
      final result = await detector!.processFrame(planes: planes, width: image.width, height: image.height, format: 'yuv420', rotation: camera?.description.sensorOrientation ?? 90);
      if (!result.hasPoses) {
        if (mounted && frames % 10 == 0) setState(() { status = 'FIND YOUR BODY'; feedback = 'Step back until your head, hips, knees and feet are visible.'; });
        return;
      }
      final pose = result.firstPose!;
      if (pose.getVisibleLandmarks(threshold: .55).length < 8) {
        if (mounted && frames % 10 == 0) setState(() { status = 'LOW CONFIDENCE'; feedback = 'Improve lighting and keep your whole body in frame.'; });
        return;
      }
      final angle = pose.calculateAngle(LandmarkType.leftHip, LandmarkType.leftKnee, LandmarkType.leftAnkle);
      if (angle == null) return;
      final old = phase;
      String next;
      if (angle > 155) { next = 'Standing'; if (old == 'Ascending' || old == 'Bottom') reps++; }
      else if (angle > 110) next = old == 'Bottom' ? 'Ascending' : 'Descending';
      else next = 'Bottom';
      var message = next == 'Bottom' ? 'Good depth — keep your chest controlled.' : 'Keep the movement smooth.';
      if (angle < 70) message = 'Avoid collapsing too deep; stay controlled.';
      if (mounted && frames % 2 == 0) setState(() { phase = next; knee = angle; feedback = message; status = next == 'Bottom' ? 'GREAT' : 'MOVE'; });
    } catch (e) { if (mounted && frames % 30 == 0) setState(() => error = 'Frame skipped: $e'); }
    finally { busy = false; }
  }

  Future<void> stop() async {
    if (camera?.value.isStreamingImages == true) await camera!.stopImageStream();
    if (mounted) setState(() { running = false; status = 'SESSION COMPLETE'; feedback = reps == 0 ? 'No complete reps detected. Try again with your full body visible.' : 'Nice work — you completed $reps ${reps == 1 ? 'rep' : 'reps'}.'; });
  }

  Future<void> switchCamera() async { if (running) return; setState(() => front = !front); await initCamera(); }
  @override void didChangeAppLifecycleState(AppLifecycleState state) { if (state != AppLifecycleState.resumed && running) stop(); }
  @override void dispose() { WidgetsBinding.instance.removeObserver(this); camera?.dispose(); detector?.dispose(); super.dispose(); }

  Color _statusColor() {
    if (status == 'GREAT') return const Color(0xFF7CF2B0);
    if (status == 'LOW CONFIDENCE' || status == 'FIND YOUR BODY') return const Color(0xFFFFC76A);
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final c = camera;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(fit: StackFit.expand, children: [
        if (c != null && cameraReady != null)
          FutureBuilder<void>(future: cameraReady, builder: (_, s) => s.connectionState == ConnectionState.done && !s.hasError ? CameraPreview(c) : const Center(child: CircularProgressIndicator()))
        else const Center(child: CircularProgressIndicator()),
        const Positioned.fill(child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xAA000000), Color(0x11000000), Color(0xCC000000)], stops: [0, .45, 1]))))),
        Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _FramePainter()))),
        SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 0), child: Row(children: [
          _RoundButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.of(context).pop()),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Squat Check', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)), Text('Live form coaching', style: TextStyle(color: Colors.white60, fontSize: 12))])),
          _RoundButton(icon: Icons.flip_camera_android_rounded, onTap: running ? null : switchCamera),
        ]))),
        Positioned(top: 104, left: 24, right: 24, child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: Colors.black.withValues(alpha: .55), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white24)), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: _statusColor(), shape: BoxShape.circle)), const SizedBox(width: 8), Text(status, style: TextStyle(color: _statusColor(), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.1))]))),
        Positioned(left: 20, right: 20, bottom: 18, child: _CoachPanel(running: running, reps: reps, phase: phase, knee: knee, feedback: feedback, error: error, onAction: c == null ? null : (running ? stop : start))),
      ]),
    );
  }
}

class _CoachPanel extends StatelessWidget {
  const _CoachPanel({required this.running, required this.reps, required this.phase, required this.knee, required this.feedback, required this.error, required this.onAction});
  final bool running; final int reps; final String phase, feedback; final double? knee; final String? error; final VoidCallback? onAction;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.fromLTRB(18, 16, 18, 16), decoration: BoxDecoration(color: const Color(0xE8171720), borderRadius: BorderRadius.circular(26), border: Border.all(color: Colors.white12), boxShadow: const [BoxShadow(blurRadius: 30, offset: Offset(0, 10), color: Colors.black54)]), child: Column(children: [
    Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('REPS', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)), const SizedBox(height: 1), Text('$reps', style: const TextStyle(color: Colors.white, fontSize: 42, height: 1, fontWeight: FontWeight.w900))])),
      _Metric(value: phase, label: 'PHASE'), const SizedBox(width: 22), _Metric(value: knee == null ? '—' : '${knee!.round()}°', label: 'KNEE')]),
    const SizedBox(height: 12), Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .06), borderRadius: BorderRadius.circular(15)), child: Row(children: [const Icon(Icons.auto_awesome_rounded, color: Color(0xFFB9ADFF), size: 18), const SizedBox(width: 9), Expanded(child: Text(feedback, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3, fontWeight: FontWeight.w600)))])),
    if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.orangeAccent, fontSize: 11))),
    const SizedBox(height: 12), SizedBox(width: double.infinity, height: 52, child: FilledButton.icon(onPressed: onAction, icon: Icon(running ? Icons.stop_rounded : Icons.play_arrow_rounded), label: Text(running ? 'Finish session' : 'Start squat check'), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))))
  ]));
}

class _Metric extends StatelessWidget { const _Metric({required this.value, required this.label}); final String value, label; @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1))]); }
class _RoundButton extends StatelessWidget { const _RoundButton({required this.icon, required this.onTap}); final IconData icon; final VoidCallback? onTap; @override Widget build(BuildContext context) => Material(color: Colors.black.withValues(alpha: .55), shape: const CircleBorder(), child: InkWell(onTap: onTap, customBorder: const CircleBorder(), child: Padding(padding: const EdgeInsets.all(11), child: Icon(icon, color: onTap == null ? Colors.white24 : Colors.white, size: 21)))); }
class _FramePainter extends CustomPainter { @override void paint(Canvas c, Size s) { final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.white.withValues(alpha: .48); final r = Rect.fromCenter(center: Offset(s.width / 2, s.height * .47), width: s.width * .62, height: s.height * .68); c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(30)), p); final corner = Paint()..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.round..color = Colors.white.withValues(alpha: .9); const l = 22.0; final x1 = r.left, x2 = r.right, y1 = r.top, y2 = r.bottom; c.drawLine(Offset(x1, y1 + l), Offset(x1, y1), corner); c.drawLine(Offset(x1, y1), Offset(x1 + l, y1), corner); c.drawLine(Offset(x2 - l, y1), Offset(x2, y1), corner); c.drawLine(Offset(x2, y1), Offset(x2, y1 + l), corner); c.drawLine(Offset(x1, y2 - l), Offset(x1, y2), corner); c.drawLine(Offset(x1, y2), Offset(x1 + l, y2), corner); c.drawLine(Offset(x2 - l, y2), Offset(x2, y2), corner); c.drawLine(Offset(x2, y2 - l), Offset(x2, y2), corner); } @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false; }
