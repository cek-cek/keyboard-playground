/// Platform-agnostic input event types for keyboard and mouse capture.
///
/// This file defines the event model used across all platforms (macOS, Linux, Windows).
library;

/// Type of input event.
enum InputEventType {
  keyDown,
  keyUp,
  mouseMove,
  mouseDown,
  mouseUp,
  mouseScroll,
}

/// Mouse button identifier.
enum MouseButton {
  left,
  right,
  middle,
  other,
}

/// Keyboard modifier keys.
enum KeyModifier {
  shift,
  control,
  alt,
  meta, // Cmd on macOS, Win on Windows
}

/// Base class for all input events.
abstract class InputEvent {
  /// Type of this event.
  InputEventType get type;

  /// When this event occurred.
  DateTime get timestamp;
}

/// Keyboard event (key down or key up).
class KeyEvent extends InputEvent {
  /// Platform-specific key code.
  final int keyCode;

  /// Human-readable key name (e.g., "a", "Enter", "Escape").
  final String key;

  /// Active modifier keys when this event occurred.
  final Set<KeyModifier> modifiers;

  /// True if this is a key down event, false if key up.
  final bool isDown;

  /// When this event occurred.
  @override
  final DateTime timestamp;

  KeyEvent({
    required this.keyCode,
    required this.key,
    required this.modifiers,
    required this.isDown,
    required this.timestamp,
  });

  @override
  InputEventType get type => isDown ? InputEventType.keyDown : InputEventType.keyUp;

  @override
  String toString() {
    final modStr = modifiers.isEmpty ? '' : '${modifiers.map((m) => m.name).join('+')}+';
    return 'KeyEvent(${isDown ? 'down' : 'up'}: $modStr$key, code: $keyCode)';
  }
}

/// Mouse movement event.
class MouseMoveEvent extends InputEvent {
  /// X coordinate of mouse position.
  final double x;

  /// Y coordinate of mouse position.
  final double y;

  /// When this event occurred.
  @override
  final DateTime timestamp;

  MouseMoveEvent({
    required this.x,
    required this.y,
    required this.timestamp,
  });

  @override
  InputEventType get type => InputEventType.mouseMove;

  @override
  String toString() => 'MouseMoveEvent(x: ${x.toStringAsFixed(1)}, y: ${y.toStringAsFixed(1)})';
}

/// Mouse button event (button down or button up).
class MouseButtonEvent extends InputEvent {
  /// Which button was pressed.
  final MouseButton button;

  /// X coordinate where the click occurred.
  final double x;

  /// Y coordinate where the click occurred.
  final double y;

  /// True if this is a button down event, false if button up.
  final bool isDown;

  /// When this event occurred.
  @override
  final DateTime timestamp;

  MouseButtonEvent({
    required this.button,
    required this.x,
    required this.y,
    required this.isDown,
    required this.timestamp,
  });

  @override
  InputEventType get type => isDown ? InputEventType.mouseDown : InputEventType.mouseUp;

  @override
  String toString() {
    return 'MouseButtonEvent(${isDown ? 'down' : 'up'}: ${button.name}, '
        'x: ${x.toStringAsFixed(1)}, y: ${y.toStringAsFixed(1)})';
  }
}

/// Mouse scroll wheel event.
class MouseScrollEvent extends InputEvent {
  /// Horizontal scroll delta.
  final double deltaX;

  /// Vertical scroll delta.
  final double deltaY;

  /// When this event occurred.
  @override
  final DateTime timestamp;

  MouseScrollEvent({
    required this.deltaX,
    required this.deltaY,
    required this.timestamp,
  });

  @override
  InputEventType get type => InputEventType.mouseScroll;

  @override
  String toString() {
    return 'MouseScrollEvent(deltaX: ${deltaX.toStringAsFixed(1)}, deltaY: ${deltaY.toStringAsFixed(1)})';
  }
}
