# PRD-010: Game 2a - Keyboard Visualizer

**Status**: ⚪ Not Started
**Dependencies**: PRD-008 (Integration & Base App)
**Estimated Effort**: 14 hours
**Priority**: P1
**Branch**: `feature/prd-010-game-keyboard-visualizer`

## Overview

Real-time visualization of keyboard state showing which keys are currently pressed. Displays a graphical keyboard layout that lights up as keys are pressed.

## Goals

- ✅ Visual keyboard layout matching physical keyboard
- ✅ Keys highlight when pressed
- ✅ Different colors for different key types
- ✅ Supports modifier keys (Shift, Ctrl, Alt, Meta)
- ✅ Mouse buttons visualization (left, right, middle)
- ✅ Responsive to rapid key presses
- ✅ Layout scales without overflow (responsive design)
- ✅ Works on all screen sizes (minimum 1024x768)

## Technical Approach

### Keyboard Layout

```dart
class KeyboardVisualizerGame extends BaseGame {
  final Map<String, bool> _keyStates = {};
  final Map<MouseButton, bool> _mouseButtonStates = {
    MouseButton.left: false,
    MouseButton.right: false,
    MouseButton.middle: false,
  };

  @override
  Widget buildUI() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return KeyboardLayoutWidget(
          keyStates: _keyStates,
          mouseButtonStates: _mouseButtonStates,
          availableWidth: constraints.maxWidth,
          availableHeight: constraints.maxHeight,
        );
      },
    );
  }

  @override
  void onKeyEvent(KeyEvent event) {
    _keyStates[event.key] = event.isDown;
    notifyListeners();
  }

  @override
  void onMouseEvent(InputEvent event) {
    if (event is MouseButtonEvent) {
      _mouseButtonStates[event.button] = event.isDown;
      notifyListeners();
    }
  }
}

// Keyboard layout with rows of keys
class KeyboardLayoutWidget extends StatelessWidget {
  final Map<String, bool> keyStates;
  final Map<MouseButton, bool> mouseButtonStates;
  final double availableWidth;
  final double availableHeight;

  static const keyRows = [
    ['Esc', 'F1', 'F2', ...],  // Function row
    ['`', '1', '2', ..., 'Backspace'],  // Number row
    ['Tab', 'Q', 'W', ..., '\\'],  // QWERTY row
    ['Caps', 'A', 'S', ..., 'Enter'],  // Home row
    ['Shift', 'Z', 'X', ..., 'Shift'],  // Bottom row
    ['Ctrl', 'Alt', 'Cmd', 'Space', ...]  // Modifier row
  ];

  @override
  Widget build(BuildContext context) {
    // Calculate key size based on available space to prevent overflow
    final keySize = _calculateKeySize(availableWidth, availableHeight);

    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Keyboard rows
            ...keyRows.map((row) => KeyboardRow(
              keys: row,
              keyStates: keyStates,
              keySize: keySize,
            )),

            SizedBox(height: keySize * 0.5),

            // Mouse buttons row
            MouseButtonsRow(
              buttonStates: mouseButtonStates,
              buttonSize: keySize * 2,
            ),
          ],
        ),
      ),
    );
  }

  double _calculateKeySize(double width, double height) {
    // Calculate based on screen size to prevent overflow
    // Assuming max row has ~15 keys
    final maxKeyWidth = width / 17; // Extra space for margins
    final maxKeyHeight = height / 10; // 6 keyboard rows + mouse buttons
    return min(maxKeyWidth, maxKeyHeight).clamp(40.0, 80.0);
  }
}

// Mouse buttons visualization
class MouseButtonsRow extends StatelessWidget {
  final Map<MouseButton, bool> buttonStates;
  final double buttonSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildMouseButton('L', MouseButton.left, Colors.red),
        SizedBox(width: buttonSize * 0.3),
        _buildMouseButton('M', MouseButton.middle, Colors.yellow),
        SizedBox(width: buttonSize * 0.3),
        _buildMouseButton('R', MouseButton.right, Colors.blue),
      ],
    );
  }

  Widget _buildMouseButton(String label, MouseButton button, Color color) {
    final isPressed = buttonStates[button] ?? false;

    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: isPressed ? color : color.withOpacity(0.3),
        border: Border.all(
          color: color,
          width: isPressed ? 4 : 2,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isPressed
          ? [
              BoxShadow(
                color: color.withOpacity(0.6),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ]
          : [],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: buttonSize * 0.4,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
```

### Visual Design

**Keyboard Keys:**
- Responsive size (40-80px based on screen size)
- High contrast colors
- Different colors for:
  - Letters: Blue
  - Numbers: Green
  - Modifiers: Orange
  - Special keys: Purple
- Glow effect when pressed

**Mouse Buttons:**
- Large, circular buttons (2x key size)
- Positioned below keyboard
- Color-coded:
  - Left: Red
  - Middle: Yellow
  - Right: Blue
- Strong glow effect when pressed

**Layout:**
- Uses LayoutBuilder for responsive sizing
- SingleChildScrollView prevents overflow
- Automatic key size calculation based on screen dimensions
- Centered layout with proper spacing

## Acceptance Criteria

- [ ] Keyboard layout displays all common keys
- [ ] Keys light up instantly on press (<16ms)
- [ ] Keys dim on release
- [ ] Modifier keys show as active
- [ ] Mouse buttons (L/M/R) displayed below keyboard
- [ ] Mouse buttons light up on press with glow effect
- [ ] Layout scales to screen size without overflow
- [ ] Works on minimum screen size (1024x768)
- [ ] Works on large screens without excessive spacing
- [ ] Automatic key size calculation prevents overflow
- [ ] SingleChildScrollView enables scrolling if needed
- [ ] Handles rapid key presses (>10/sec)
- [ ] Handles rapid mouse clicks
- [ ] Tests cover key state management
- [ ] Tests cover mouse button state management
- [ ] Tests cover responsive layout behavior

## Implementation Steps

1. Design keyboard layout data structure (2h)
2. Create responsive keyboard widget with LayoutBuilder (3h)
3. Implement key highlighting (2h)
4. Add color coding (1h)
5. Add mouse buttons visualization (2h)
6. Implement responsive layout calculations (1h)
7. Performance testing (1h)
8. Tests (including layout overflow tests) (2h)

---

**Can start in parallel with PRD-009 after PRD-008!**
