/// Mouse Visualizer game - real-time mouse position and button visualization.
///
/// This game displays:
/// - Large, colorful cursor at mouse position
/// - Trail effect following mouse movement (up to 30 positions within 1 second)
/// - Expanding ripple animations on clicks
/// - Button state indicators (L/R/M) showing which buttons are pressed
library;

import 'dart:async';

import 'package:flutter/material.dart';
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
  Timer? _animationTimer;

  @override
  String get id => 'mouse_visualizer';

  @override
  String get name => 'Mouse Visualizer';

  @override
  String get description =>
      'Real-time visualization of mouse position and button states';

  /// Schedules the next animation frame using a timer.
  void _scheduleNextFrame() {
    if (_disposed || _animationTimer != null) return;

    // Use a periodic timer for animations (~60 FPS = ~16ms)
    _animationTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_disposed) {
        timer.cancel();
        _animationTimer = null;
        return;
      }

      // Stop animation if no active elements
      if (_trail.isEmpty && _ripples.isEmpty) {
        timer.cancel();
        _animationTimer = null;
        return;
      }

      _notifyUpdate();
    });
  }

  @override
  Widget buildUI() {
    // Capture current time once per frame for all calculations
    final now = DateTime.now();

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
          return Stack(
            children: [
              // Background grid (optional, for visual reference)
              _buildBackgroundGrid(),

              // Button indicators
              _buildButtonIndicators(),

              // Instructions
              _buildInstructions(),

              // Ripples (drawn first, behind cursor and trail)
              ..._buildRipples(now),

              // Trail (drawn before cursor)
              ..._buildTrail(now),

              // Cursor (drawn last, on top)
              _buildCursor(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackgroundGrid() {
    return CustomPaint(
      size: Size.infinite,
      painter: _GridPainter(),
    );
  }

  Widget _buildCursor() {
    return Positioned(
      left: _mousePosition.dx - 20,
      top: _mousePosition.dy - 20,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [
              Color(0xFFFFFFFF), // White center
              Color(0xFF60A5FA), // Blue 400
              Color(0xFF3B82F6), // Blue 500
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.6),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTrail(DateTime now) {
    // Clean up old trail points (older than animation duration)
    _trail.removeWhere((point) {
      return now.difference(point.timestamp).inMilliseconds >
          _animationDurationMs;
    });

    final widgets = <Widget>[];
    for (var i = 0; i < _trail.length; i++) {
      final point = _trail[i];
      final age = now.difference(point.timestamp).inMilliseconds;
      final opacity = (1.0 - (age / _animationDurationMs)).clamp(0.0, 1.0);
      final size = _minTrailSize + (opacity * (_maxTrailSize - _minTrailSize));

      if (opacity > 0) {
        widgets.add(
          Positioned(
            left: point.position.dx - size / 2,
            top: point.position.dy - size / 2,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF60A5FA).withValues(alpha: opacity * 0.6),
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  List<Widget> _buildRipples(DateTime now) {
    final widgets = <Widget>[];

    // Remove old ripples
    _ripples.removeWhere((ripple) {
      return now.difference(ripple.timestamp).inMilliseconds >
          _animationDurationMs;
    });

    for (final ripple in _ripples) {
      final age = now.difference(ripple.timestamp).inMilliseconds;
      final progress = (age / _animationDurationMs).clamp(0.0, 1.0);
      final size =
          _rippleStartSize + (progress * (_rippleMaxSize - _rippleStartSize));
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      widgets.add(
        Positioned(
          left: ripple.position.dx - size / 2,
          top: ripple.position.dy - size / 2,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ripple.color.withValues(alpha: opacity),
                width: 3,
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
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
        color: isPressed ? color : color.withValues(alpha: 0.2),
        border: Border.all(
          color: color,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isPressed
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
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
    // Cancel animation timer
    _animationTimer?.cancel();
    _animationTimer = null;
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

/// Custom painter for the background grid.
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.1) // Slate 700
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
