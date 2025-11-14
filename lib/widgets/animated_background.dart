/// Animated gradient background widget.
///
/// Provides visually appealing animated backgrounds for games and UI screens.
library;

import 'package:flutter/material.dart';

/// An animated gradient background that smoothly transitions between colors.
///
/// Features:
/// - Smooth color transitions
/// - Customizable color palette
/// - Configurable animation duration
/// - Automatic looping
/// - Optional direction changes
///
/// Example usage:
/// ```dart
/// AnimatedBackground(
///   colors: [Colors.blue, Colors.purple, Colors.pink],
///   duration: Duration(seconds: 8),
///   child: YourGameWidget(),
/// )
/// ```
class AnimatedBackground extends StatefulWidget {
  /// Creates an animated gradient background.
  const AnimatedBackground({
    required this.colors,
    this.duration = const Duration(seconds: 5),
    this.child,
    super.key,
  });

  /// Colors to cycle through in the gradient.
  ///
  /// Should have at least 2 colors. The gradient will smoothly transition
  /// between these colors over time.
  final List<Color> colors;

  /// Duration for one complete animation cycle.
  final Duration duration;

  /// Optional child widget to display on top of the background.
  final Widget? child;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void didUpdateWidget(AnimatedBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Calculate gradient stops based on animation value
        final value = _controller.value;
        final stops = <double>[];

        // Create stops for smooth gradient transition
        if (widget.colors.length == 2) {
          stops.addAll([0.0, 1.0]);
        } else {
          // For multiple colors, distribute stops evenly
          for (var i = 0; i < widget.colors.length; i++) {
            final baseStop = i / (widget.colors.length - 1);
            // Offset the stop position based on animation value
            final animatedStop = (baseStop + value) % 1.0;
            stops.add(animatedStop);
          }
          stops.sort();
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.colors,
              stops: stops,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A pulsing gradient background that expands and contracts.
///
/// Features:
/// - Pulsing animation effect
/// - Configurable pulse speed
/// - Smooth transitions
///
/// Example usage:
/// ```dart
/// PulsingBackground(
///   colors: [Colors.red, Colors.orange],
///   child: YourGameWidget(),
/// )
/// ```
class PulsingBackground extends StatefulWidget {
  /// Creates a pulsing gradient background.
  const PulsingBackground({
    required this.colors,
    this.duration = const Duration(seconds: 3),
    this.child,
    super.key,
  });

  /// Colors for the gradient.
  final List<Color> colors;

  /// Duration for one pulse cycle.
  final Duration duration;

  /// Optional child widget.
  final Widget? child;

  @override
  State<PulsingBackground> createState() => _PulsingBackgroundState();
}

class _PulsingBackgroundState extends State<PulsingBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(PulsingBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Calculate scale based on animation
        final scale = 1.0 + (_animation.value * 0.1);

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.colors,
              ),
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// A static gradient background (no animation).
///
/// Useful when you want consistent gradient styling without animation overhead.
///
/// Example usage:
/// ```dart
/// StaticGradientBackground(
///   colors: [Colors.blue, Colors.green],
///   child: YourWidget(),
/// )
/// ```
class StaticGradientBackground extends StatelessWidget {
  /// Creates a static gradient background.
  const StaticGradientBackground({
    required this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.child,
    super.key,
  });

  /// Colors for the gradient.
  final List<Color> colors;

  /// Gradient start alignment.
  final AlignmentGeometry begin;

  /// Gradient end alignment.
  final AlignmentGeometry end;

  /// Optional child widget.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: colors,
        ),
      ),
      child: child,
    );
  }
}

/// A radial gradient background that radiates from the center.
///
/// Example usage:
/// ```dart
/// RadialGradientBackground(
///   colors: [Colors.yellow, Colors.orange, Colors.red],
///   child: YourWidget(),
/// )
/// ```
class RadialGradientBackground extends StatelessWidget {
  /// Creates a radial gradient background.
  const RadialGradientBackground({
    required this.colors,
    this.center = Alignment.center,
    this.radius = 1.0,
    this.child,
    super.key,
  });

  /// Colors for the gradient.
  final List<Color> colors;

  /// Center point of the radial gradient.
  final AlignmentGeometry center;

  /// Radius of the gradient (0.0 to 1.0+).
  final double radius;

  /// Optional child widget.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: center,
          radius: radius,
          colors: colors,
        ),
      ),
      child: child,
    );
  }
}
