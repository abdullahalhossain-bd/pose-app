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
  String status = 'Camera ready', phase = 'Standing', feedback = 'Stand sideways and keep your full body visible.';
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
      setState(() { error = null; status = 'Loading pose model…'; reps = 0; frames = 0; phase = 'Standing'; });
      await initDetector();
      setState(() { running = true; status = 'Analyzing'; });
      await c.startImageStream(onFrame);
    } catch (e) { if (mounted) setState(() { running = false; error = 'Pose detection could not start: $e'; }); }
  }

  Future<void> onFrame(CameraImage image) async {
    if (!running || busy || detector == null) return;
    busy = true; frames++;
    try {
      final planes = image.planes.map((p) => <String, dynamic>{'bytes': p.bytes, 'bytesPerRow': p.bytesPerRow, 'bytesPerPixel': p.bytesPerPixel}).toList();
      final result = await detector!.processFrame(planes: planes, width: image.width, height: image.height, format: 'yuv420', rotation: camera?.description.sensorOrientation ?? 90);
      if (!result.hasPoses) { if (mounted && frames % 10 == 0) setState(() { status = 'Find your full body'; feedback = 'Step back so your head, hips, knees and feet are visible.'; }); return; }
      final pose = result.firstPose!;
      if (pose.getVisibleLandmarks(threshold: .55).length < 8) { if (mounted && frames % 10 == 0) setState(() { status = 'Low confidence'; feedback = 'Improve lighting and keep your whole body in frame.'; }); return; }
      final angle = pose.calculateAngle(LandmarkType.leftHip, LandmarkType.leftKnee, LandmarkType.leftAnkle);
      if (angle == null) return;
      final old = phase;
      String next;
      if (angle > 155) { next = 'Standing'; if (old == 'Ascending' || old == 'Bottom') reps++; }
      else if (angle > 110) next = old == 'Bottom' ? 'Ascending' : 'Descending';
      else next = 'Bottom';
      var message = next == 'Bottom' ? 'Good depth — keep your chest controlled.' : 'Keep the movement smooth.';
      if (angle < 70) message = 'Avoid collapsing too deep; keep the movement controlled.';
      if (mounted && frames % 2 == 0) setState(() { phase = next; knee = angle; feedback = message; status = 'Body detected'; });
    } catch (e) { if (mounted && frames % 30 == 0) setState(() => error = 'Frame skipped: $e'); }
    finally { busy = false; }
  }

  Future<void> stop() async {
    if (camera?.value.isStreamingImages == true) await camera!.stopImageStream();
    if (mounted) setState(() { running = false; status = 'Session complete'; feedback = reps == 0 ? 'No complete reps detected.' : 'Nice work — review your reps below.'; });
  }

  Future<void> switchCamera() async { if (running) return; setState(() => front = !front); await initCamera(); }
  @override void didChangeAppLifecycleState(AppLifecycleState state) { if (state != AppLifecycleState.resumed && running) stop(); }
  @override void dispose() { WidgetsBinding.instance.removeObserver(this); camera?.dispose(); detector?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = camera;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: const Text('Squat Check'), actions: [IconButton(onPressed: running ? null : switchCamera, icon: const Icon(Icons.flip_camera_android_rounded))]),
      body: Column(children: [
        Expanded(child: Stack(fit: StackFit.expand, children: [
          if (c != null && cameraReady != null) FutureBuilder<void>(future: cameraReady, builder: (_, s) => s.connectionState == ConnectionState.done && !s.hasError ? CameraPreview(c) : const Center(child: CircularProgressIndicator())) else const Center(child: CircularProgressIndicator()),
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _FramePainter()))),
          Positioned(top: 16, left: 16, right: 16, child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.black.withValues(alpha: .72), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(feedback, style: const TextStyle(color: Colors.white70))])))
        ])),
        Container(color: const Color(0xFF111111), padding: const EdgeInsets.fromLTRB(20, 14, 20, 24), child: Column(children: [
          Row(children: [Expanded(child: _Stat('$_reps', 'Reps')), Expanded(child: _Stat(knee == null ? '—' : '${knee!.round()}°', 'Knee')), Expanded(child: _Stat(phase, 'Phase'))]),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.orangeAccent))),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: c == null ? null : (running ? stop : start), icon: Icon(running ? Icons.stop_rounded : Icons.play_arrow_rounded), label: Text(running ? 'Finish session' : 'Start squat check'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)))
        ]))
      ]),
    );
  }
}

class _Stat extends StatelessWidget { const _Stat(this.value, this.label); final String value, label; @override Widget build(BuildContext context) => Column(children: [Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12))]); }
class _FramePainter extends CustomPainter { @override void paint(Canvas c, Size s) { final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.white.withValues(alpha: .7); c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(s.width / 2, s.height / 2), width: s.width * .58, height: s.height * .72), const Radius.circular(28)), p); } @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false; }
