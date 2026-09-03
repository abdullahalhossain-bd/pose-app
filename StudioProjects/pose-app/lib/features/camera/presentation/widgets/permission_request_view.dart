import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_theme.dart';

class PermissionRequestView extends StatelessWidget {
  const PermissionRequestView({
    super.key,
    required this.onRetry,
    this.permanentlyDenied = false,
  });

  final VoidCallback onRetry;
  final bool permanentlyDenied;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 32,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Camera access needed',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'AI Visual Director needs your camera to guide your pose '
              'and framing in real time. Nothing is uploaded — analysis '
              'happens entirely on your device.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: permanentlyDenied ? openAppSettings : onRetry,
              child: Text(
                permanentlyDenied ? 'Open Settings' : 'Allow Camera Access',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
