import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/widgets.dart';

/// History placeholder.
///
/// Day 8+ will plug this into a real [SessionRepository] that streams
/// past capture sessions. For now it demonstrates the empty state UX
/// matching the design system.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AppPageHeader(
                title: 'History',
                subtitle: 'Past capture sessions and AI suggestions.',
              ),
            ),
            const SliverFillRemaining(
              hasScrollBody: false,
              child: AppEmptyState(
                icon: Icons.history,
                title: 'No history yet',
                description:
                'Photos and sessions you capture will appear here, '
                    'organized by date and location.',
                actionLabel: 'Start capturing',
              ),
            ),
          ],
        ),
      ),
    );
  }
}