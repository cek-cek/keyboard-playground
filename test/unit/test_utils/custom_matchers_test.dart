import 'package:flutter_test/flutter_test.dart';
import 'package:keyboard_playground/platform/input_events.dart';

import '../../test_utils/builders/event_builder.dart';
import '../../test_utils/matchers/custom_matchers.dart';

void main() {
  group('Custom Matchers', () {
    group('isKeyEvent', () {
      test('matches key event with specific key', () {
        final event = EventBuilder.keyDown('a');

        expect(event, isKeyEvent(key: 'a'));
      });

      test('matches key event with isDown', () {
        final downEvent = EventBuilder.keyDown('a');
        final upEvent = EventBuilder.keyUp('a');

        expect(downEvent, isKeyEvent(isDown: true));
        expect(upEvent, isKeyEvent(isDown: false));
      });

      test('matches key event with modifiers', () {
        final event = EventBuilder.keyDown(
          'A',
          modifiers: {KeyModifier.shift},
        );

        expect(event, isKeyEvent(modifiers: {KeyModifier.shift}));
      });

      test('does not match wrong key', () {
        final event = EventBuilder.keyDown('a');

        expect(event, isNot(isKeyEvent(key: 'b')));
      });

      test('does not match non-KeyEvent', () {
        final event = EventBuilder.mouseClick(100, 200);

        expect(event, isNot(isKeyEvent()));
      });
    });

    group('isMouseButtonEvent', () {
      test('matches mouse button event with button', () {
        final event = EventBuilder.mouseClick(100, 200);

        expect(event, isMouseButtonEvent(button: MouseButton.left));
      });

      test('matches mouse button event with coordinates', () {
        final event = EventBuilder.mouseClick(100, 200);

        expect(event, isMouseButtonEvent(x: 100, y: 200));
      });

      test('matches mouse button event with isDown', () {
        final downEvent = EventBuilder.mouseDown(100, 200);
        final upEvent = EventBuilder.mouseUp(100, 200);

        expect(downEvent, isMouseButtonEvent(isDown: true));
        expect(upEvent, isMouseButtonEvent(isDown: false));
      });

      test('does not match wrong button', () {
        final event = EventBuilder.mouseClick(100, 200);

        expect(event, isNot(isMouseButtonEvent(button: MouseButton.right)));
      });

      test('does not match non-MouseButtonEvent', () {
        final event = EventBuilder.keyDown('a');

        expect(event, isNot(isMouseButtonEvent()));
      });
    });

    group('isMouseMoveEvent', () {
      test('matches mouse move event with coordinates', () {
        final event = EventBuilder.mouseMove(100, 200);

        expect(event, isMouseMoveEvent(x: 100, y: 200));
      });

      test('does not match wrong coordinates', () {
        final event = EventBuilder.mouseMove(100, 200);

        expect(event, isNot(isMouseMoveEvent(x: 150, y: 200)));
      });

      test('does not match non-MouseMoveEvent', () {
        final event = EventBuilder.keyDown('a');

        expect(event, isNot(isMouseMoveEvent()));
      });
    });

    group('isMouseScrollEvent', () {
      test('matches mouse scroll event with deltas', () {
        final event = EventBuilder.mouseScroll(deltaX: 10, deltaY: -20);

        expect(event, isMouseScrollEvent(deltaX: 10, deltaY: -20));
      });

      test('does not match wrong deltas', () {
        final event = EventBuilder.mouseScroll(deltaX: 10, deltaY: -20);

        expect(event, isNot(isMouseScrollEvent(deltaX: 20, deltaY: -20)));
      });

      test('does not match non-MouseScrollEvent', () {
        final event = EventBuilder.keyDown('a');

        expect(event, isNot(isMouseScrollEvent()));
      });
    });
  });
}
