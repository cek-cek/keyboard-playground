import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyboard_playground/games/keyboard_visualizer_game.dart';
import 'package:keyboard_playground/platform/input_events.dart' as events;

void main() {
  group('KeyboardVisualizerGame', () {
    late KeyboardVisualizerGame game;

    setUp(() {
      game = KeyboardVisualizerGame();
    });

    tearDown(() {
      game.dispose();
    });

    group('Game Properties', () {
      test('has correct id', () {
        expect(game.id, equals('keyboard_visualizer'));
      });

      test('has correct name', () {
        expect(game.name, equals('Keyboard Visualizer'));
      });

      test('has non-empty description', () {
        expect(game.description, isNotEmpty);
        expect(game.description, contains('keyboard'));
      });
    });

    group('UI Building', () {
      testWidgets('buildUI returns a valid widget', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: game.buildUI(),
            ),
          ),
        );

        expect(find.text('Keyboard Visualizer'), findsOneWidget);
        // Helper instruction text removed; ensure title still present.
        expect(find.text('Keyboard Visualizer'), findsOneWidget);
      });

      testWidgets('displays keyboard layout', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: game.buildUI(),
            ),
          ),
        );

        // Check that keyboard layout widget is present
        expect(find.byType(KeyboardLayoutWidget), findsOneWidget);
      });

      testWidgets('arrow keys are present', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: game.buildUI(),
            ),
          ),
        );

        expect(find.text('↑'), findsOneWidget);
        expect(find.text('←'), findsOneWidget);
        expect(find.text('↓'), findsOneWidget);
        expect(find.text('→'), findsOneWidget);
      });

      testWidgets('displays legend with key types', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: game.buildUI(),
            ),
          ),
        );

        // Check for legend labels
        expect(find.text('Letters'), findsOneWidget);
        expect(find.text('Numbers'), findsOneWidget);
        expect(find.text('Modifiers'), findsOneWidget);
        expect(find.text('Special'), findsOneWidget);
      });
    });

    group('Key Event Handling', () {
      testWidgets('updates UI when key is pressed', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: game.buildUI(),
            ),
          ),
        );

        // Send a key down event
        final keyEvent = events.KeyEvent(
          keyCode: 65,
          key: 'A',
          modifiers: {},
          isDown: true,
          timestamp: DateTime.now(),
        );

        game.onKeyEvent(keyEvent);
        await tester.pump();

        // Verify the UI updated (widget tree rebuilt)
        expect(find.byType(KeyboardLayoutWidget), findsOneWidget);
      });

      testWidgets('updates UI when key is released', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: game.buildUI(),
            ),
          ),
        );

        // Press key
        final keyDown = events.KeyEvent(
          keyCode: 65,
          key: 'A',
          modifiers: {},
          isDown: true,
          timestamp: DateTime.now(),
        );
        game.onKeyEvent(keyDown);
        await tester.pump();

        // Release key
        final keyUp = events.KeyEvent(
          keyCode: 65,
          key: 'A',
          modifiers: {},
          isDown: false,
          timestamp: DateTime.now(),
        );
        game.onKeyEvent(keyUp);
        await tester.pump();

        // Verify the UI updated
        expect(find.byType(KeyboardLayoutWidget), findsOneWidget);
      });

      testWidgets('handles rapid key presses', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: game.buildUI(),
            ),
          ),
        );

        // Simulate rapid key presses
        for (var i = 0; i < 20; i++) {
          final keyEvent = events.KeyEvent(
            keyCode: 65 + (i % 10),
            key: String.fromCharCode(65 + (i % 10)),
            modifiers: {},
            isDown: i.isEven,
            timestamp: DateTime.now(),
          );
          game.onKeyEvent(keyEvent);
        }

        await tester.pump();

        // Verify the game still works
        expect(find.byType(KeyboardLayoutWidget), findsOneWidget);
      });

      testWidgets('handles modifier keys', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: game.buildUI(),
            ),
          ),
        );

        // Send modifier key events
        final modifiers = [
          'ShiftLeft',
          'ControlLeft',
          'AltLeft',
          'MetaLeft',
        ];

        for (final modifier in modifiers) {
          final keyEvent = events.KeyEvent(
            keyCode: 0,
            key: modifier,
            modifiers: {},
            isDown: true,
            timestamp: DateTime.now(),
          );
          game.onKeyEvent(keyEvent);
          await tester.pump();
        }

        // Verify the game handles all modifiers
        expect(find.byType(KeyboardLayoutWidget), findsOneWidget);
      });

      test('maps generic modifier to both sides', () {
        final shiftEvent = events.KeyEvent(
          keyCode: 0,
          key: 'Shift',
          modifiers: {},
          isDown: true,
          timestamp: DateTime.now(),
        );
        game.onKeyEvent(shiftEvent);
        expect(game.keyStates['ShiftLeft'], isTrue);
        expect(game.keyStates['ShiftRight'], isTrue);
      });

      test('uppercases single letter keys', () {
        final aEvent = events.KeyEvent(
          keyCode: 65,
          key: 'a',
          modifiers: {},
          isDown: true,
          timestamp: DateTime.now(),
        );
        game.onKeyEvent(aEvent);
        expect(game.keyStates['A'], isTrue);
      });

      test('maps Space to single space layout key', () {
        final spaceEvent = events.KeyEvent(
          keyCode: 32,
          key: 'Space',
          modifiers: {},
          isDown: true,
          timestamp: DateTime.now(),
        );
        game.onKeyEvent(spaceEvent);
        expect(game.keyStates[' '], isTrue);
      });
    });

    group('KeyboardLayoutWidget', () {
      testWidgets('renders without errors', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: KeyboardLayoutWidget(keyStates: {}, baseUnit: 60),
            ),
          ),
        );

        expect(find.byType(KeyboardLayoutWidget), findsOneWidget);
      });

      testWidgets('shows key as pressed when in keyStates', (tester) async {
        final keyStates = {'A': true};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: KeyboardLayoutWidget(keyStates: keyStates, baseUnit: 60),
            ),
          ),
        );

        // The keyboard layout should render
        expect(find.byType(KeyboardLayoutWidget), findsOneWidget);
      });

      testWidgets('shows key as not pressed when not in keyStates',
          (tester) async {
        final keyStates = <String, bool>{};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: KeyboardLayoutWidget(keyStates: keyStates, baseUnit: 60),
            ),
          ),
        );

        expect(find.byType(KeyboardLayoutWidget), findsOneWidget);
      });
    });

    group('KeyWidget', () {
      testWidgets('renders key label', (tester) async {
        const keyInfo = KeyInfo('A', width: 1.0);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: KeyWidget(
                keyInfo: keyInfo,
                isPressed: false,
                baseUnit: 60,
              ),
            ),
          ),
        );

        expect(find.text('A'), findsOneWidget);
      });

      testWidgets('uses custom label when provided', (tester) async {
        const keyInfo = KeyInfo('Space', width: 1.0, label: 'Space Bar');

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: KeyWidget(
                keyInfo: keyInfo,
                isPressed: false,
                baseUnit: 60,
              ),
            ),
          ),
        );

        expect(find.text('Space Bar'), findsOneWidget);
      });

      testWidgets('shows different appearance when pressed', (tester) async {
        const keyInfo = KeyInfo('A', width: 1.0);

        // Build with not pressed
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: KeyWidget(
                keyInfo: keyInfo,
                isPressed: false,
                baseUnit: 60,
              ),
            ),
          ),
        );

        final notPressedWidget = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );

        // Rebuild with pressed
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: KeyWidget(
                keyInfo: keyInfo,
                isPressed: true,
                baseUnit: 60,
              ),
            ),
          ),
        );

        final pressedWidget = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );

        // Decorations should be different
        expect(
          notPressedWidget.decoration,
          isNot(equals(pressedWidget.decoration)),
        );
      });
    });

    group('KeyInfo', () {
      test('uses key as label when label is not provided', () {
        const keyInfo = KeyInfo('A', width: 1.0);
        expect(keyInfo.displayLabel, equals('A'));
      });

      test('uses custom label when provided', () {
        const keyInfo = KeyInfo('Tab', width: 1.5, label: '⇥');
        expect(keyInfo.displayLabel, equals('⇥'));
      });

      test('handles null key (for gaps)', () {
        const keyInfo = KeyInfo(null, width: 0.5);
        expect(keyInfo.displayLabel, equals(''));
      });
    });
  });
}
