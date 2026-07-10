import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// Centered indeterminate loader. Use inside a [Scaffold] body when
/// there's nothing else to render yet.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: context.colorScheme.primary),
          if (label != null) ...[
            const SizedBox(height: 16),
            Text(
              label!,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
