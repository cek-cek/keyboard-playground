/// Platform channel interface for capturing keyboard and mouse input at the OS level.
///
/// This class provides a high-level Dart API that communicates with platform-specific
/// native code (Swift on macOS, C++ on Linux/Windows) to intercept all input events
/// before they reach other applications.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'input_events.dart';

/// Captures keyboard and mouse input at the OS level.
///
/// This class uses platform channels to communicate with native code that
/// intercepts input events system-wide. On macOS, this requires Accessibility
/// permissions. On Linux, it may require input group membership. On Windows,
/// it may require administrator elevation.
///
/// Example usage:
/// ```dart
/// final capture = InputCapture();
///
/// // Check and request permissions
/// if (!await capture.hasPermissions()) {
///   await capture.requestPermissions();
/// }
///
/// // Start capturing events
/// await capture.startCapture();
///
/// // Listen to events
/// capture.events.listen((event) {
///   if (event is KeyEvent) {
///     print('Key: ${event.key}, Down: ${event.isDown}');
///   } else if (event is MouseMoveEvent) {
///     print('Mouse: ${event.x}, ${event.y}');
///   }
/// });
///
/// // Stop capturing
/// await capture.stopCapture();
/// ```
class InputCapture {
  /// Method channel for controlling the capture (start, stop, permissions).
  static const MethodChannel _methodChannel =
      MethodChannel('com.keyboardplayground/input_capture');

  /// Event channel for receiving input events from native code.
  static const EventChannel _eventChannel =
      EventChannel('com.keyboardplayground/input_events');

  /// Cached event stream.
  Stream<InputEvent>? _eventStream;

  /// Stream of all input events.
  ///
  /// Events will only be emitted when capture is active (after [startCapture]).
  /// The stream is a broadcast stream, so multiple listeners can subscribe.
  Stream<InputEvent> get events {
    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map(parseEvent)
        .cast<InputEvent>();
    return _eventStream!;
  }

  /// Starts capturing input events.
  ///
  /// Returns `true` if capture started successfully, `false` otherwise.
  /// Capture may fail if permissions are not granted or if the platform
  /// does not support input capture.
  ///
  /// This method is idempotent - calling it multiple times has no effect
  /// if capture is already active.
  Future<bool> startCapture() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('startCapture');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to start capture: ${e.message}');
      return false;
    }
  }

  /// Stops capturing input events.
  ///
  /// Returns `true` if capture stopped successfully, `false` otherwise.
  ///
  /// This method is idempotent - calling it multiple times has no effect
  /// if capture is not active.
  Future<bool> stopCapture() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('stopCapture');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to stop capture: ${e.message}');
      return false;
    }
  }

  /// Checks if currently capturing input events.
  Future<bool> isCapturing() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isCapturing');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to check capture status: ${e.message}');
      return false;
    }
  }

  /// Checks if the app has the necessary permissions to capture input.
  ///
  /// Returns a map of permission names to their status. The keys depend
  /// on the platform:
  /// - macOS: `{'accessibility': true/false}`
  /// - Linux: `{'input_group': true/false}`
  /// - Windows: `{'admin': true/false}` (may not be required)
  Future<Map<String, bool>> checkPermissions() async {
    try {
      final result = await _methodChannel.invokeMapMethod<String, bool>(
        'checkPermissions',
      );
      return result ?? {};
    } on PlatformException catch (e) {
      print('Failed to check permissions: ${e.message}');
      return {};
    }
  }

  /// Checks if all necessary permissions are granted.
  Future<bool> hasPermissions() async {
    final perms = await checkPermissions();
    return perms.isNotEmpty && perms.values.every((granted) => granted);
  }

  /// Requests necessary permissions from the user.
  ///
  /// On macOS, this will show the system Accessibility permissions dialog.
  /// On Linux, this may print instructions for adding the user to the input group.
  /// On Windows, this may request administrator elevation.
  ///
  /// Returns `true` if permissions were granted, `false` otherwise.
  Future<bool> requestPermissions() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'requestPermissions',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to request permissions: ${e.message}');
      return false;
    }
  }

  /// Parses a raw event map from the event channel into a typed [InputEvent].
  @visibleForTesting
  InputEvent parseEvent(dynamic data) {
    final map = data as Map;
    final type = map['type'] as String;
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      map['timestamp'] as int,
    );

    switch (type) {
      case 'keyDown':
      case 'keyUp':
        return KeyEvent(
          keyCode: map['keyCode'] as int,
          key: map['key'] as String,
          modifiers: (map['modifiers'] as List)
              .map(parseModifier)
              .toSet(),
          isDown: type == 'keyDown',
          timestamp: timestamp,
        );

      case 'mouseMove':
        return MouseMoveEvent(
          x: (map['x'] as num).toDouble(),
          y: (map['y'] as num).toDouble(),
          timestamp: timestamp,
        );

      case 'mouseDown':
      case 'mouseUp':
        return MouseButtonEvent(
          button: parseButton(map['button'] as String),
          x: (map['x'] as num).toDouble(),
          y: (map['y'] as num).toDouble(),
          isDown: type == 'mouseDown',
          timestamp: timestamp,
        );

      case 'mouseScroll':
        return MouseScrollEvent(
          deltaX: (map['deltaX'] as num).toDouble(),
          deltaY: (map['deltaY'] as num).toDouble(),
          timestamp: timestamp,
        );

      default:
        throw UnimplementedError('Unknown event type: $type');
    }
  }

  /// Parses a modifier string into a [KeyModifier] enum.
  @visibleForTesting
  KeyModifier parseModifier(dynamic mod) {
    switch (mod as String) {
      case 'shift':
        return KeyModifier.shift;
      case 'control':
        return KeyModifier.control;
      case 'alt':
        return KeyModifier.alt;
      case 'meta':
        return KeyModifier.meta;
      default:
        throw ArgumentError('Unknown modifier: $mod');
    }
  }

  /// Parses a button string into a [MouseButton] enum.
  @visibleForTesting
  MouseButton parseButton(String button) {
    switch (button) {
      case 'left':
        return MouseButton.left;
      case 'right':
        return MouseButton.right;
      case 'middle':
        return MouseButton.middle;
      default:
        return MouseButton.other;
    }
  }
}
