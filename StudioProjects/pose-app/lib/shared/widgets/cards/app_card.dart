import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// Surface card with optional leading icon, title, subtitle, trailing.
///
/// Material 3 card with our app's radius and elevation tokens.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
  });

  factory AppCard.listTile({
    Key? key,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return AppCard(
      key: key,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

/// Stat card — big number above a small label. Used in dashboards.
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.trend,
  });

  final String label;
  final String value;
  final IconData? icon;
  final TrendIndicator? trend;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, color: cs.primary),
              const SizedBox(height: 12),
            ],
            Text(
              value,
              style: context.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  label,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (trend != null) ...[
                  const SizedBox(width: 8),
                  trend!,
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum TrendDirection { up, down, neutral }

class TrendIndicator extends StatelessWidget {
  const TrendIndicator({
    super.key,
    required this.direction,
    required this.value,
  });

  final TrendDirection direction;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = switch (direction) {
      TrendDirection.up => colors.success,
      TrendDirection.down => colors.danger,
      TrendDirection.neutral => context.colorScheme.onSurfaceVariant,
    };
    final icon = switch (direction) {
      TrendDirection.up => Icons.arrow_upward,
      TrendDirection.down => Icons.arrow_downward,
      TrendDirection.neutral => Icons.remove,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
