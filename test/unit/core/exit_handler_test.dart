import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyboard_playground/core/exit_handler.dart';
import 'package:keyboard_playground/platform/input_capture.dart';
import 'package:keyboard_playground/platform/input_events.dart';

/// Mock InputCapture for testing.
class MockInputCapture extends InputCapture {
  final StreamController<InputEvent> _controller =
      StreamController<InputEvent>.broadcast();

  @override
  Stream<InputEvent> get events => _controller.stream;

  /// Simulates a key event.
  void simulateKeyEvent(KeyEvent event) {
    _controller.add(event);
  }

  /// Simulates a mouse button event.
  void simulateMouseEvent(MouseButtonEvent event) {
    _controller.add(event);
  }

  /// Disposes the mock.
  void dispose() {
    _controller.close();
  }
}

void main() {
  group('ExitHandler', () {
    late MockInputCapture mockInput;
    late ExitHandler exitHandler;

    setUp(() {
      mockInput = MockInputCapture();
      exitHandler = ExitHandler(
        inputCapture: mockInput,
      );
    });

    tearDown(() async {
      await exitHandler.dispose();
      mockInput.dispose();
    });

    group('Keyboard Sequence', () {
      test('completes successfully with correct sequence', () async {
        final progressEvents = <ExitProgress>[];
        final exitEvents = <void>[];

        exitHandler.progressStream.listen(progressEvents.add);
        exitHandler.exitTriggered.listen(exitEvents.add);

        // Simulate correct sequence: Alt, Control, ArrowRight, Escape, q
        final keys = ['Alt', 'Control', 'ArrowRight', 'Escape', 'q'];
        for (final key in keys) {
          mockInput.simulateKeyEvent(
            KeyEvent(
              keyCode: 0,
              key: key,
              modifiers: {},
              isDown: true,
              timestamp: DateTime.now(),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }

        // Wait for events to propagate
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Should have progress events for each step
        expect(progressEvents.length, greaterThanOrEqualTo(keys.length));

        // Should have a completed event
        final completedEvents = progressEvents
            .where((p) => p.state == ExitSequenceState.completed)
            .toList();
        expect(completedEvents.length, 1);
        expect(completedEvents.first.currentStep, keys.length);

        // Exit should be triggered
        expect(exitEvents.length, 1);
      });

      test('resets on wrong key', () async {
        final progressEvents = <ExitProgress>[];

        exitHandler.progressStream.listen(progressEvents.add);

        // Start sequence correctly
        mockInput.simulateKeyEvent(
          KeyEvent(
            keyCode: 0,
            key: 'Alt',
            modifiers: {},
            isDown: true,
            timestamp: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(exitHandler.currentKeyboardStep, 1);

        // Press wrong key
        mockInput.simulateKeyEvent(
          KeyEvent(
            keyCode: 0,
            key: 'x',
            modifiers: {},
            isDown: true,
            timestamp: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Should reset to 0
        expect(exitHandler.currentKeyboardStep, 0);

        // Should have progress events showing reset
        final lastProgress = progressEvents.last;
        expect(lastProgress.state, ExitSequenceState.idle);
        expect(lastProgress.currentStep, 0);
      });

      test('resets on timeout', () async {
        final progressEvents = <ExitProgress>[];

        exitHandler.progressStream.listen(progressEvents.add);

        // Use a shorter timeout for testing
        await exitHandler.dispose();
        exitHandler = ExitHandler(
          inputCapture: mockInput,
          keyboardSequence: const ExitSequence(
            type: ExitSequenceType.keyboard,
            steps: ['Alt', 'Control'],
            timeout: Duration(milliseconds: 500),
          ),
        );

        exitHandler.progressStream.listen(progressEvents.add);

        // Start sequence
        mockInput.simulateKeyEvent(
          KeyEvent(
            keyCode: 0,
            key: 'Alt',
            modifiers: {},
            isDown: true,
            timestamp: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(exitHandler.currentKeyboardStep, 1);

        // Wait for timeout
        await Future<void>.delayed(const Duration(milliseconds: 600));

        // Should reset to 0
        expect(exitHandler.currentKeyboardStep, 0);

        // Last progress should show idle state
        final lastProgress = progressEvents.last;
        expect(lastProgress.state, ExitSequenceState.idle);
      });

      test('maintains partial progress until timeout or wrong key', () async {
        // Start sequence
        mockInput.simulateKeyEvent(
          KeyEvent(
            keyCode: 0,
            key: 'Alt',
            modifiers: {},
            isDown: true,
            timestamp: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        mockInput.simulateKeyEvent(
          KeyEvent(
            keyCode: 0,
            key: 'Control',
            modifiers: {},
            isDown: true,
            timestamp: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Should be at step 2
        expect(exitHandler.currentKeyboardStep, 2);

        // Wait a bit but not timeout
        await Future<void>.delayed(const Duration(milliseconds: 200));

        // Should still be at step 2
        expect(exitHandler.currentKeyboardStep, 2);
      });

      test('ignores key up events', () async {
        // Press Alt down
        mockInput.simulateKeyEvent(
          KeyEvent(
            keyCode: 0,
            key: 'Alt',
            modifiers: {},
            isDown: true,
            timestamp: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(exitHandler.currentKeyboardStep, 1);

        // Release Alt (key up)
        mockInput.simulateKeyEvent(
          KeyEvent(
            keyCode: 0,
            key: 'Alt',
            modifiers: {},
            isDown: false,
            timestamp: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Should still be at step 1
        expect(exitHandler.currentKeyboardStep, 1);
      });
    });

    group('Mouse Sequence', () {
      test('completes successfully with correct corner sequence', () async {
        final progressEvents = <ExitProgress>[];
        final exitEvents = <void>[];

        exitHandler.progressStream.listen(progressEvents.add);
        exitHandler.exitTriggered.listen(exitEvents.add);

        // Click corners: TL, TR, BR, BL
        final corners = [
          (10.0, 10.0), // Top-left
          (1910.0, 10.0), // Top-right
          (1910.0, 1070.0), // Bottom-right
          (10.0, 1070.0), // Bottom-left
        ];

        for (final (x, y) in corners) {
          mockInput.simulateMouseEvent(
            MouseButtonEvent(
              button: MouseButton.left,
              x: x,
              y: y,
              isDown: true,
              timestamp: DateTime.now(),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }

        // Wait for events to propagate
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Should have progress events for each corner
        expect(progressEvents.length, greaterThanOrEqualTo(corners.length));

        // Should have a completed event
        final completedEvents = progressEvents
            .where((p) => p.state == ExitSequenceState.completed)
            .toList();
        expect(completedEvents.length, 1);

        // Exit should be triggered
        expect(exitEvents.length, 1);
      });

      test('resets on wrong corner', () async {
        // Click top-left (correct)
        mockInput.simulateMouseEvent(
          MouseButtonEvent(
            button: MouseButton.left,
            x: 10,
            y: 10,
            isDown: true,
            timestamp: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(exitHandler.currentMouseStep, 1);

        // Click bottom-left (wrong - should be top-right)
        mockInput.simulateMouseEvent(
          MouseButtonEvent(
            button: MouseButton.left,
            x: 10,
            y: 1070,
            isDown: true,
            timestamp: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Should reset to 0
        expect(exitHandler.currentMouseStep, 0);
      });

      test('resets when clicking outside corners', () async {
        // Click top-left (correct)
        mockInput.simulateMouseEvent(
          MouseButtonEvent(
            button: MouseButton.left,
            x: 10,
            y: 10,
            isDown: true,
            timestamp: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(exitHandler.currentMouseStep, 1);

        // Click center of screen (not a corner)
        mockInput.simulateMouseEvent(
          MouseButtonEvent(
            button: MouseButton.left,
            x: 960,
            y: 540,
            isDown: true,
            timestamp: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Should reset to 0
        expect(exitHandler.currentMouseStep, 0);
      });

      test('ignores non-left-button clicks', () async {
        // Right-click top-left
        mockInput.simulateMouseEvent(
          MouseButtonEvent(
            button: MouseButton.right,
            x: 10,
            y: 10,
            isDown: true,
            timestamp: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Should not advance
        expect(exitHandler.currentMouseStep, 0);
      });

      test('resets on timeout', () async {
        // Use shorter timeout
        await exitHandler.dispose();
        exitHandler = ExitHandler(
          inputCapture: mockInput,
          mouseSequence: const ExitSequence(
            type: ExitSequenceType.mouse,
            steps: ['topLeft', 'topRight'],
            timeout: Duration(milliseconds: 500),
          ),
        );

        // Click top-left
        mockInput.simulateMouseEvent(
          MouseButtonEvent(
            button: MouseButton.left,
            x: 10,
            y: 10,
            isDown: true,
            timestamp: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(exitHandler.currentMouseStep, 1);

        // Wait for timeout
        await Future<void>.delayed(const Duration(milliseconds: 600));

        // Should reset
        expect(exitHandler.currentMouseStep, 0);
      });
    });

    group('Corner Detection', () {
      test('detects all four corners correctly', () async {
        // Test by simulating clicks and checking if sequence advances
        // Top-left
        mockInput.simulateMouseEvent(
          MouseButtonEvent(
            button: MouseButton.left,
            x: 10,
            y: 10,
            isDown: true,
            timestamp: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(exitHandler.currentMouseStep, 1);

        // Top-right
        mockInput.simulateMouseEvent(
          MouseButtonEvent(
            button: MouseButton.left,
            x: 1910,
            y: 10,
            isDown: true,
            timestamp: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(exitHandler.currentMouseStep, 2);

        // Bottom-right
        mockInput.simulateMouseEvent(
          MouseButtonEvent(
            button: MouseButton.left,
            x: 1910,
            y: 1070,
            isDown: true,
            timestamp: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(exitHandler.currentMouseStep, 3);

        // Bottom-left
        mockInput.simulateMouseEvent(
          MouseButtonEvent(
            button: MouseButton.left,
            x: 10,
            y: 1070,
            isDown: true,
            timestamp: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(exitHandler.currentMouseStep, 0); // Resets after completion
      });

      test('ignores center clicks', () async {
        // Center click should not advance sequence
        mockInput.simulateMouseEvent(
          MouseButtonEvent(
            button: MouseButton.left,
            x: 960,
            y: 540,
            isDown: true,
            timestamp: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(exitHandler.currentMouseStep, 0);
      });

      test('uses threshold correctly', () async {
        // Just inside threshold (49px in both x and y from top-left corner)
        mockInput.simulateMouseEvent(
          MouseButtonEvent(
            button: MouseButton.left,
            x: 49,
            y: 49,
            isDown: true,
            timestamp: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(exitHandler.currentMouseStep, 1);

        // Reset
        await exitHandler.dispose();
        exitHandler = ExitHandler(
          inputCapture: mockInput,
        );

        // Just outside threshold (51px in both x and y from top-left corner) - should not advance
        mockInput.simulateMouseEvent(
          MouseButtonEvent(
            button: MouseButton.left,
            x: 51,
            y: 51,
            isDown: true,
            timestamp: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(exitHandler.currentMouseStep, 0);
      });
    });

    group('Progress Tracking', () {
      test('emits progress updates on each step', () async {
        final progressEvents = <ExitProgress>[];
        exitHandler.progressStream.listen(progressEvents.add);

        // Simulate first two steps
        mockInput.simulateKeyEvent(
          KeyEvent(
            keyCode: 0,
            key: 'Alt',
            modifiers: {},
            isDown: true,
            timestamp: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        mockInput.simulateKeyEvent(
          KeyEvent(
            keyCode: 0,
            key: 'Control',
            modifiers: {},
            isDown: true,
            timestamp: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Should have at least 2 progress events
        expect(progressEvents.length, greaterThanOrEqualTo(2));

        // Check progress values
        final progress1 = progressEvents[0];
        expect(progress1.currentStep, 1);
        expect(progress1.state, ExitSequenceState.inProgress);

        final progress2 = progressEvents[1];
        expect(progress2.currentStep, 2);
        expect(progress2.state, ExitSequenceState.inProgress);
      });

      test('calculates progress fraction correctly', () async {
        final progressEvents = <ExitProgress>[];
        exitHandler.progressStream.listen(progressEvents.add);

        // Complete half the sequence
        mockInput.simulateKeyEvent(
          KeyEvent(
            keyCode: 0,
            key: 'Alt',
            modifiers: {},
            isDown: true,
            timestamp: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        mockInput.simulateKeyEvent(
          KeyEvent(
            keyCode: 0,
            key: 'Control',
            modifiers: {},
            isDown: true,
            timestamp: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final lastProgress = progressEvents.last;
        // 2 steps out of 5 total = 0.4
        expect(lastProgress.progress, closeTo(0.4, 0.01));
      });
    });

    group('ExitProgress', () {
      test('calculates progress correctly', () {
        const progress = ExitProgress(
          currentStep: 3,
          totalSteps: 5,
          remainingTime: Duration(seconds: 2),
          state: ExitSequenceState.inProgress,
        );

        expect(progress.progress, closeTo(0.6, 0.01));
        expect(progress.isCompleted, false);
      });

      test('handles completed state', () {
        const progress = ExitProgress(
          currentStep: 5,
          totalSteps: 5,
          remainingTime: Duration.zero,
          state: ExitSequenceState.completed,
        );

        expect(progress.progress, 1.0);
        expect(progress.isCompleted, true);
      });

      test('handles zero total steps', () {
        const progress = ExitProgress(
          currentStep: 0,
          totalSteps: 0,
          remainingTime: Duration.zero,
          state: ExitSequenceState.idle,
        );

        expect(progress.progress, 0.0);
      });
    });

    group('ExitSequence', () {
      test('has correct default keyboard sequence', () {
        expect(ExitSequence.keyboardDefault.type, ExitSequenceType.keyboard);
        expect(ExitSequence.keyboardDefault.steps.length, 5);
        expect(ExitSequence.keyboardDefault.timeout.inSeconds, 5);
      });

      test('has correct default mouse sequence', () {
        expect(ExitSequence.mouseDefault.type, ExitSequenceType.mouse);
        expect(ExitSequence.mouseDefault.steps.length, 4);
        expect(ExitSequence.mouseDefault.timeout.inSeconds, 10);
      });
    });

    group('Edge Cases', () {
      test('handles rapid repeated correct inputs', () async {
        // Simulate very fast sequence completion
        final keys = ['Alt', 'Control', 'ArrowRight', 'Escape', 'q'];
        for (final key in keys) {
          mockInput.simulateKeyEvent(
            KeyEvent(
              keyCode: 0,
              key: key,
              modifiers: {},
              isDown: true,
              timestamp: DateTime.now(),
            ),
          );
          // Very short delay
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }

        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Should still complete successfully
        expect(exitHandler.currentKeyboardStep, 0); // Reset after completion
      });

      test('handles interleaved keyboard and mouse sequences', () async {
        // Start keyboard sequence
        mockInput.simulateKeyEvent(
          KeyEvent(
            keyCode: 0,
            key: 'Alt',
            modifiers: {},
            isDown: true,
            timestamp: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(exitHandler.currentKeyboardStep, 1);

        // Start mouse sequence
        mockInput.simulateMouseEvent(
          MouseButtonEvent(
            button: MouseButton.left,
            x: 10,
            y: 10,
            isDown: true,
            timestamp: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(exitHandler.currentMouseStep, 1);

        // Both should be tracking independently
        expect(exitHandler.currentKeyboardStep, 1);
        expect(exitHandler.currentMouseStep, 1);
      });
    });
  });
}
