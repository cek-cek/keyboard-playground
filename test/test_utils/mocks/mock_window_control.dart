/// Mock implementation of WindowControl for testing.
library;

// ignore: unnecessary_import
import 'dart:ui' show Size;

/// Mock implementation of window control for testing.
///
/// Simulates window management operations without requiring actual platform
/// code.
///
/// Example usage:
/// ```dart
/// final mockWindow = MockWindowControl();
///
/// // Configure screen size
/// mockWindow.screenSize = const Size(1920, 1080);
///
/// // Test fullscreen operations
/// await mockWindow.enterFullscreen();
/// expect(mockWindow.isFullscreen, true);
/// ```
class MockWindowControl {
  bool _isFullscreen = false;

  /// The current screen size. Can be modified for testing.
  Size screenSize = const Size(1920, 1080);

  /// Enters fullscreen mode (mock implementation).
  ///
  /// Always returns `true` in the mock.
  Future<bool> enterFullscreen() async {
    _isFullscreen = true;
    return true;
  }

  /// Exits fullscreen mode (mock implementation).
  ///
  /// Always returns `true` in the mock.
  Future<bool> exitFullscreen() async {
    _isFullscreen = false;
    return true;
  }

  /// Checks if the window is currently in fullscreen mode.
  bool get isFullscreen => _isFullscreen;

  /// Gets the screen size.
  ///
  /// Returns the current screenSize value.
  Future<Size> getScreenSize() async {
    return screenSize;
  }
}
