/// Custom matchers for testing input events and other app-specific types.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyboard_playground/platform/input_events.dart';

/// Matcher for KeyEvent.
///
/// Example usage:
/// ```dart
/// expect(event, isKeyEvent(key: 'a', isDown: true));
/// expect(event, isKeyEvent(modifiers: {KeyModifier.shift}));
/// ```
Matcher isKeyEvent({
  String? key,
  bool? isDown,
  Set<KeyModifier>? modifiers,
}) {
  return _KeyEventMatcher(key: key, isDown: isDown, modifiers: modifiers);
}

class _KeyEventMatcher extends Matcher {
  _KeyEventMatcher({this.key, this.isDown, this.modifiers});

  final String? key;
  final bool? isDown;
  final Set<KeyModifier>? modifiers;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! KeyEvent) return false;

    if (key != null && item.key != key) return false;
    if (isDown != null && item.isDown != isDown) return false;
    if (modifiers != null && !setEquals(item.modifiers, modifiers)) {
      return false;
    }

    return true;
  }

  @override
  Description describe(Description description) {
    final parts = <String>[];
    if (key != null) parts.add('key: $key');
    if (isDown != null) parts.add('isDown: $isDown');
    if (modifiers != null) parts.add('modifiers: $modifiers');

    return description.add('KeyEvent(${parts.join(', ')})');
  }
}

/// Matcher for MouseButtonEvent.
///
/// Example usage:
/// ```dart
/// expect(event, isMouseButtonEvent(button: MouseButton.left, isDown: true));
/// expect(event, isMouseButtonEvent(x: 100, y: 200));
/// ```
Matcher isMouseButtonEvent({
  MouseButton? button,
  double? x,
  double? y,
  bool? isDown,
}) {
  return _MouseButtonEventMatcher(
    button: button,
    x: x,
    y: y,
    isDown: isDown,
  );
}

class _MouseButtonEventMatcher extends Matcher {
  _MouseButtonEventMatcher({
    this.button,
    this.x,
    this.y,
    this.isDown,
  });

  final MouseButton? button;
  final double? x;
  final double? y;
  final bool? isDown;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! MouseButtonEvent) return false;

    if (button != null && item.button != button) return false;
    final xValue = x;
    if (xValue != null && (item.x - xValue).abs() > 0.01) return false;
    final yValue = y;
    if (yValue != null && (item.y - yValue).abs() > 0.01) return false;
    if (isDown != null && item.isDown != isDown) return false;

    return true;
  }

  @override
  Description describe(Description description) {
    final parts = <String>[];
    if (button != null) parts.add('button: $button');
    if (x != null) parts.add('x: $x');
    if (y != null) parts.add('y: $y');
    if (isDown != null) parts.add('isDown: $isDown');

    return description.add('MouseButtonEvent(${parts.join(', ')})');
  }
}

/// Matcher for MouseMoveEvent.
///
/// Example usage:
/// ```dart
/// expect(event, isMouseMoveEvent(x: 100, y: 200));
/// ```
Matcher isMouseMoveEvent({
  double? x,
  double? y,
}) {
  return _MouseMoveEventMatcher(x: x, y: y);
}

class _MouseMoveEventMatcher extends Matcher {
  _MouseMoveEventMatcher({this.x, this.y});

  final double? x;
  final double? y;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! MouseMoveEvent) return false;

    final xValue = x;
    if (xValue != null && (item.x - xValue).abs() > 0.01) return false;
    final yValue = y;
    if (yValue != null && (item.y - yValue).abs() > 0.01) return false;

    return true;
  }

  @override
  Description describe(Description description) {
    final parts = <String>[];
    if (x != null) parts.add('x: $x');
    if (y != null) parts.add('y: $y');

    return description.add('MouseMoveEvent(${parts.join(', ')})');
  }
}

/// Matcher for MouseScrollEvent.
///
/// Example usage:
/// ```dart
/// expect(event, isMouseScrollEvent(deltaY: -120));
/// ```
Matcher isMouseScrollEvent({
  double? deltaX,
  double? deltaY,
}) {
  return _MouseScrollEventMatcher(deltaX: deltaX, deltaY: deltaY);
}

class _MouseScrollEventMatcher extends Matcher {
  _MouseScrollEventMatcher({this.deltaX, this.deltaY});

  final double? deltaX;
  final double? deltaY;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! MouseScrollEvent) return false;

    final deltaXValue = deltaX;
    if (deltaXValue != null && (item.deltaX - deltaXValue).abs() > 0.01) {
      return false;
    }
    final deltaYValue = deltaY;
    if (deltaYValue != null && (item.deltaY - deltaYValue).abs() > 0.01) {
      return false;
    }

    return true;
  }

  @override
  Description describe(Description description) {
    final parts = <String>[];
    if (deltaX != null) parts.add('deltaX: $deltaX');
    if (deltaY != null) parts.add('deltaY: $deltaY');

    return description.add('MouseScrollEvent(${parts.join(', ')})');
  }
}

/// Matcher to check if a stream emits a specific event type.
///
/// Example usage:
/// ```dart
/// expect(
///   eventStream,
///   emitsInOrder([
///     isKeyEvent(key: 'a'),
///     isKeyEvent(key: 'b'),
///   ]),
/// );
/// ```
Matcher emitsKeyEvent({
  String? key,
  bool? isDown,
}) {
  return emits(isKeyEvent(key: key, isDown: isDown));
}
