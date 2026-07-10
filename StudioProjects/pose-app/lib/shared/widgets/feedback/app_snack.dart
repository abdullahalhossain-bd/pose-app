import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

enum AppSnackKind { info, success, warning, error }

/// Helper for showing app-styled snackbars with semantic colors.
void showAppSnack(
  BuildContext context,
  String message, {
  AppSnackKind kind = AppSnackKind.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 3),
}) {
  final colors = context.colors;
  final (backgroundColor, foregroundColor) = switch (kind) {
    AppSnackKind.info => (context.colorScheme.inverseSurface,
        context.colorScheme.onInverseSurface),
    AppSnackKind.success => (colors.success, colors.onSuccess),
    AppSnackKind.warning => (colors.warning, colors.onWarning),
    AppSnackKind.error => (colors.danger, colors.onDanger),
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: foregroundColor)),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: foregroundColor,
                onPressed: onAction,
              )
            : null,
      ),
    );
}
