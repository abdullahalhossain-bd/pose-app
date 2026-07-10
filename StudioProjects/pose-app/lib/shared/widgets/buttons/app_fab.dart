import 'package:flutter/material.dart';

/// Floating action button sized to the app's design tokens.
class AppFab extends StatelessWidget {
  const AppFab({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.extended = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? label;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    if (extended && label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label!),
      );
    }
    return FloatingActionButton(onPressed: onPressed, child: Icon(icon));
  }
}
