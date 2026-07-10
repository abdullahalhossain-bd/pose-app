import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/widgets.dart';
import '../../../auth/presentation/providers/session_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              CircleAvatar(
                radius: 64,
                backgroundColor: cs.primaryContainer,
                child: Icon(
                  Icons.person,
                  size: 64,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const AppGap.md(),
              Text(
                session.email ?? 'Welcome',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const AppGap.lg(),
              AppSecondaryButton(
                label: 'Edit profile',
                icon: Icons.edit_outlined,
                onPressed: () {},
                expand: true,
              ),
              const AppGap.xl(),
              _StatRow(
                items: const [
                  _StatItem(label: 'Captures', value: '0'),
                  _StatItem(label: 'Saved', value: '0'),
                  _StatItem(label: 'Streak', value: '0d'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.items});
  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .map((item) => Expanded(child: AppStatCard(label: item.label, value: item.value)))
          .toList(),
    );
  }
}

class _StatItem {
  const _StatItem({required this.label, required this.value});
  final String label;
  final String value;
}