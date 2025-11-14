import 'package:flutter_test/flutter_test.dart';
import 'package:keyboard_playground/platform/input_events.dart';

import '../../test_utils/builders/event_builder.dart';

void main() {
  group('EventBuilder', () {
    group('keyDown', () {
      test('creates key down event with default values', () {
        final event = EventBuilder.keyDown('a');

        expect(event.key, 'a');
        expect(event.isDown, true);
        expect(event.modifiers, isEmpty);
      });

      test('creates key down event with modifiers', () {
        final event = EventBuilder.keyDown(
          'A',
          modifiers: {KeyModifier.shift},
        );

        expect(event.key, 'A');
        expect(event.isDown, true);
        expect(event.modifiers, {KeyModifier.shift});
      });

      test('uses custom key code when provided', () {
        final event = EventBuilder.keyDown('Enter', keyCode: 13);

        expect(event.key, 'Enter');
        expect(event.keyCode, 13);
      });
    });

    group('keyUp', () {
      test('creates key up event', () {
        final event = EventBuilder.keyUp('a');

        expect(event.key, 'a');
        expect(event.isDown, false);
      });
    });

    group('mouseMove', () {
      test('creates mouse move event', () {
        final event = EventBuilder.mouseMove(100, 200);

        expect(event.x, 100);
        expect(event.y, 200);
      });
    });

    group('mouseClick', () {
      test('creates mouse click event with default button', () {
        final event = EventBuilder.mouseClick(100, 200);

        expect(event.button, MouseButton.left);
        expect(event.x, 100);
        expect(event.y, 200);
        expect(event.isDown, true);
      });

      test('creates mouse click with custom button', () {
        final event = EventBuilder.mouseClick(
          100,
          200,
          button: MouseButton.right,
        );

        expect(event.button, MouseButton.right);
      });
    });

    group('mouseDown', () {
      test('creates mouse button down event', () {
        final event = EventBuilder.mouseDown(100, 200);

        expect(event.isDown, true);
        expect(event.x, 100);
        expect(event.y, 200);
      });
    });

    group('mouseUp', () {
      test('creates mouse button up event', () {
        final event = EventBuilder.mouseUp(100, 200);

        expect(event.isDown, false);
        expect(event.x, 100);
        expect(event.y, 200);
      });
    });

    group('mouseScroll', () {
      test('creates mouse scroll event', () {
        final event = EventBuilder.mouseScroll(deltaX: 10, deltaY: -20);

        expect(event.deltaX, 10);
        expect(event.deltaY, -20);
      });

      test('creates scroll event with default deltas', () {
        final event = EventBuilder.mouseScroll();

        expect(event.deltaX, 0);
        expect(event.deltaY, 0);
      });
    });

    group('keyPress', () {
      test('creates complete key press sequence', () {
        final events = EventBuilder.keyPress('a');

        expect(events, hasLength(2));
        expect(events[0].isDown, true);
        expect(events[1].isDown, false);
        expect(events[0].key, 'a');
        expect(events[1].key, 'a');
      });
    });

    group('mouseClickSequence', () {
      test('creates complete mouse click sequence', () {
        final events = EventBuilder.mouseClickSequence(100, 200);

        expect(events, hasLength(2));
        expect(events[0].isDown, true);
        expect(events[1].isDown, false);
        expect(events[0].x, 100);
        expect(events[1].x, 100);
      });
    });
  });
}
