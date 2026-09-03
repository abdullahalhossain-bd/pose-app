import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';

/// The shutter button. Adds real tactile feedback (a subtle press-down
/// scale + haptic tick) that a plain `GestureDetector.onTap` doesn't
/// give you — this is one of the small details that separates a
/// premium camera app from a generic Flutter template (spec §12/§33:
/// "premium, not cheap").
class CaptureButton extends StatefulWidget {
  const CaptureButton({
    super.key,
    required this.onPressed,
    required this.isCapturing,
    required this.isReadyForPerfectShot,
  });

  final VoidCallback onPressed;
  final bool isCapturing;

  /// True when the guidance engine reports the pose is currently good —
  /// draws a thin accent ring so the manual shutter still benefits from
  /// AI feedback (manual capture always remains available, spec §5).
  final bool isReadyForPerfectShot;

  @override
  State<CaptureButton> createState() => _CaptureButtonState();
}

class _CaptureButtonState extends State<CaptureButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.isCapturing) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    if (widget.isCapturing) return;
    HapticFeedback.mediumImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.isCapturing ? null : _handleTap,
      child: Semantics(
        label: widget.isCapturing ? 'Capturing photo' : 'Take photo',
        button: true,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.isReadyForPerfectShot
                    ? AppColors.accent
                    : Colors.white.withValues(alpha: 0.7),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: (widget.isReadyForPerfectShot
                          ? AppColors.accent
                          : Colors.black)
                      .withValues(
                          alpha: widget.isReadyForPerfectShot ? 0.35 : 0.25),
                  blurRadius: 16,
                  spreadRadius: widget.isReadyForPerfectShot ? 2 : 0,
                ),
              ],
            ),
            padding: const EdgeInsets.all(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: widget.isCapturing
                  ? const Padding(
                      padding: EdgeInsets.all(18),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.background,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
