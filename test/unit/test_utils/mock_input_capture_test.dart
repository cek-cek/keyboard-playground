import 'package:flutter_test/flutter_test.dart';

import '../../test_utils/builders/event_builder.dart';
import '../../test_utils/mocks/mock_input_capture.dart';

void main() {
  group('MockInputCapture', () {
    late MockInputCapture mockInput;

    setUp(() {
      mockInput = MockInputCapture();
    });

    tearDown(() async {
      await mockInput.dispose();
    });

    test('starts and stops capture', () async {
      expect(await mockInput.isCapturing(), false);

      final started = await mockInput.startCapture();
      expect(started, true);
      expect(await mockInput.isCapturing(), true);

      final stopped = await mockInput.stopCapture();
      expect(stopped, true);
      expect(await mockInput.isCapturing(), false);
    });

    test('emits single event', () async {
      final events = <dynamic>[];
      mockInput.events.listen(events.add);

      final testEvent = EventBuilder.keyDown('a');
      mockInput.emitEvent(testEvent);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(events, hasLength(1));
      expect(events[0], testEvent);
    });

    test('emits multiple events', () async {
      final events = <dynamic>[];
      mockInput.events.listen(events.add);

      final testEvents = [
        EventBuilder.keyDown('a'),
        EventBuilder.keyUp('a'),
        EventBuilder.keyDown('b'),
      ];

      mockInput.emitEvents(testEvents);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(events, hasLength(3));
      expect(events, testEvents);
    });

    test('allows multiple listeners', () async {
      final events1 = <dynamic>[];
      final events2 = <dynamic>[];

      mockInput.events.listen(events1.add);
      mockInput.events.listen(events2.add);

      final testEvent = EventBuilder.keyDown('a');
      mockInput.emitEvent(testEvent);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(events1, hasLength(1));
      expect(events2, hasLength(1));
    });
  });
}
