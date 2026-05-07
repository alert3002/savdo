import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Semi-transparent shimmering skeleton placeholder.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    required this.child,
    this.enabled = true,
    this.borderRadius,
  });

  final Widget child;
  final bool enabled;
  final BorderRadius? borderRadius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1350),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    // Base layer: slightly lighter than background, like in the screenshot.
    final base = isDark ? const Color(0xFF2A2E33) : const Color(0xFFE7EAEE);
    final highlight = isDark ? const Color(0xFF3A4046) : const Color(0xFFF5F6F8);

    final radius = widget.borderRadius ?? BorderRadius.circular(16);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value; // 0..1
        // Move a diagonal highlight across the widget.
        final dx = -1.2 + (2.2 + 1.2) * t;

        return ClipRRect(
          borderRadius: radius,
          child: ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment(-1.0 + dx, -0.3),
                end: Alignment(1.0 + dx, 0.3),
                colors: [
                  base.withValues(alpha: 0.55),
                  highlight.withValues(alpha: 0.85),
                  base.withValues(alpha: 0.55),
                ],
                stops: const [0.40, 0.52, 0.64],
                transform: const GradientRotation(math.pi / 6),
              ).createShader(rect);
            },
            child: ColoredBox(
              color: base.withValues(alpha: 0.55),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: SizedBox(width: width, height: height),
    );
  }
}

class SkeletonText extends StatelessWidget {
  const SkeletonText({
    super.key,
    required this.width,
    this.height = 12,
    this.borderRadius,
  });

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
    );
  }
}

