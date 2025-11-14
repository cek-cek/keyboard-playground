/// Pre-built event sequences for common testing scenarios.
library;

import 'dart:math';

import 'package:keyboard_playground/platform/input_events.dart';

import '../test_utils/builders/event_builder.dart';

/// Common event sequences for testing.
///
/// Provides pre-built sequences of input events for common testing scenarios.
///
/// Example usage:
/// ```dart
/// // Use a pre-built typing sequence
/// mockInput.emitEvents(EventFixtures.typingHello);
///
/// // Use the exit sequence
/// mockInput.emitEvents(EventFixtures.exitSequence);
/// ```
class EventFixtures {
  /// Typical typing sequence: "HELLO"
  static List<InputEvent> get typingHello {
    return [
      EventBuilder.keyDown('H'),
      EventBuilder.keyUp('H'),
      EventBuilder.keyDown('E'),
      EventBuilder.keyUp('E'),
      EventBuilder.keyDown('L'),
      EventBuilder.keyUp('L'),
      EventBuilder.keyDown('L'),
      EventBuilder.keyUp('L'),
      EventBuilder.keyDown('O'),
      EventBuilder.keyUp('O'),
    ];
  }

  /// Exit sequence (from PRD-005): Alt, Control, ArrowRight, Escape, q
  static List<InputEvent> get exitSequence {
    return [
      EventBuilder.keyDown('Alt'),
      EventBuilder.keyUp('Alt'),
      EventBuilder.keyDown('Control'),
      EventBuilder.keyUp('Control'),
      EventBuilder.keyDown('ArrowRight'),
      EventBuilder.keyUp('ArrowRight'),
      EventBuilder.keyDown('Escape'),
      EventBuilder.keyUp('Escape'),
      EventBuilder.keyDown('q'),
      EventBuilder.keyUp('q'),
    ];
  }

  /// Just the key down events for the exit sequence.
  static List<InputEvent> get exitSequenceKeysOnly {
    return [
      EventBuilder.keyDown('Alt'),
      EventBuilder.keyDown('Control'),
      EventBuilder.keyDown('ArrowRight'),
      EventBuilder.keyDown('Escape'),
      EventBuilder.keyDown('q'),
    ];
  }

  /// Mouse clicks in four corners: TL, TR, BR, BL
  static List<InputEvent> cornerClicks({
    double width = 1920,
    double height = 1080,
    double margin = 10,
  }) {
    return [
      EventBuilder.mouseClick(margin, margin), // Top-left
      EventBuilder.mouseClick(width - margin, margin), // Top-right
      EventBuilder.mouseClick(width - margin, height - margin), // Bottom-right
      EventBuilder.mouseClick(margin, height - margin), // Bottom-left
    ];
  }

  /// Mouse movement in a circle.
  ///
  /// Generates [steps] number of mouse move events in a circular pattern.
  static List<InputEvent> circleMouseMovement(
    double centerX,
    double centerY,
    double radius,
    int steps,
  ) {
    return List.generate(steps, (i) {
      final angle = (i / steps) * 2 * pi;
      return EventBuilder.mouseMove(
        centerX + radius * cos(angle),
        centerY + radius * sin(angle),
      );
    });
  }

  /// Mouse movement in a line from start to end.
  static List<InputEvent> lineMouseMovement(
    double startX,
    double startY,
    double endX,
    double endY,
    int steps,
  ) {
    if (steps < 2) {
      // Return single point for steps < 2
      return [EventBuilder.mouseMove(startX, startY)];
    }
    return List.generate(steps, (i) {
      final t = i / (steps - 1);
      return EventBuilder.mouseMove(
        startX + (endX - startX) * t,
        startY + (endY - startY) * t,
      );
    });
  }

  /// Rapid keyboard typing (alternating key down/up).
  static List<InputEvent> rapidTyping(
    String text, {
    Duration delayBetweenKeys = const Duration(milliseconds: 50),
  }) {
    final events = <InputEvent>[];
    final baseTime = DateTime.now();

    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      final timestamp = baseTime.add(delayBetweenKeys * i);

      events
        ..add(
          EventBuilder.keyDown(char, timestamp: timestamp),
        )
        ..add(
          EventBuilder.keyUp(
            char,
            timestamp: timestamp.add(const Duration(milliseconds: 10)),
          ),
        );
    }

    return events;
  }

  /// Key combination (e.g., Ctrl+C, Alt+F4).
  static List<InputEvent> keyCombo(
    List<String> keys, {
    Set<KeyModifier> modifiers = const {},
  }) {
    final events = <InputEvent>[];

    // Press all keys down
    for (final key in keys) {
      events.add(EventBuilder.keyDown(key, modifiers: modifiers));
    }

    // Release all keys up (in reverse order)
    for (final key in keys.reversed) {
      events.add(EventBuilder.keyUp(key, modifiers: modifiers));
    }

    return events;
  }

  /// Modifier key press and release.
  static List<InputEvent> modifierPress(KeyModifier modifier) {
    final key = switch (modifier) {
      KeyModifier.shift => 'Shift',
      KeyModifier.control => 'Control',
      KeyModifier.alt => 'Alt',
      KeyModifier.meta => 'Meta',
    };

    return [
      EventBuilder.keyDown(key, modifiers: {modifier}),
      EventBuilder.keyUp(key),
    ];
  }
}
