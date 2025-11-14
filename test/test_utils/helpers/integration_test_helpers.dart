/// Helper utilities for integration testing.
library;

import 'package:flutter_test/flutter_test.dart';

/// Helper for integration tests.
///
/// Provides utilities for end-to-end integration testing.
class IntegrationTestHelpers {
  /// Waits for a condition to become true.
  ///
  /// Polls the condition every [pollInterval] until it returns true
  /// or [timeout] is reached.
  ///
  /// Example usage:
  /// ```dart
  /// await waitFor(
  ///   () => myValue == expectedValue,
  ///   timeout: Duration(seconds: 5),
  /// );
  /// ```
  static Future<void> waitFor(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 10),
    Duration pollInterval = const Duration(milliseconds: 100),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      if (condition()) {
        return;
      }
      await Future<void>.delayed(pollInterval);
    }

    throw TimeoutException(
      'Condition not met within $timeout',
      timeout,
    );
  }

  /// Waits for a widget to appear.
  static Future<void> waitForWidget(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await waitFor(
      () => finder.evaluate().isNotEmpty,
      timeout: timeout,
    );
    await tester.pumpAndSettle();
  }

  /// Waits for a widget to disappear.
  static Future<void> waitForWidgetToDisappear(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await waitFor(
      () => finder.evaluate().isEmpty,
      timeout: timeout,
    );
    await tester.pumpAndSettle();
  }

  /// Measures the execution time of an async function.
  ///
  /// Returns the duration it took to execute.
  static Future<Duration> measureTime(Future<void> Function() fn) async {
    final start = DateTime.now();
    await fn();
    return DateTime.now().difference(start);
  }

  /// Measures frame rate over a duration.
  ///
  /// Returns the average frames per second.
  static Future<double> measureFrameRate(
    WidgetTester tester,
    Duration duration,
  ) async {
    var frameCount = 0;
    final start = DateTime.now();

    while (DateTime.now().difference(start) < duration) {
      await tester.pump(const Duration(milliseconds: 16));
      frameCount++;
    }

    final actualDuration = DateTime.now().difference(start);
    return frameCount / actualDuration.inSeconds;
  }
}

/// Exception thrown when a timeout occurs.
class TimeoutException implements Exception {
  /// Creates a timeout exception.
  TimeoutException(this.message, this.timeout);

  /// The error message.
  final String message;

  /// The timeout duration that was exceeded.
  final Duration timeout;

  @override
  String toString() => 'TimeoutException: $message';
}
