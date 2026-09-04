import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../widgets.dart';

/// Visual gallery of every design-system widget.
///
/// Used by designers/engineers to verify token usage and as living
/// documentation. Route: `/dev/gallery` (added to the router in
/// Day 6 polish).
class DesignSystemGallery extends StatelessWidget {
  const DesignSystemGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Design System')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Section(title: 'Buttons', children: [
            AppPrimaryButton(label: 'Primary', onPressed: () {}),
            AppSecondaryButton(label: 'Secondary', onPressed: () {}),
            AppTextButton(label: 'Text', onPressed: () {}),
            AppPrimaryButton(
              label: 'Loading',
              loading: true,
              onPressed: () {},
            ),
            AppPrimaryButton(
              label: 'Disabled',
              onPressed: null,
            ),
          ]),
          SizedBox(height: 24),
          _Section(title: 'Inputs', children: [
            AppTextField(label: 'Name', hint: 'Jane Doe'),
            AppEmailField(),
            AppPasswordField(),
          ]),
          SizedBox(height: 24),
          _Section(title: 'Cards', children: [
            AppCard(child: Text('Plain card content')),
            AppCard.listTile(
              icon: Icons.camera_alt,
              title: 'Camera',
              subtitle: 'Tap to open',
            ),
          ]),
          SizedBox(height: 24),
          _Section(title: 'Loading', children: [
            AppSkeleton(width: 200, height: 12),
            AppSkeleton(width: 140, height: 12),
            AppLoadingIndicator(),
          ]),
          SizedBox(height: 24),
          _Section(title: 'States', children: [
            SizedBox(
              height: 280,
              child: AppEmptyState(
                icon: Icons.history,
                title: 'No history yet',
                description: 'Photos you capture will appear here.',
              ),
            ),
            SizedBox(
              height: 280,
              child: AppErrorState(
                title: 'Could not load',
                description: 'Network unreachable.',
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: children,
        ),
      ],
    );
  }
}
