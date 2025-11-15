# PRD-011: Game 2b - Mouse Visualizer

**Status**: ⚪ Not Started
**Dependencies**: PRD-008 (Integration & Base App)
**Estimated Effort**: 13 hours
**Priority**: P1
**Branch**: `feature/prd-011-game-mouse-visualizer`

## Overview

Real-time visualization of mouse position and button states. Shows a cursor trail, click ripples, and button state indicators.

## Goals

- ✅ Large, visible cursor (properly centered)
- ✅ Smooth trail effect following mouse movement
- ✅ Time-based trail animation (fades even when mouse is still)
- ✅ Click ripple animations (time-based, continuous)
- ✅ Button state indicators (L/R/M)
- ✅ Smooth 60 FPS tracking
- ✅ Centered cursor rendering (no offset issues)
- ✅ Trail particles update on every frame, not just on mouse move

## Technical Approach

### Mouse Tracking

```dart
class MouseVisualizerGame extends BaseGame with SingleTickerProviderStateMixin {
  Offset _mousePosition = Offset.zero;
  final List<TrailParticle> _trail = [];
  final List<ClickRipple> _ripples = [];
  bool _leftButtonDown = false;
  bool _rightButtonDown = false;
  bool _middleButtonDown = false;

  late AnimationController _animationController;
  DateTime _lastFrameTime = DateTime.now();

  @override
  void init() {
    super.init();
    // Continuous animation at 60 FPS
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(days: 365), // Effectively infinite
    )..repeat();

    _animationController.addListener(_updateFrame);
  }

  void _updateFrame() {
    final now = DateTime.now();
    final deltaTime = now.difference(_lastFrameTime).inMilliseconds / 1000.0;
    _lastFrameTime = now;

    // Update trail particles (fade over time)
    _trail.removeWhere((particle) {
      particle.age += deltaTime;
      return particle.age > particle.lifetime;
    });

    // Update ripples (expand and fade over time)
    _ripples.removeWhere((ripple) {
      ripple.age += deltaTime;
      return ripple.age > ripple.lifetime;
    });

    notifyListeners();
  }

  @override
  void onMouseEvent(InputEvent event) {
    if (event is MouseMoveEvent) {
      _mousePosition = Offset(event.x, event.y);

      // Add trail particle with timestamp
      _trail.add(TrailParticle(
        position: _mousePosition,
        createdAt: DateTime.now(),
      ));

      // Limit trail length
      if (_trail.length > 50) _trail.removeAt(0);
    } else if (event is MouseButtonEvent) {
      if (event.isDown) {
        _ripples.add(ClickRipple(
          position: Offset(event.x, event.y),
          color: _getButtonColor(event.button),
          createdAt: DateTime.now(),
        ));
      }

      // Update button states
      if (event.button == MouseButton.left) {
        _leftButtonDown = event.isDown;
      } else if (event.button == MouseButton.right) {
        _rightButtonDown = event.isDown;
      } else if (event.button == MouseButton.middle) {
        _middleButtonDown = event.isDown;
      }
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget buildUI() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          painter: MouseVisualizerPainter(
            mousePosition: _mousePosition,
            trail: _trail,
            ripples: _ripples,
            leftButtonDown: _leftButtonDown,
            rightButtonDown: _rightButtonDown,
            middleButtonDown: _middleButtonDown,
          ),
          child: Container(),
        );
      },
    );
  }
}

class TrailParticle {
  final Offset position;
  final DateTime createdAt;
  double age = 0.0;
  final double lifetime = 1.0; // 1 second fade

  TrailParticle({
    required this.position,
    required this.createdAt,
  });

  double get opacity => 1.0 - (age / lifetime).clamp(0.0, 1.0);
}

class ClickRipple {
  final Offset position;
  final Color color;
  final DateTime createdAt;
  double age = 0.0;
  final double lifetime = 1.5; // 1.5 seconds expand and fade

  ClickRipple({
    required this.position,
    required this.color,
    required this.createdAt,
  });

  double get radius => age * 100; // Expands to 150px
  double get opacity => (1.0 - (age / lifetime)).clamp(0.0, 1.0);
}

class MouseVisualizerPainter extends CustomPainter {
  final Offset mousePosition;
  final List<TrailParticle> trail;
  final List<ClickRipple> ripples;
  final bool leftButtonDown;
  final bool rightButtonDown;
  final bool middleButtonDown;

  MouseVisualizerPainter({
    required this.mousePosition,
    required this.trail,
    required this.ripples,
    required this.leftButtonDown,
    required this.rightButtonDown,
    required this.middleButtonDown,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw ripples
    for (final ripple in ripples) {
      final paint = Paint()
        ..color = ripple.color.withOpacity(ripple.opacity * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawCircle(ripple.position, ripple.radius, paint);
    }

    // Draw trail
    for (int i = 0; i < trail.length; i++) {
      final particle = trail[i];
      final paint = Paint()
        ..color = Colors.white.withOpacity(particle.opacity * 0.5);

      // Gradient size based on trail position (larger = more recent)
      final size = 8.0 + (i / trail.length) * 12.0;
      canvas.drawCircle(particle.position, size, paint);
    }

    // Draw centered cursor (large, colorful)
    final cursorPaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.fill;

    final cursorOutlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Draw cursor centered at mouse position (no offset)
    canvas.drawCircle(mousePosition, 20, cursorPaint);
    canvas.drawCircle(mousePosition, 20, cursorOutlinePaint);

    // Draw button indicators in corners
    _drawButtonIndicator(
      canvas,
      size,
      'L',
      Alignment.topLeft,
      leftButtonDown,
      Colors.red,
    );
    _drawButtonIndicator(
      canvas,
      size,
      'R',
      Alignment.topRight,
      rightButtonDown,
      Colors.blue,
    );
    _drawButtonIndicator(
      canvas,
      size,
      'M',
      Alignment.bottomCenter,
      middleButtonDown,
      Colors.green,
    );
  }

  void _drawButtonIndicator(
    Canvas canvas,
    Size size,
    String label,
    Alignment alignment,
    bool isPressed,
    Color color,
  ) {
    final position = alignment.alongSize(size);
    final paint = Paint()
      ..color = isPressed ? color : color.withOpacity(0.3);

    canvas.drawCircle(position, 30, paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      position - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(MouseVisualizerPainter oldDelegate) => true;
}
```

### Visual Effects

**Cursor:**
- Large, colorful cursor (20px radius)
- Perfectly centered at mouse position (no offset)
- Cyan accent color with white outline

**Trail:**
- Time-based fading (1 second lifetime)
- Up to 50 trail particles
- Continuous fade animation even when mouse is still
- Gradient size (larger = more recent)
- Updates every frame at 60 FPS

**Ripples:**
- Time-based expansion and fade (1.5 seconds)
- Continuous animation even after click
- Expands to 150px radius
- Color-coded by button type
- Updates every frame at 60 FPS

**Button Indicators:**
- Positioned in screen corners
  - Top-left: Left button (red when pressed)
  - Top-right: Right button (blue when pressed)
  - Bottom-center: Middle button (green when pressed)
- 30px radius circles
- Opacity changes on press

**Technical Details:**
- Uses AnimationController for continuous 60 FPS updates
- Delta time calculation for smooth time-based animations
- CustomPainter for efficient rendering
- Automatic cleanup of old particles/ripples

## Acceptance Criteria

**Cursor:**
- [ ] Cursor follows mouse in real-time with no lag
- [ ] Cursor is perfectly centered (no offset issues)
- [ ] Cursor visible and distinct (20px radius)

**Trail:**
- [ ] Trail shows up to 50 particles with time-based fade
- [ ] Trail continues fading even when mouse is still
- [ ] Trail particles update every frame at 60 FPS
- [ ] Trail has gradient sizing (recent = larger)
- [ ] Smooth fade over 1 second

**Ripples:**
- [ ] Click creates expanding ripple
- [ ] Ripples continue animating after click (time-based)
- [ ] Ripples update every frame at 60 FPS
- [ ] Ripples expand to 150px radius over 1.5 seconds
- [ ] Ripples fade smoothly over lifetime
- [ ] Different colors for different mouse buttons

**Button Indicators:**
- [ ] Button indicators positioned in corners correctly
- [ ] Button indicators update immediately on press
- [ ] All three buttons (L/M/R) supported

**Performance:**
- [ ] Maintains smooth 60 FPS performance
- [ ] No frame drops during rapid mouse movement
- [ ] No frame drops during rapid clicks
- [ ] Efficient particle cleanup

**Testing:**
- [ ] Tests cover mouse state tracking
- [ ] Tests cover time-based animation updates
- [ ] Tests cover particle/ripple lifecycle
- [ ] Tests verify cursor centering
- [ ] Tests verify continuous animation (not just on mouse move)

## Implementation Steps

1. Implement mouse position tracking with centering (2h)
2. Setup AnimationController for continuous 60 FPS updates (1h)
3. Implement time-based trail system with delta time (2h)
4. Create CustomPainter with centered cursor rendering (2h)
5. Implement time-based click ripple animation (2h)
6. Add button indicators (1h)
7. Performance optimization and particle cleanup (1h)
8. Testing (including time-based animation tests) (2h)

---

**Can start in parallel with PRD-009, 010 after PRD-008!**
