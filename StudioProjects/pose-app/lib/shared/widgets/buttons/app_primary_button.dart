import 'package:flutter/material.dart';

/// Primary call-to-action button.
///
/// Wraps [FilledButton] with the app's design tokens. Always set
/// [onPressed] to `null` (not a no-op) when the action is unavailable
/// — that triggers the disabled style automatically.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final body = switch ((loading, icon)) {
      (true, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
      (false, final i) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(i, size: 18), const SizedBox(width: 8), Text(label)],
        ),
      (false, null) => Text(label),
    };

    final button = FilledButton(
      onPressed: loading ? null : onPressed,
      child: body,
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
