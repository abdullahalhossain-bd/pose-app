import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// Standard app bar with optional leading back button and actions.
///
/// Wraps [AppBar] so all screens share consistent typography + spacing.
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.centerTitle,
    this.bottom,
    this.flexibleSpace,
  });

  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final bool? centerTitle;
  final PreferredSizeWidget? bottom;
  final Widget? flexibleSpace;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarSize + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      leading: leading,
      actions: actions,
      centerTitle: centerTitle,
      bottom: bottom,
      flexibleSpace: flexibleSpace,
    );
  }
}

/// Sliver variant of [AppAppBar] for use inside [CustomScrollView]s.
class AppSliverAppBar extends StatelessWidget {
  const AppSliverAppBar({
    super.key,
    this.title,
    this.actions,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.stretch = false,
    this.expandedHeight,
    this.flexibleSpace,
  });

  final String? title;
  final List<Widget>? actions;
  final bool pinned;
  final bool floating;
  final bool snap;
  final bool stretch;
  final double? expandedHeight;
  final Widget? flexibleSpace;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: title != null ? Text(title!) : null,
      actions: actions,
      pinned: pinned,
      floating: floating,
      snap: snap,
      stretch: stretch,
      expandedHeight: expandedHeight,
      flexibleSpace: flexibleSpace,
    );
  }
}

/// Convenience: page header with title + subtitle on top of a screen body.
/// Use when there is no [AppBar] (e.g. inside the home tab).
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.spacing.screenHorizontal,
        context.spacing.md,
        context.spacing.screenHorizontal,
        context.spacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
