/// Mouse Visualizer game - real-time mouse position and button visualization.
///
/// This game displays:
/// - Large, colorful cursor at mouse position
/// - Trail effect following mouse movement (up to 30 positions within 1 second)
/// - Expanding ripple animations on clicks
/// - Button state indicators (L/R/M) showing which buttons are pressed
library;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:keyboard_playground/games/base_game.dart';
import 'package:keyboard_playground/platform/input_events.dart' as events;

/// A visualizer that shows mouse position, trails, clicks, and button states.
///
/// Features:
/// - Smooth cursor tracking at 60 FPS
/// - Fading trail showing up to 30 mouse positions within 1 second
/// - Click ripple animations with different colors per button
/// - Real-time button state indicators in corners
class MouseVisualizerGame extends BaseGame {
  /// Creates a new mouse visualizer game.
  MouseVisualizerGame() {
    // Initialize with center position
    _mousePosition = const Offset(960, 540); // Default to 1920x1080 center
    // Animation ticker will start automatically when first event is received
  }

  // Animation constants
  static const int _animationDurationMs = 1000; // 1 second
  static const int _maxTrailPoints = 30;
  static const double _minTrailSize = 8;
  static const double _maxTrailSize = 20;
  static const double _rippleStartSize = 20;
  static const double _rippleMaxSize = 220;

  Offset _mousePosition = Offset.zero;
  final List<_TrailPoint> _trail = [];
  final List<_ClickRipple> _ripples = [];
  final Map<events.MouseButton, bool> _buttonStates = {
    events.MouseButton.left: false,
    events.MouseButton.right: false,
    events.MouseButton.middle: false,
  };

  final ValueNotifier<int> _updateNotifier = ValueNotifier<int>(0);
  bool _disposed = false;

  @override
  String get id => 'mouse_visualizer';

  @override
  String get name => 'Mouse Visualizer';

  @override
  String get description =>
      'Real-time visualization of mouse position and button states';

  /// Schedules the next animation frame using SchedulerBinding.
  void _scheduleNextFrame() {
    if (_disposed) return;

    // Stop animation if no active elements
    if (_trail.isEmpty && _ripples.isEmpty) {
      return;
    }

    // Use SchedulerBinding for optimal frame timing
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (!_disposed) {
        _notifyUpdate();
        _scheduleNextFrame();
      }
    });
  }

  @override
  Widget buildUI() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A), // Slate 900
            Color(0xFF1E1B4B), // Indigo 950
          ],
        ),
      ),
      child: ValueListenableBuilder<int>(
        valueListenable: _updateNotifier,
        builder: (context, _, __) {
          // Capture current time once per frame for all calculations
          final now = DateTime.now();

          return Stack(
            children: [
              // Background grid (static, using const)
              const _BackgroundGridWidget(),

              // Animated elements (using CustomPainter for better performance)
              RepaintBoundary(
                child: CustomPaint(
                  painter: _MouseVisualizerPainter(
                    trail: _trail,
                    ripples: _ripples,
                    mousePosition: _mousePosition,
                    currentTime: now,
                  ),
                  size: Size.infinite,
                ),
              ),

              // Button indicators (UI elements on top)
              _buildButtonIndicators(),

              // Instructions (UI elements on top)
              _buildInstructions(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildButtonIndicators() {
    return Positioned(
      top: 40,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left button indicator
          _buildButtonIndicator(
            'LEFT',
            events.MouseButton.left,
            const Color(0xFFEF4444), // Red
          ),
          const SizedBox(width: 40),

          // Middle button indicator
          _buildButtonIndicator(
            'MIDDLE',
            events.MouseButton.middle,
            const Color(0xFF10B981), // Green
          ),
          const SizedBox(width: 40),

          // Right button indicator
          _buildButtonIndicator(
            'RIGHT',
            events.MouseButton.right,
            const Color(0xFF3B82F6), // Blue
          ),
        ],
      ),
    );
  }

  Widget _buildButtonIndicator(
    String label,
    events.MouseButton button,
    Color color,
  ) {
    final isPressed = _buttonStates[button] ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isPressed ? color : color.withOpacity(0.2),
        border: Border.all(
          color: color,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isPressed
            ? [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isPressed ? Colors.white : color,
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return const Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: Column(
          children: [
            Text(
              'Move your mouse to see the trail',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white60,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Click to create ripple effects',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white38,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void onMouseEvent(events.InputEvent event) {
    if (event is events.MouseMoveEvent) {
      _handleMouseMove(event);
    } else if (event is events.MouseButtonEvent) {
      _handleMouseButton(event);
    }
    _notifyUpdate();
  }

  void _handleMouseMove(events.MouseMoveEvent event) {
    _mousePosition = Offset(event.x, event.y);

    // Add to trail
    _trail.add(
      _TrailPoint(
        position: _mousePosition,
        timestamp: DateTime.now(),
      ),
    );

    // Keep only last N points (time-based cleanup happens in buildUI)
    if (_trail.length > _maxTrailPoints) {
      _trail.removeAt(0);
    }

    // Restart ticker if it was stopped
    _scheduleNextFrame();
  }

  void _handleMouseButton(events.MouseButtonEvent event) {
    // Update button state
    _buttonStates[event.button] = event.isDown;

    // Create ripple on button down
    if (event.isDown) {
      _ripples.add(
        _ClickRipple(
          position: Offset(event.x, event.y),
          color: _getButtonColor(event.button),
          timestamp: DateTime.now(),
        ),
      );

      // Restart ticker if it was stopped
      _scheduleNextFrame();
    }
  }

  Color _getButtonColor(events.MouseButton button) {
    switch (button) {
      case events.MouseButton.left:
        return const Color(0xFFEF4444); // Red
      case events.MouseButton.right:
        return const Color(0xFF3B82F6); // Blue
      case events.MouseButton.middle:
        return const Color(0xFF10B981); // Green
      case events.MouseButton.other:
        return const Color(0xFFF59E0B); // Orange
    }
  }

  void _notifyUpdate() {
    _updateNotifier.value = (_updateNotifier.value + 1) % 1000;
  }

  @override
  void dispose() {
    _disposed = true;
    // Clear all animation state
    _trail.clear();
    _ripples.clear();
    _updateNotifier.dispose();
    super.dispose();
  }
}

/// Represents a point in the mouse trail.
class _TrailPoint {
  _TrailPoint({
    required this.position,
    required this.timestamp,
  });

  final Offset position;
  final DateTime timestamp;
}

/// Represents a click ripple animation.
class _ClickRipple {
  _ClickRipple({
    required this.position,
    required this.color,
    required this.timestamp,
  });

  final Offset position;
  final Color color;
  final DateTime timestamp;
}

/// Static background grid widget.
class _BackgroundGridWidget extends StatelessWidget {
  const _BackgroundGridWidget();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _GridPainter(),
    );
  }
}

/// Custom painter for the background grid.
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF334155).withOpacity(0.1) // Slate 700
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw vertical lines every 100px
    for (var x = 0.0; x < size.width; x += 100) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines every 100px
    for (var y = 0.0; y < size.height; y += 100) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for mouse visualizer animated elements.
class _MouseVisualizerPainter extends CustomPainter {
  const _MouseVisualizerPainter({
    required this.trail,
    required this.ripples,
    required this.mousePosition,
    required this.currentTime,
  });

  final List<_TrailPoint> trail;
  final List<_ClickRipple> ripples;
  final Offset mousePosition;
  final DateTime currentTime;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw ripples first (behind everything)
    _drawRipples(canvas);

    // Draw trail
    _drawTrail(canvas);

    // Draw cursor last (on top)
    _drawCursor(canvas);
  }

  void _drawTrail(Canvas canvas) {
    for (final point in trail) {
      final age = currentTime.difference(point.timestamp).inMilliseconds;
      if (age > MouseVisualizerGame._animationDurationMs) continue;

      final opacity = (1.0 - (age / MouseVisualizerGame._animationDurationMs))
          .clamp(0.0, 1.0);
      final size = MouseVisualizerGame._minTrailSize +
          (opacity *
              (MouseVisualizerGame._maxTrailSize -
                  MouseVisualizerGame._minTrailSize));

      if (opacity > 0) {
        final paint = Paint()
          ..color = const Color(0xFF60A5FA).withOpacity(opacity * 0.6)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(point.position, size / 2, paint);
      }
    }
  }

  void _drawRipples(Canvas canvas) {
    for (final ripple in ripples) {
      final age = currentTime.difference(ripple.timestamp).inMilliseconds;
      if (age > MouseVisualizerGame._animationDurationMs) continue;

      final progress =
          (age / MouseVisualizerGame._animationDurationMs).clamp(0.0, 1.0);
      final size = MouseVisualizerGame._rippleStartSize +
          (progress *
              (MouseVisualizerGame._rippleMaxSize -
                  MouseVisualizerGame._rippleStartSize));
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      if (opacity > 0) {
        final paint = Paint()
          ..color = ripple.color.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;

        canvas.drawCircle(ripple.position, size / 2, paint);
      }
    }
  }

  void _drawCursor(Canvas canvas) {
    // Outer glow
    final glowPaint = Paint()
      ..color = const Color(0xFF3B82F6).withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(mousePosition, 25, glowPaint);

    // Gradient fill (simulated with multiple circles)
    final centerPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(mousePosition, 20, centerPaint);

    final midPaint = Paint()
      ..color = const Color(0xFF60A5FA)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(mousePosition, 15, midPaint);

    final outerPaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(mousePosition, 10, outerPaint);
  }

  @override
  bool shouldRepaint(_MouseVisualizerPainter oldDelegate) {
    return trail.length != oldDelegate.trail.length ||
        ripples.length != oldDelegate.ripples.length ||
        mousePosition != oldDelegate.mousePosition ||
        currentTime != oldDelegate.currentTime;
  }
}
