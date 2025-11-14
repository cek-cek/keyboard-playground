/// Mock implementation of InputCapture for testing.
library;

import 'dart:async';

import 'package:keyboard_playground/platform/input_capture.dart';
import 'package:keyboard_playground/platform/input_events.dart';

/// Mock implementation of [InputCapture] for testing.
///
/// Allows tests to simulate input events without requiring actual
/// platform-specific input capture.
///
/// Example usage:
/// ```dart
/// final mockInput = MockInputCapture();
///
/// // Emit a key event
/// mockInput.emitEvent(KeyEvent(
///   keyCode: 65,
///   key: 'a',
///   modifiers: {},
///   isDown: true,
///   timestamp: DateTime.now(),
/// ));
///
/// // Or emit multiple events
/// mockInput.emitEvents([event1, event2, event3]);
/// ```
class MockInputCapture extends InputCapture {
  final StreamController<InputEvent> _eventController =
      StreamController<InputEvent>.broadcast();

  bool _isCapturing = false;

  @override
  Stream<InputEvent> get events => _eventController.stream;

  /// Starts capturing input events (mock implementation).
  ///
  /// Always returns `true` in the mock.
  @override
  Future<bool> startCapture() async {
    _isCapturing = true;
    return true;
  }

  /// Stops capturing input events (mock implementation).
  ///
  /// Always returns `true` in the mock.
  @override
  Future<bool> stopCapture() async {
    _isCapturing = false;
    return true;
  }

  /// Checks if input capture is currently active.
  @override
  Future<bool> isCapturing() async {
    return _isCapturing;
  }

  /// Emits a single test event.
  ///
  /// Use this to simulate input events in your tests.
  void emitEvent(InputEvent event) {
    _eventController.add(event);
  }

  /// Emits a sequence of events.
  ///
  /// Useful for testing sequences of input events.
  void emitEvents(List<InputEvent> events) {
    for (final event in events) {
      _eventController.add(event);
    }
  }

  /// Disposes of the mock and closes the event stream.
  Future<void> dispose() async {
    await _eventController.close();
  }
}
