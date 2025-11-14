/// Platform-specific window management for fullscreen mode.
///
/// Provides methods to control the application window including entering/exiting
/// fullscreen mode and getting screen dimensions.
library;

// ignore: unnecessary_import
import 'dart:ui' show Size;

import 'package:flutter/services.dart';

/// Controls the application window across different platforms.
///
/// Uses platform channels to communicate with native code for window management
/// operations like fullscreen toggling and screen size detection.
///
/// Example usage:
/// ```dart
/// // Enter fullscreen mode
/// final success = await WindowControl.enterFullscreen();
/// if (success) {
///   print('Fullscreen mode activated');
/// }
///
/// // Get screen dimensions
/// final size = await WindowControl.getScreenSize();
/// print('Screen: ${size.width}x${size.height}');
/// ```
class WindowControl {
  /// Method channel for window control operations.
  static const _methodChannel = MethodChannel(
    'com.keyboardplayground/window_control',
  );

  /// Enters fullscreen mode.
  ///
  /// Returns `true` if fullscreen was successfully enabled, `false` otherwise.
  /// On platforms that don't support fullscreen, this returns `false`.
  ///
  /// Platform behavior:
  /// - **macOS**: Uses `NSWindow.toggleFullScreen()`
  /// - **Linux**: Uses X11 fullscreen protocol
  /// - **Windows**: Uses Win32 fullscreen mode
  static Future<bool> enterFullscreen() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('enterFullscreen');
      return result ?? false;
    } on PlatformException {
      // Platform channel not implemented or error occurred
      // This is expected if running without platform-specific code
      return false;
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return false;
    }
  }

  /// Exits fullscreen mode.
  ///
  /// Returns `true` if fullscreen was successfully exited, `false` otherwise.
  /// On platforms that don't support fullscreen, this returns `false`.
  ///
  /// Platform behavior:
  /// - **macOS**: Uses `NSWindow.toggleFullScreen()`
  /// - **Linux**: Uses X11 fullscreen protocol
  /// - **Windows**: Uses Win32 windowed mode
  static Future<bool> exitFullscreen() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('exitFullscreen');
      return result ?? false;
    } on PlatformException {
      // Platform channel not implemented or error occurred
      return false;
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return false;
    }
  }

  /// Gets the screen size in pixels.
  ///
  /// Returns the dimensions of the primary screen. On multi-monitor setups,
  /// this returns the size of the main display.
  ///
  /// Returns a default size of 1920x1080 if the platform doesn't support
  /// screen size detection or if an error occurs.
  ///
  /// Platform behavior:
  /// - **macOS**: Uses `NSScreen.mainScreen.frame`
  /// - **Linux**: Uses X11 screen dimensions
  /// - **Windows**: Uses `GetSystemMetrics()`
  static Future<Size> getScreenSize() async {
    try {
      final result = await _methodChannel.invokeMapMethod<String, double>(
        'getScreenSize',
      );
      if (result != null &&
          result['width'] != null &&
          result['height'] != null) {
        return Size(
          result['width']!,
          result['height']!,
        );
      }
      return const Size(1920, 1080);
    } on PlatformException {
      // Platform channel not implemented or error occurred
      return const Size(1920, 1080);
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return const Size(1920, 1080);
    }
  }

  /// Gets whether the window is currently in fullscreen mode.
  ///
  /// Returns `true` if the window is in fullscreen, `false` otherwise.
  /// Returns `false` if the platform doesn't support fullscreen detection.
  static Future<bool> isFullscreen() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isFullscreen');
      return result ?? false;
    } on PlatformException {
      return false;
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return false;
    }
  }
}
