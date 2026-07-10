import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../shared/widgets/widgets.dart';

/// The first thing users see after auth.
///
/// Hero CTA → open the camera. Below: empty-state hints for what to do
/// next. As features ship (history, AI suggestions) this screen fills
/// up with cards.
class MainHomeScreen extends ConsumerWidget {
  const MainHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AppPageHeader(
                title: 'Capture',
                subtitle: 'Your visual director is ready when you are.',
              ),
            ),
            const SliverToBoxAdapter(child: AppGap.md()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _HeroCameraCard(onTap: () => context.push(RoutePaths.camera)),
              ),
            ),
            const SliverToBoxAdapter(child: AppGap.lg()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Quick actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: AppGap.sm()),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  childAspectRatio: 1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildListDelegate.fixed([
                  _QuickActionTile(
                    icon: Icons.camera_alt,
                    label: 'New capture',
                    color: cs.primaryContainer,
                    iconColor: cs.onPrimaryContainer,
                    onTap: () => context.push(RoutePaths.camera),
                  ),
                  _QuickActionTile(
                    icon: Icons.history,
                    label: 'History',
                    color: cs.secondaryContainer,
                    iconColor: cs.onSecondaryContainer,
                    onTap: () => context.go('${RoutePaths.home}${RoutePaths.history}'),
                  ),
                  _QuickActionTile(
                    icon: Icons.bookmark_outline,
                    label: 'Saved',
                    color: cs.tertiaryContainer,
                    iconColor: cs.onTertiaryContainer,
                    onTap: () {},
                  ),
                  _QuickActionTile(
                    icon: Icons.tips_and_updates_outlined,
                    label: 'Tips',
                    color: cs.surfaceContainerHighest,
                    iconColor: cs.onSurface,
                    onTap: () {},
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCameraCard extends StatelessWidget {
  const _HeroCameraCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.camera_alt, size: 40, color: cs.onPrimaryContainer),
              const AppGap.md(),
              Text(
                'Start a session',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const AppGap.xs(),
              Text(
                'Open the camera and let your visual director guide the shot.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onPrimaryContainer.withOpacity(0.85),
                    ),
              ),
              const AppGap.lg(),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Open camera'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 28),
              const Spacer(),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
