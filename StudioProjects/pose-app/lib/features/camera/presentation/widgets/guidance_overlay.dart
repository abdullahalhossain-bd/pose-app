import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../guidance/domain/guidance_message.dart';

/// Renders the single active guidance instruction as a floating glass
/// chip near the top of the camera preview.
///
/// Deliberately small and out of the way of the subject's face (spec
/// §13 — avoid covering the subject). Confirmation messages ("Perfect")
/// get the accent treatment; corrections stay neutral so the app never
/// feels like it's scolding the user. Uses a backdrop blur rather than
/// a flat semi-transparent fill — a small detail, but it's the
/// difference between looking like a generic Flutter overlay and
/// looking like a real camera app's HUD (spec §33: "premium, not
/// cheap").
class GuidanceOverlay extends StatelessWidget {
  const GuidanceOverlay({super.key, required this.message});

  final GuidanceMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.category == GuidanceCategory.none) {
      return const SizedBox.shrink();
    }

    final isConfirmation = message.isConfirmation;
    final isLowConfidence =
        message.category == GuidanceCategory.lowConfidence;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: ClipRRect(
        key: ValueKey('${message.category}-${message.textEn}'),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: isConfirmation
                  ? AppColors.accent.withValues(alpha: 0.18)
                  : AppColors.surface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: isConfirmation
                    ? AppColors.accent.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isConfirmation
                      ? Icons.check_circle_rounded
                      : isLowConfidence
                          ? Icons.person_search_rounded
                          : message.category == GuidanceCategory.lighting
                              ? Icons.wb_sunny_rounded
                              : message.category ==
                                      GuidanceCategory.composition
                                  ? Icons.crop_free_rounded
                                  : Icons.navigation_rounded,
                  size: 18,
                  color: isConfirmation
                      ? AppColors.accent
                      : AppColors.textPrimary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    message.textBn,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isConfirmation
                              ? AppColors.accent
                              : AppColors.textPrimary,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
