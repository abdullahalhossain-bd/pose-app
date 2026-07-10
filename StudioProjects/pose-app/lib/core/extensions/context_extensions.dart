import 'package:flutter/material.dart';

import '../theme/extensions/app_colors_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';

/// Convenience accessors on [BuildContext] for theme tokens.
///
/// Goal: keep widget code terse without losing type safety. Instead of
/// `Theme.of(context).extension<AppColorsExtension>()!` everywhere,
/// we write `context.colors.success`.
extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.sizeOf(this);
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);
  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  AppColorsExtension get colors =>
      Theme.of(this).extension<AppColorsExtension>()!;
  AppSpacingExtension get spacing =>
      Theme.of(this).extension<AppSpacingExtension>()!;

  double get screenHeight => screenSize.height;
  double get screenWidth => screenSize.width;

  /// Whether the current form factor is a tablet or larger.
  bool get isTablet => shortestSide >= 600;
  double get shortestSide => mediaQuery.size.shortestSide;
}

/// Snackbars / sheets / dialogs invoked from context.
extension BuildContextOverlayExtensions on BuildContext {
  void showSnack(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }

  void showErrorSnack(String message) {
    final colors = Theme.of(this).extension<AppColorsExtension>()!;
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: colors.danger,
        ),
      );
  }
}
