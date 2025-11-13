import 'package:flutter_test/flutter_test.dart';
import 'package:keyboard_playground/platform/input_capture.dart';
import 'package:keyboard_playground/platform/input_events.dart';

void main() {
  group('InputCapture', () {
    late InputCapture inputCapture;

    setUp(() {
      inputCapture = InputCapture();
    });

    group('Event Parsing', () {
      test('parses key down event correctly', () {
        final rawEvent = <String, dynamic>{
          'type': 'keyDown',
          'timestamp': 1234567890,
          'keyCode': 65,
          'key': 'a',
          'modifiers': <String>[],
        };

        final event = inputCapture.parseEvent(rawEvent);

        expect(event, isA<KeyEvent>());
        final keyEvent = event as KeyEvent;
        expect(keyEvent.type, InputEventType.keyDown);
        expect(keyEvent.keyCode, 65);
        expect(keyEvent.key, 'a');
        expect(keyEvent.isDown, true);
        expect(keyEvent.modifiers, isEmpty);
        expect(keyEvent.timestamp,
            DateTime.fromMillisecondsSinceEpoch(1234567890),);
      });

      test('parses key up event correctly', () {
        final rawEvent = <String, dynamic>{
          'type': 'keyUp',
          'timestamp': 1234567890,
          'keyCode': 65,
          'key': 'a',
          'modifiers': <String>[],
        };

        final event = inputCapture.parseEvent(rawEvent);

        expect(event, isA<KeyEvent>());
        final keyEvent = event as KeyEvent;
        expect(keyEvent.type, InputEventType.keyUp);
        expect(keyEvent.isDown, false);
      });

      test('parses key event with modifiers', () {
        final rawEvent = <String, dynamic>{
          'type': 'keyDown',
          'timestamp': 1234567890,
          'keyCode': 65,
          'key': 'a',
          'modifiers': <String>['shift', 'control', 'alt', 'meta'],
        };

        final event = inputCapture.parseEvent(rawEvent);

        expect(event, isA<KeyEvent>());
        final keyEvent = event as KeyEvent;
        expect(
            keyEvent.modifiers,
            containsAll([
              KeyModifier.shift,
              KeyModifier.control,
              KeyModifier.alt,
              KeyModifier.meta,
            ]),);
        expect(keyEvent.modifiers.length, 4);
      });

      test('parses mouse move event correctly', () {
        final rawEvent = <String, dynamic>{
          'type': 'mouseMove',
          'timestamp': 1234567890,
          'x': 100.5,
          'y': 200.7,
        };

        final event = inputCapture.parseEvent(rawEvent);

        expect(event, isA<MouseMoveEvent>());
        final mouseEvent = event as MouseMoveEvent;
        expect(mouseEvent.type, InputEventType.mouseMove);
        expect(mouseEvent.x, 100.5);
        expect(mouseEvent.y, 200.7);
        expect(mouseEvent.timestamp,
            DateTime.fromMillisecondsSinceEpoch(1234567890),);
      });

      test('parses mouse button down event correctly', () {
        final rawEvent = <String, dynamic>{
          'type': 'mouseDown',
          'timestamp': 1234567890,
          'button': 'left',
          'x': 100.0,
          'y': 200.0,
        };

        final event = inputCapture.parseEvent(rawEvent);

        expect(event, isA<MouseButtonEvent>());
        final buttonEvent = event as MouseButtonEvent;
        expect(buttonEvent.type, InputEventType.mouseDown);
        expect(buttonEvent.button, MouseButton.left);
        expect(buttonEvent.x, 100.0);
        expect(buttonEvent.y, 200.0);
        expect(buttonEvent.isDown, true);
      });

      test('parses mouse button up event correctly', () {
        final rawEvent = <String, dynamic>{
          'type': 'mouseUp',
          'timestamp': 1234567890,
          'button': 'right',
          'x': 100.0,
          'y': 200.0,
        };

        final event = inputCapture.parseEvent(rawEvent);

        expect(event, isA<MouseButtonEvent>());
        final buttonEvent = event as MouseButtonEvent;
        expect(buttonEvent.type, InputEventType.mouseUp);
        expect(buttonEvent.button, MouseButton.right);
        expect(buttonEvent.isDown, false);
      });

      test('parses all mouse button types', () {
        for (final button in ['left', 'right', 'middle']) {
          final rawEvent = <String, dynamic>{
            'type': 'mouseDown',
            'timestamp': 1234567890,
            'button': button,
            'x': 100.0,
            'y': 200.0,
          };

          final event = inputCapture.parseEvent(rawEvent);
          final buttonEvent = event as MouseButtonEvent;

          switch (button) {
            case 'left':
              expect(buttonEvent.button, MouseButton.left);
            case 'right':
              expect(buttonEvent.button, MouseButton.right);
            case 'middle':
              expect(buttonEvent.button, MouseButton.middle);
          }
        }
      });

      test('parses mouse scroll event correctly', () {
        final rawEvent = <String, dynamic>{
          'type': 'mouseScroll',
          'timestamp': 1234567890,
          'deltaX': 1.5,
          'deltaY': -2.3,
        };

        final event = inputCapture.parseEvent(rawEvent);

        expect(event, isA<MouseScrollEvent>());
        final scrollEvent = event as MouseScrollEvent;
        expect(scrollEvent.type, InputEventType.mouseScroll);
        expect(scrollEvent.deltaX, 1.5);
        expect(scrollEvent.deltaY, -2.3);
      });

      test('throws on unknown event type', () {
        final rawEvent = <String, dynamic>{
          'type': 'unknownEvent',
          'timestamp': 1234567890,
        };

        expect(
          () => inputCapture.parseEvent(rawEvent),
          throwsA(isA<UnimplementedError>()),
        );
      });
    });

    group('Modifier Parsing', () {
      test('parses shift modifier', () {
        expect(
          inputCapture.parseModifier('shift'),
          KeyModifier.shift,
        );
      });

      test('parses control modifier', () {
        expect(
          inputCapture.parseModifier('control'),
          KeyModifier.control,
        );
      });

      test('parses alt modifier', () {
        expect(
          inputCapture.parseModifier('alt'),
          KeyModifier.alt,
        );
      });

      test('parses meta modifier', () {
        expect(
          inputCapture.parseModifier('meta'),
          KeyModifier.meta,
        );
      });

      test('throws on unknown modifier', () {
        expect(
          () => inputCapture.parseModifier('unknown'),
          throwsArgumentError,
        );
      });
    });

    group('Button Parsing', () {
      test('parses left button', () {
        expect(
          inputCapture.parseButton('left'),
          MouseButton.left,
        );
      });

      test('parses right button', () {
        expect(
          inputCapture.parseButton('right'),
          MouseButton.right,
        );
      });

      test('parses middle button', () {
        expect(
          inputCapture.parseButton('middle'),
          MouseButton.middle,
        );
      });

      test('returns other for unknown button', () {
        expect(
          inputCapture.parseButton('unknown'),
          MouseButton.other,
        );
      });
    });
  });

  group('KeyEvent', () {
    test('toString returns formatted string', () {
      final event = KeyEvent(
        keyCode: 65,
        key: 'a',
        modifiers: {KeyModifier.shift, KeyModifier.control},
        isDown: true,
        timestamp: DateTime(2024),
      );

      final str = event.toString();
      expect(str, contains('KeyEvent'));
      expect(str, contains('down'));
      expect(str, contains('a'));
      expect(str, contains('65'));
    });
  });

  group('MouseMoveEvent', () {
    test('toString returns formatted string', () {
      final event = MouseMoveEvent(
        x: 123.4,
        y: 567.8,
        timestamp: DateTime(2024),
      );

      final str = event.toString();
      expect(str, contains('MouseMoveEvent'));
      expect(str, contains('123'));
      expect(str, contains('567'));
    });
  });

  group('MouseButtonEvent', () {
    test('toString returns formatted string for button down', () {
      final event = MouseButtonEvent(
        button: MouseButton.left,
        x: 100,
        y: 200,
        isDown: true,
        timestamp: DateTime(2024),
      );

      final str = event.toString();
      expect(str, contains('MouseButtonEvent'));
      expect(str, contains('down'));
      expect(str, contains('left'));
    });

    test('toString returns formatted string for button up', () {
      final event = MouseButtonEvent(
        button: MouseButton.right,
        x: 100,
        y: 200,
        isDown: false,
        timestamp: DateTime(2024),
      );

      final str = event.toString();
      expect(str, contains('up'));
      expect(str, contains('right'));
    });
  });

  group('MouseScrollEvent', () {
    test('toString returns formatted string', () {
      final event = MouseScrollEvent(
        deltaX: 1.5,
        deltaY: -2.3,
        timestamp: DateTime(2024),
      );

      final str = event.toString();
      expect(str, contains('MouseScrollEvent'));
      expect(str, contains('1.5'));
      expect(str, contains('-2.3'));
    });
  });
}
