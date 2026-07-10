import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// A skeleton placeholder box used inside shimmer-style loading layouts.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final double? borderRadius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Color.lerp(
              colors.skeletonBase,
              colors.skeletonHighlight,
              _controller.value,
            ),
            borderRadius:
                BorderRadius.circular(widget.borderRadius ?? 8),
          ),
          child: child,
        );
      },
      child: SizedBox(
        width: widget.width,
        height: widget.height,
      ),
    );
  }
}
