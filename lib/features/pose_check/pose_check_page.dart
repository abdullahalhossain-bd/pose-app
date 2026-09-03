import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class PoseCheckPage extends StatefulWidget {
  const PoseCheckPage({super.key});

  @override
  State<PoseCheckPage> createState() => _PoseCheckPageState();
}

class _PoseCheckPageState extends State<PoseCheckPage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeFuture;
  String? _error;
  bool _frontCamera = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('NoCamera', 'No camera was found on this device.');
      }

      final selected = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      final future = controller.initialize();
      setState(() {
        _controller = controller;
        _initializeFuture = future;
        _error = null;
      });

      await future;
      if (mounted) setState(() {});
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _cameraErrorMessage(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'We could not start the camera. Please try again.';
      });
    }
  }

  String _cameraErrorMessage(CameraException error) {
    switch (error.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
        return 'Camera permission is off. Allow camera access in Settings to continue.';
      case 'CameraAccessRestricted':
        return 'Camera access is restricted on this device.';
      default:
        return error.description ?? 'We could not start the camera.';
    }
  }

  Future<void> _switchCamera() async {
    final cameras = await availableCameras();
    if (cameras.length < 2) return;

    final direction = _frontCamera
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    final selected = cameras.firstWhere(
      (camera) => camera.lensDirection == direction,
      orElse: () => cameras.first,
    );

    final oldController = _controller;
    final controller = CameraController(
      selected,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    setState(() {
      _controller = controller;
      _initializeFuture = controller.initialize();
      _frontCamera = !_frontCamera;
      _error = null;
    });

    await oldController?.dispose();
    try {
      await _initializeFuture;
      if (mounted) setState(() {});
    } on CameraException catch (e) {
      if (mounted) setState(() => _error = _cameraErrorMessage(e));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Pose Check'),
        actions: [
          IconButton(
            tooltip: 'Switch camera',
            onPressed: controller == null ? null : _switchCamera,
            icon: const Icon(Icons.flip_camera_android_rounded),
          ),
        ],
      ),
      body: _error != null
          ? _ErrorView(message: _error!, onRetry: _initializeCamera)
          : controller == null || _initializeFuture == null
              ? const Center(child: CircularProgressIndicator())
              : FutureBuilder<void>(
                  future: _initializeFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !controller.value.isInitialized) {
                      return _ErrorView(
                        message: 'Camera initialization failed. Please try again.',
                        onRetry: _initializeCamera,
                      );
                    }

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Center(child: CameraPreview(controller)),
                        IgnorePointer(
                          child: CustomPaint(painter: _FramingGuidePainter()),
                        ),
                        Positioned(
                          left: 20,
                          right: 20,
                          top: 20,
                          child: SafeArea(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Stand back so your full body fits inside the frame.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Squat analysis will use your body landmarks in the next milestone.',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 24,
                          right: 24,
                          bottom: 28,
                          child: SafeArea(
                            child: FilledButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Camera is ready. Live pose detection is the next engine milestone.',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Start squat check'),
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(54),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_rounded, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _FramingGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.7);
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.58,
        height: size.height * 0.72,
      ),
      const Radius.circular(28),
    );
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
