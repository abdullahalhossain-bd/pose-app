import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// Error state with a retry CTA. Wired into [Failure] rendering across
/// the app — see `FailureView` for theFailure-aware variant.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.title,
    this.description,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  final String title;
  final String? description;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.screenHorizontal,
          vertical: context.spacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.dangerContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: colors.danger),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
