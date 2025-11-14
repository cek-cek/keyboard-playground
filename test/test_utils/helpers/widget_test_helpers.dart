/// Helper utilities for widget testing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyboard_playground/ui/app_theme.dart';

/// Helper for pumping a widget with the app theme.
///
/// Wraps the widget in a MaterialApp with the kid-friendly theme.
///
/// Example usage:
/// ```dart
/// testWidgets('MyWidget displays correctly', (tester) async {
///   await pumpThemedWidget(tester, MyWidget());
///   expect(find.byType(MyWidget), findsOneWidget);
/// });
/// ```
Future<void> pumpThemedWidget(
  WidgetTester tester,
  Widget widget,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.kidFriendlyTheme,
      home: Scaffold(body: widget),
    ),
  );
}

/// Helper to find by test key.
///
/// Convenience wrapper around find.byKey(Key(key)).
Finder findByTestKey(String key) {
  return find.byKey(Key(key));
}

/// Helper to wait for animations to complete.
///
/// Uses pumpAndSettle with a reasonable timeout.
Future<void> waitForAnimations(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

/// Helper to pump frames for a specific duration.
///
/// Useful for testing time-based animations.
Future<void> pumpForDuration(
  WidgetTester tester,
  Duration duration, {
  Duration frameInterval = const Duration(milliseconds: 16),
}) async {
  final frames = duration.inMilliseconds ~/ frameInterval.inMilliseconds;
  for (var i = 0; i < frames; i++) {
    await tester.pump(frameInterval);
  }
}

/// Helper to tap and settle.
///
/// Combines tap and pumpAndSettle in one call.
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Helper to enter text and settle.
///
/// Combines enterText and pumpAndSettle in one call.
Future<void> enterTextAndSettle(
  WidgetTester tester,
  Finder finder,
  String text,
) async {
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

/// Helper to check if a widget has a specific text color.
bool hasTextColor(Finder finder, Color expectedColor) {
  final elements = finder.evaluate();
  if (elements.isEmpty) {
    return false;
  }
  final widget = elements.first.widget;
  if (widget is Text) {
    return widget.style?.color == expectedColor;
  }
  return false;
}

/// Helper to get the text from a Text widget.
String? getTextFromFinder(Finder finder) {
  final elements = finder.evaluate();
  if (elements.isEmpty) {
    return null;
  }
  final widget = elements.first.widget;
  if (widget is Text) {
    return widget.data ?? widget.textSpan?.toPlainText();
  }
  return null;
}

/// Helper to check if a widget is visible.
///
/// Returns false if hidden by Opacity or Visibility.
bool isVisible(Finder finder) {
  final elements = finder.evaluate();
  if (elements.isEmpty) {
    return false;
  }
  final element = elements.first;
  final widget = element.widget;

  if (widget is Opacity) {
    return widget.opacity > 0;
  }
  if (widget is Visibility) {
    return widget.visible;
  }

  return true;
}
