/// Builder utilities for creating test input events.
library;

import 'package:keyboard_playground/platform/input_events.dart';

/// Builder class for creating test input events.
///
/// Provides convenient methods for creating various types of input events
/// for testing purposes.
///
/// Example usage:
/// ```dart
/// // Create a key press
/// final keyEvent = EventBuilder.keyDown('a');
///
/// // Create a mouse click
/// final clickEvent = EventBuilder.mouseClick(100, 200);
///
/// // Create events with modifiers
/// final shiftA = EventBuilder.keyDown(
///   'A',
///   modifiers: {KeyModifier.shift},
/// );
/// ```
class EventBuilder {
  /// Creates a key down event.
  static KeyEvent keyDown(
    String key, {
    int? keyCode,
    Set<KeyModifier> modifiers = const {},
    DateTime? timestamp,
  }) {
    return KeyEvent(
      keyCode: keyCode ?? key.codeUnitAt(0),
      key: key,
      modifiers: modifiers,
      isDown: true,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Creates a key up event.
  static KeyEvent keyUp(
    String key, {
    int? keyCode,
    Set<KeyModifier> modifiers = const {},
    DateTime? timestamp,
  }) {
    return KeyEvent(
      keyCode: keyCode ?? key.codeUnitAt(0),
      key: key,
      modifiers: modifiers,
      isDown: false,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Creates a mouse move event.
  static MouseMoveEvent mouseMove(
    double x,
    double y, {
    DateTime? timestamp,
  }) {
    return MouseMoveEvent(
      x: x,
      y: y,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Creates a mouse click event (button down).
  static MouseButtonEvent mouseClick(
    double x,
    double y, {
    MouseButton button = MouseButton.left,
    bool isDown = true,
    DateTime? timestamp,
  }) {
    return MouseButtonEvent(
      button: button,
      x: x,
      y: y,
      isDown: isDown,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Creates a mouse button down event.
  static MouseButtonEvent mouseDown(
    double x,
    double y, {
    MouseButton button = MouseButton.left,
    DateTime? timestamp,
  }) {
    return MouseButtonEvent(
      button: button,
      x: x,
      y: y,
      isDown: true,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Creates a mouse button up event.
  static MouseButtonEvent mouseUp(
    double x,
    double y, {
    MouseButton button = MouseButton.left,
    DateTime? timestamp,
  }) {
    return MouseButtonEvent(
      button: button,
      x: x,
      y: y,
      isDown: false,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Creates a mouse scroll event.
  static MouseScrollEvent mouseScroll({
    double deltaX = 0,
    double deltaY = 0,
    DateTime? timestamp,
  }) {
    return MouseScrollEvent(
      deltaX: deltaX,
      deltaY: deltaY,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Creates a complete key press sequence (down then up).
  static List<KeyEvent> keyPress(
    String key, {
    int? keyCode,
    Set<KeyModifier> modifiers = const {},
    Duration? delay,
  }) {
    final now = DateTime.now();
    final downEvent = keyDown(
      key,
      keyCode: keyCode,
      modifiers: modifiers,
      timestamp: now,
    );
    final upEvent = keyUp(
      key,
      keyCode: keyCode,
      modifiers: modifiers,
      timestamp: delay != null ? now.add(delay) : now,
    );
    return [downEvent, upEvent];
  }

  /// Creates a complete mouse click sequence (down then up).
  static List<MouseButtonEvent> mouseClickSequence(
    double x,
    double y, {
    MouseButton button = MouseButton.left,
    Duration? delay,
  }) {
    final now = DateTime.now();
    final downEvent = mouseDown(x, y, button: button, timestamp: now);
    final upEvent = mouseUp(
      x,
      y,
      button: button,
      timestamp: delay != null ? now.add(delay) : now,
    );
    return [downEvent, upEvent];
  }
}
