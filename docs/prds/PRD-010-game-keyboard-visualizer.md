# PRD-010: Game 2a - Keyboard Visualizer

**Status**: ⚪ Not Started  
**Dependencies**: PRD-008 (Integration & Base App)  
**Estimated Effort**: 10 hours  
**Priority**: P1  
**Branch**: `feature/prd-010-game-keyboard-visualizer`

## Overview

Real-time visualization of keyboard state showing which keys are currently pressed. Displays a graphical keyboard layout that lights up as keys are pressed.

## Goals

- ✅ Visual keyboard layout matching physical keyboard
- ✅ Keys highlight when pressed
- ✅ Different colors for different key types
- ✅ Supports modifier keys (Shift, Ctrl, Alt, Meta)
- ✅ Responsive to rapid key presses

## Technical Approach

### Keyboard Layout

```dart
class KeyboardVisualizerGame extends BaseGame {
  final Map<String, bool> _keyStates = {};
  
  @override
  Widget buildUI() {
    return KeyboardLayoutWidget(
      keyStates: _keyStates,
    );
  }
  
  @override
  void onKeyEvent(KeyEvent event) {
    _keyStates[event.key] = event.isDown;
    notifyListeners();
  }
}

// Keyboard layout with rows of keys
class KeyboardLayoutWidget extends StatelessWidget {
  static const keyRows = [
    ['Esc', 'F1', 'F2', ...],  // Function row
    ['`', '1', '2', ..., 'Backspace'],  // Number row
    ['Tab', 'Q', 'W', ..., '\\'],  // QWERTY row
    ['Caps', 'A', 'S', ..., 'Enter'],  // Home row
    ['Shift', 'Z', 'X', ..., 'Shift'],  // Bottom row
    ['Ctrl', 'Alt', 'Cmd', 'Space', ...]  // Modifier row
  ];
}
```

### Visual Design

- Large, clear keys (60x60px minimum)
- High contrast colors
- Different colors for:
  - Letters: Blue
  - Numbers: Green
  - Modifiers: Orange
  - Special keys: Purple
- Glow effect when pressed

## Acceptance Criteria

- [ ] Keyboard layout displays all common keys
- [ ] Keys light up instantly on press (<16ms)
- [ ] Keys dim on release
- [ ] Modifier keys show as active
- [ ] Layout scales to screen size
- [ ] Handles rapid key presses (>10/sec)
- [ ] Tests cover key state management

## Implementation Steps

1. Design keyboard layout data structure (2h)
2. Create keyboard widget with rows (3h)
3. Implement key highlighting (2h)
4. Add color coding (1h)
5. Performance testing (1h)
6. Tests (1h)

---

**Can start in parallel with PRD-009 after PRD-008!**
