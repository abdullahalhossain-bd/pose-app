import 'package:flutter/widgets.dart';

import '../../../core/extensions/context_extensions.dart';

/// Standard vertical gap widget. Use instead of `SizedBox(height: ...)`
/// for readability.
class AppGap extends StatelessWidget {
  const AppGap.xs({super.key}) : _size = 4;
  const AppGap.sm({super.key}) : _size = 8;
  const AppGap.md({super.key}) : _size = 16;
  const AppGap.lg({super.key}) : _size = 24;
  const AppGap.xl({super.key}) : _size = 32;
  const AppGap.xxl({super.key}) : _size = 48;
  const AppGap({super.key, required double size}) : _size = size;

  final double _size;

  @override
  Widget build(BuildContext context) => SizedBox(height: _size);
}

/// Horizontal variant.
class AppGapH extends StatelessWidget {
  const AppGapH.xs({super.key}) : _size = 4;
  const AppGapH.sm({super.key}) : _size = 8;
  const AppGapH.md({super.key}) : _size = 16;
  const AppGapH.lg({super.key}) : _size = 24;
  const AppGapH.xl({super.key}) : _size = 32;
  const AppGapH.xxl({super.key}) : _size = 48;
  const AppGapH({super.key, required double size}) : _size = size;

  final double _size;

  @override
  Widget build(BuildContext context) => SizedBox(width: _size);
}

/// Standard screen body wrapper with horizontal padding.
class AppScreenBody extends StatelessWidget {
  const AppScreenBody({
    super.key,
    required this.child,
    this.scrollable = false,
    this.padding,
  });

  final Widget child;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final inner = Padding(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: context.spacing.screenHorizontal,
            vertical: context.spacing.screenVertical,
          ),
      child: child,
    );
    return scrollable
        ? SingleChildScrollView(child: inner)
        : SafeArea(child: inner);
  }
}
