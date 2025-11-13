# PRD-011: Game 2b - Mouse Visualizer

**Status**: ⚪ Not Started  
**Dependencies**: PRD-008 (Integration & Base App)  
**Estimated Effort**: 8 hours  
**Priority**: P1  
**Branch**: `feature/prd-011-game-mouse-visualizer`

## Overview

Real-time visualization of mouse position and button states. Shows a cursor trail, click ripples, and button state indicators.

## Goals

- ✅ Large, visible cursor
- ✅ Trail effect following mouse movement
- ✅ Click ripple animations
- ✅ Button state indicators (L/R/M)
- ✅ Smooth 60 FPS tracking

## Technical Approach

### Mouse Tracking

```dart
class MouseVisualizerGame extends BaseGame {
  Offset _mousePosition = Offset.zero;
  final List<Offset> _trail = [];
  final List<ClickRipple> _ripples = [];
  bool _leftButtonDown = false;
  bool _rightButtonDown = false;
  
  @override
  void onMouseEvent(InputEvent event) {
    if (event is MouseMoveEvent) {
      _mousePosition = Offset(event.x, event.y);
      _trail.add(_mousePosition);
      if (_trail.length > 30) _trail.removeAt(0);
    } else if (event is MouseButtonEvent) {
      if (event.isDown) {
        _ripples.add(ClickRipple(
          position: Offset(event.x, event.y),
          color: _getButtonColor(event.button),
        ));
      }
      
      if (event.button == MouseButton.left) {
        _leftButtonDown = event.isDown;
      } else if (event.button == MouseButton.right) {
        _rightButtonDown = event.isDown;
      }
    }
  }
}

class ClickRipple {
  final Offset position;
  final Color color;
  final AnimationController controller;
  
  // Expands from center and fades out
}
```

### Visual Effects

- Custom cursor (large, colorful)
- Fading trail (30 points)
- Expanding ripple on click
- Button indicators in corners:
  - Top-left: Left button (red when pressed)
  - Top-right: Right button (blue when pressed)
  - Bottom-center: Middle button (green when pressed)

## Acceptance Criteria

- [ ] Cursor follows mouse in real-time
- [ ] Trail shows last 30 positions with fade
- [ ] Click creates expanding ripple
- [ ] Button indicators update immediately
- [ ] Different colors for different buttons
- [ ] Smooth 60 FPS performance
- [ ] Tests cover mouse state tracking

## Implementation Steps

1. Implement mouse position tracking (2h)
2. Create cursor and trail rendering (2h)
3. Implement click ripple animation (2h)
4. Add button indicators (1h)
5. Testing (1h)

---

**Can start in parallel with PRD-009, 010 after PRD-008!**
