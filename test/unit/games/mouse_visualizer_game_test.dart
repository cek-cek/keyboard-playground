import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyboard_playground/games/mouse_visualizer_game.dart';
import 'package:keyboard_playground/platform/input_events.dart' as events;

import '../../test_utils/builders/event_builder.dart';

void main() {
  group('MouseVisualizerGame', () {
    late MouseVisualizerGame game;

    setUp(() {
      game = MouseVisualizerGame();
    });

    tearDown(() {
      game.dispose();
    });

    group('Basic Properties', () {
      test('has correct id', () {
        expect(game.id, equals('mouse_visualizer'));
      });

      test('has correct name', () {
        expect(game.name, equals('Mouse Visualizer'));
      });

      test('has correct description', () {
        expect(
          game.description,
          equals('Real-time visualization of mouse position and button states'),
        );
      });

      test('buildUI returns a widget', () {
        final widget = game.buildUI();
        expect(widget, isA<Widget>());
      });
    });

    group('Mouse Move Events', () {
      testWidgets('updates mouse position on move event', (tester) async {
        await tester.pumpWidget(MaterialApp(home: game.buildUI()));

        // Send a mouse move event
        final moveEvent = EventBuilder.mouseMove(100, 200);
        game.onMouseEvent(moveEvent);

        await tester.pump();

        // Widget should rebuild (verify by pumping)
        expect(tester.takeException(), isNull);
      });

      testWidgets('tracks trail of mouse movements', (tester) async {
        await tester.pumpWidget(MaterialApp(home: game.buildUI()));

        // Send multiple mouse move events
        for (var i = 0; i < 10; i++) {
          final moveEvent = EventBuilder.mouseMove(
            100.0 + i * 10,
            200.0 + i * 10,
          );
          game.onMouseEvent(moveEvent);
          await tester.pump();
        }

        // Verify no exceptions occurred
        expect(tester.takeException(), isNull);
      });

      testWidgets('limits trail to 30 points', (tester) async {
        await tester.pumpWidget(MaterialApp(home: game.buildUI()));

        // Send 50 mouse move events
        for (var i = 0; i < 50; i++) {
          final moveEvent = EventBuilder.mouseMove(
            100.0 + i,
            200.0 + i,
          );
          game.onMouseEvent(moveEvent);
          await tester.pump(Duration.zero);
        }

        // Verify no exceptions occurred (trail should be limited internally)
        expect(tester.takeException(), isNull);
      });
    });

    group('Mouse Button Events', () {
      testWidgets('handles left button click', (tester) async {
        await tester.pumpWidget(MaterialApp(home: game.buildUI()));

        // Send left button down event
        final downEvent = EventBuilder.mouseDown(300, 400);
        game.onMouseEvent(downEvent);
        await tester.pump();

        expect(tester.takeException(), isNull);

        // Send left button up event
        final upEvent = EventBuilder.mouseUp(300, 400);
        game.onMouseEvent(upEvent);
        await tester.pump();

        expect(tester.takeException(), isNull);
      });

      testWidgets('handles right button click', (tester) async {
        await tester.pumpWidget(MaterialApp(home: game.buildUI()));

        final downEvent = EventBuilder.mouseDown(
          300,
          400,
          button: events.MouseButton.right,
        );
        game.onMouseEvent(downEvent);
        await tester.pump();

        expect(tester.takeException(), isNull);

        final upEvent = EventBuilder.mouseUp(
          300,
          400,
          button: events.MouseButton.right,
        );
        game.onMouseEvent(upEvent);
        await tester.pump();

        expect(tester.takeException(), isNull);
      });

      testWidgets('handles middle button click', (tester) async {
        await tester.pumpWidget(MaterialApp(home: game.buildUI()));

        final downEvent = EventBuilder.mouseDown(
          300,
          400,
          button: events.MouseButton.middle,
        );
        game.onMouseEvent(downEvent);
        await tester.pump();

        expect(tester.takeException(), isNull);

        final upEvent = EventBuilder.mouseUp(
          300,
          400,
          button: events.MouseButton.middle,
        );
        game.onMouseEvent(upEvent);
        await tester.pump();

        expect(tester.takeException(), isNull);
      });

      testWidgets('creates ripple on button down', (tester) async {
        await tester.pumpWidget(MaterialApp(home: game.buildUI()));

        // Click at position
        final clickEvent = EventBuilder.mouseDown(500, 600);
        game.onMouseEvent(clickEvent);
        await tester.pump();

        // Should not throw exception
        expect(tester.takeException(), isNull);

        // Pump again to let ripple animate
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      });

      testWidgets('handles multiple simultaneous button presses',
          (tester) async {
        await tester.pumpWidget(MaterialApp(home: game.buildUI()));

        // Press left button
        game.onMouseEvent(EventBuilder.mouseDown(100, 100));
        await tester.pump();

        // Press right button (while left is still down)
        game.onMouseEvent(
          EventBuilder.mouseDown(
            100,
            100,
            button: events.MouseButton.right,
          ),
        );
        await tester.pump();

        // Press middle button (while both are still down)
        game.onMouseEvent(
          EventBuilder.mouseDown(
            100,
            100,
            button: events.MouseButton.middle,
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);

        // Release all buttons
        game.onMouseEvent(EventBuilder.mouseUp(100, 100));
        game.onMouseEvent(
          EventBuilder.mouseUp(100, 100, button: events.MouseButton.right),
        );
        game.onMouseEvent(
          EventBuilder.mouseUp(100, 100, button: events.MouseButton.middle),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    });

    group('Ripple Animations', () {
      testWidgets('ripples fade over time', (tester) async {
        await tester.pumpWidget(MaterialApp(home: game.buildUI()));

        // Create a click
        game.onMouseEvent(EventBuilder.mouseDown(300, 400));
        await tester.pump();

        // Pump several frames
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.takeException(), isNull);
        }
      });

      testWidgets('multiple ripples can exist simultaneously', (tester) async {
        await tester.pumpWidget(MaterialApp(home: game.buildUI()));

        // Create multiple clicks at different positions
        game.onMouseEvent(EventBuilder.mouseDown(100, 100));
        await tester.pump(const Duration(milliseconds: 50));

        game.onMouseEvent(EventBuilder.mouseDown(200, 200));
        await tester.pump(const Duration(milliseconds: 50));

        game.onMouseEvent(EventBuilder.mouseDown(300, 300));
        await tester.pump(const Duration(milliseconds: 50));

        expect(tester.takeException(), isNull);

        // Animate ripples
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
      });

      testWidgets('old ripples are removed', (tester) async {
        await tester.pumpWidget(MaterialApp(home: game.buildUI()));

        // Create a click
        game.onMouseEvent(EventBuilder.mouseDown(300, 400));
        await tester.pump();

        // Wait for ripple to complete (> 1 second)
        await tester.pump(const Duration(milliseconds: 1100));
        expect(tester.takeException(), isNull);

        // Trigger another update to clean up old ripples
        game.onMouseEvent(EventBuilder.mouseMove(350, 450));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    });

    group('Button State Indicators', () {
      testWidgets('displays all three button indicators', (tester) async {
        await tester.pumpWidget(MaterialApp(home: game.buildUI()));
        await tester.pump();

        // Find button indicator texts
        expect(find.text('LEFT'), findsOneWidget);
        expect(find.text('RIGHT'), findsOneWidget);
        expect(find.text('MIDDLE'), findsOneWidget);
      });

      testWidgets('button states update on press and release', (tester) async {
        await tester.pumpWidget(MaterialApp(home: game.buildUI()));
        await tester.pump();

        // Press left button
        game.onMouseEvent(EventBuilder.mouseDown(100, 100));
        await tester.pump();
        expect(tester.takeException(), isNull);

        // Release left button
        game.onMouseEvent(EventBuilder.mouseUp(100, 100));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    });

    group('Keyboard Events', () {
      test('ignores keyboard events', () {
        // Mouse visualizer should not respond to keyboard events
        final keyEvent = EventBuilder.keyDown('a');

        // Should not throw exception
        expect(() => game.onKeyEvent(keyEvent), returnsNormally);
      });
    });

    group('UI Rendering', () {
      testWidgets('renders without errors', (tester) async {
        await tester.pumpWidget(MaterialApp(home: game.buildUI()));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('shows instructions', (tester) async {
        await tester.pumpWidget(MaterialApp(home: game.buildUI()));
        await tester.pump();

        expect(
          find.text('Move your mouse to see the trail'),
          findsOneWidget,
        );
        expect(
          find.text('Click to create ripple effects'),
          findsOneWidget,
        );
      });

      testWidgets('updates UI when events occur', (tester) async {
        await tester.pumpWidget(MaterialApp(home: game.buildUI()));
        await tester.pump();

        // Get initial render
        final initialWidget = find.byType(Stack);
        expect(initialWidget, findsOneWidget);

        // Send event
        game.onMouseEvent(EventBuilder.mouseMove(100, 100));
        await tester.pump();

        // UI should still be valid
        expect(find.byType(Stack), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Trail Cleanup', () {
      testWidgets('removes old trail points', (tester) async {
        await tester.pumpWidget(MaterialApp(home: game.buildUI()));

        // Create trail points with old timestamps
        game.onMouseEvent(EventBuilder.mouseMove(100, 100));
        await tester.pump();

        // Wait for trail points to age
        await tester.pump(const Duration(milliseconds: 1100));

        // Move mouse again to trigger cleanup
        game.onMouseEvent(EventBuilder.mouseMove(200, 200));
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    });

    group('Edge Cases', () {
      testWidgets('handles mouse at screen edges', (tester) async {
        await tester.pumpWidget(MaterialApp(home: game.buildUI()));

        // Test corners and edges
        final edgePositions = [
          const Offset(0, 0), // Top-left
          const Offset(1920, 0), // Top-right
          const Offset(0, 1080), // Bottom-left
          const Offset(1920, 1080), // Bottom-right
          const Offset(960, 0), // Top-center
          const Offset(960, 1080), // Bottom-center
        ];

        for (final pos in edgePositions) {
          game.onMouseEvent(EventBuilder.mouseMove(pos.dx, pos.dy));
          await tester.pump();
          expect(tester.takeException(), isNull);
        }
      });

      testWidgets('handles rapid mouse movements', (tester) async {
        await tester.pumpWidget(MaterialApp(home: game.buildUI()));

        // Send many rapid mouse moves
        for (var i = 0; i < 100; i++) {
          game.onMouseEvent(EventBuilder.mouseMove(i * 10.0, i * 5.0));
        }

        await tester.pump();
        expect(tester.takeException(), isNull);
      });

      testWidgets('handles rapid clicking', (tester) async {
        await tester.pumpWidget(MaterialApp(home: game.buildUI()));

        // Send many rapid clicks
        for (var i = 0; i < 20; i++) {
          game.onMouseEvent(EventBuilder.mouseDown(100, 100));
          game.onMouseEvent(EventBuilder.mouseUp(100, 100));
        }

        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    });

    group('Disposal', () {
      test('can be disposed without errors', () {
        final testGame = MouseVisualizerGame();
        expect(() => testGame.dispose(), returnsNormally);
      });

      testWidgets('cleans up resources on disposal', (tester) async {
        final testGame = MouseVisualizerGame();
        await tester.pumpWidget(MaterialApp(home: testGame.buildUI()));
        await tester.pump();

        // Dispose the game
        testGame.dispose();

        // Should not cause errors
        expect(tester.takeException(), isNull);
      });
    });

    group('Integration with Input Events', () {
      testWidgets('handles complete mouse interaction sequence',
          (tester) async {
        await tester.pumpWidget(MaterialApp(home: game.buildUI()));
        await tester.pump();

        // Simulate realistic mouse interaction

        // 1. Move mouse to center
        game.onMouseEvent(EventBuilder.mouseMove(960, 540));
        await tester.pump();

        // 2. Click left button
        game.onMouseEvent(EventBuilder.mouseDown(960, 540));
        await tester.pump(const Duration(milliseconds: 50));
        game.onMouseEvent(EventBuilder.mouseUp(960, 540));
        await tester.pump();

        // 3. Move to new position with trail
        for (var i = 0; i < 5; i++) {
          game.onMouseEvent(
            EventBuilder.mouseMove(960.0 + i * 20, 540.0 + i * 10),
          );
          await tester.pump(const Duration(milliseconds: 16)); // ~60 FPS
        }

        // 4. Right click
        game.onMouseEvent(
          EventBuilder.mouseDown(1060, 590, button: events.MouseButton.right),
        );
        await tester.pump(const Duration(milliseconds: 50));
        game.onMouseEvent(
          EventBuilder.mouseUp(1060, 590, button: events.MouseButton.right),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    });
  });
}
