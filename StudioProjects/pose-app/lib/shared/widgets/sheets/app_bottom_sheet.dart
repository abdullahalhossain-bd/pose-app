import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// Shows a Material 3 bottom sheet with the app's design tokens.
///
/// Wrap any custom sheet content in this widget to inherit consistent
/// padding, drag handle, and surface styling.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.padding,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: padding ??
            EdgeInsets.fromLTRB(
              context.spacing.screenHorizontal,
              context.spacing.sm,
              context.spacing.screenHorizontal,
              context.spacing.lg,
            ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null || actions != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    if (title != null)
                      Expanded(
                        child: Text(
                          title!,
                          style: context.textTheme.titleLarge,
                        ),
                      ),
                    if (actions != null) ...actions!,
                  ],
                ),
              ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

/// Helper that displays a modal bottom sheet with the standard styling.
Future<T?> showAppModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useSafeArea = true,
  Color? barrierColor,
  String? barrierLabel,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel,
    showDragHandle: true,
    builder: builder,
  );
}
