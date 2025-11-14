/// Tests for the Exploding Letters game.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyboard_playground/games/exploding_letters/exploding_letters_game.dart';
import 'package:keyboard_playground/platform/input_events.dart';

import '../../test_utils/builders/event_builder.dart';

void main() {
  group('ExplodingLettersGame', () {
    late ExplodingLettersGame game;

    setUp(() {
      game = ExplodingLettersGame();
    });

    tearDown(() {
      game.dispose();
    });

    group('metadata', () {
      test('has correct id', () {
        expect(game.id, equals('exploding_letters'));
      });

      test('has correct name', () {
        expect(game.name, equals('Exploding Letters'));
      });

      test('has correct description', () {
        expect(
            game.description, equals('Letters explode with each key press!'));
      });
    });

    group('buildUI', () {
      testWidgets('returns a valid widget', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: game.buildUI(),
            ),
          ),
        );

        expect(find.byType(Container), findsWidgets);
        expect(find.byType(CustomPaint), findsWidgets);
      });

      testWidgets('has gradient background', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: game.buildUI(),
            ),
          ),
        );

        final container =
            tester.widget<Container>(find.byType(Container).first);
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.gradient, isA<LinearGradient>());
      });
    });

    group('onKeyEvent', () {
      test('creates letter entity on key down', () async {
        // Initially no letters
        expect(game.activeLettersCount, equals(0));

        // Press 'a' key
        final keyEvent = EventBuilder.keyDown('a');
        game.onKeyEvent(keyEvent);

        // Should create one letter
        expect(game.activeLettersCount, equals(1));
      });

      test('ignores key up events', () {
        // Press and release 'a' key
        game.onKeyEvent(EventBuilder.keyDown('a'));
        final initialCount = game.activeLettersCount;

        // Release should not create another letter
        game.onKeyEvent(EventBuilder.keyUp('a'));

        expect(game.activeLettersCount, equals(initialCount));
      });

      test('creates multiple letters for multiple key presses', () {
        // Press multiple keys
        game.onKeyEvent(EventBuilder.keyDown('a'));
        game.onKeyEvent(EventBuilder.keyDown('b'));
        game.onKeyEvent(EventBuilder.keyDown('c'));

        expect(game.activeLettersCount, equals(3));
      });

      test('ignores modifier keys', () {
        // Press modifier keys
        game.onKeyEvent(EventBuilder.keyDown('Shift'));
        game.onKeyEvent(EventBuilder.keyDown('Control'));
        game.onKeyEvent(EventBuilder.keyDown('Alt'));
        game.onKeyEvent(EventBuilder.keyDown('Meta'));

        // Should not create letters for modifiers
        expect(game.activeLettersCount, equals(0));
      });

      test('handles special keys correctly', () {
        // Press space key
        game.onKeyEvent(EventBuilder.keyDown('Space'));
        expect(game.activeLettersCount, equals(1));

        // Press enter key
        game.onKeyEvent(EventBuilder.keyDown('Enter'));
        expect(game.activeLettersCount, equals(2));

        // Press arrow keys
        game.onKeyEvent(EventBuilder.keyDown('ArrowUp'));
        expect(game.activeLettersCount, equals(3));
      });

      test('cleans up old letters after timeout', () async {
        // Create a letter
        game.onKeyEvent(EventBuilder.keyDown('a'));
        expect(game.activeLettersCount, equals(1));

        // Wait for cleanup (3+ seconds)
        await Future<void>.delayed(const Duration(seconds: 4));

        // Letter should be removed
        expect(game.activeLettersCount, equals(0));
      });
    });

    group('LetterEntity', () {
      test('generates particles on creation', () {
        final letter = LetterEntity(
          character: 'A',
          position: const Offset(100, 100),
          color: Colors.red,
          createdAt: DateTime.now(),
        );

        // Should create 25 particles
        expect(letter.particles.length, equals(25));
      });

      test('has correct initial properties', () {
        final position = const Offset(200, 300);
        final color = Colors.blue;
        final character = 'X';

        final letter = LetterEntity(
          character: character,
          position: position,
          color: color,
          createdAt: DateTime.now(),
        );

        expect(letter.character, equals(character));
        expect(letter.position, equals(position));
        expect(letter.color, equals(color));
      });

      test('progress increases over time', () async {
        final letter = LetterEntity(
          character: 'A',
          position: const Offset(100, 100),
          color: Colors.red,
          createdAt: DateTime.now(),
        );

        final initialProgress = letter.getProgress();
        expect(initialProgress, lessThan(0.1));

        // Wait a bit
        await Future<void>.delayed(const Duration(milliseconds: 500));

        final laterProgress = letter.getProgress();
        expect(laterProgress, greaterThan(initialProgress));
        expect(laterProgress, lessThan(1.0));
      });

      test('progress caps at 1.0', () {
        final oldLetter = LetterEntity(
          character: 'A',
          position: const Offset(100, 100),
          color: Colors.red,
          createdAt: DateTime.now().subtract(const Duration(seconds: 10)),
        );

        expect(oldLetter.getProgress(), equals(1.0));
      });
    });

    group('Particle', () {
      test('has correct initial properties', () {
        final position = const Offset(100, 100);
        final velocity = const Offset(50, -50);
        final color = Colors.green;
        const size = 5.0;

        final particle = Particle(
          position: position,
          velocity: velocity,
          color: color,
          size: size,
          createdAt: DateTime.now(),
        );

        expect(particle.position, equals(position));
        expect(particle.velocity, equals(velocity));
        expect(particle.color, equals(color));
        expect(particle.size, equals(size));
      });

      test('position changes with physics over time', () async {
        final particle = Particle(
          position: const Offset(100, 100),
          velocity: const Offset(100, -100), // Moving right and up initially
          color: Colors.red,
          size: 5,
          createdAt: DateTime.now(),
        );

        final initialPosition = particle.getCurrentPosition();

        // Wait long enough for gravity to overcome initial upward velocity
        await Future<void>.delayed(const Duration(milliseconds: 1000));

        final laterPosition = particle.getCurrentPosition();

        // Position should have changed
        expect(laterPosition, isNot(equals(initialPosition)));

        // X should increase (moving right)
        expect(laterPosition.dx, greaterThan(initialPosition.dx));

        // After 1 second, gravity should have pulled particle down below start
        expect(laterPosition.dy, greaterThan(100));
      });

      test('opacity decreases over time', () async {
        final particle = Particle(
          position: const Offset(100, 100),
          velocity: const Offset(50, -50),
          color: Colors.red,
          size: 5,
          createdAt: DateTime.now(),
        );

        final initialOpacity = particle.getOpacity();
        expect(initialOpacity, greaterThan(0.9));

        // Wait a bit
        await Future<void>.delayed(const Duration(milliseconds: 500));

        final laterOpacity = particle.getOpacity();
        expect(laterOpacity, lessThan(initialOpacity));
      });

      test('opacity reaches zero after animation duration', () {
        final oldParticle = Particle(
          position: const Offset(100, 100),
          velocity: const Offset(50, -50),
          color: Colors.red,
          size: 5,
          createdAt: DateTime.now().subtract(const Duration(seconds: 4)),
        );

        expect(oldParticle.getOpacity(), equals(0.0));
      });
    });

    group('ExplodingLettersPainter', () {
      test('can be instantiated', () {
        final painter = ExplodingLettersPainter(letters: []);
        expect(painter, isNotNull);
      });

      test('shouldRepaint always returns true for animations', () {
        final painter1 = ExplodingLettersPainter(letters: []);
        final painter2 = ExplodingLettersPainter(letters: []);

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      testWidgets('renders without errors', (tester) async {
        final letter = LetterEntity(
          character: 'T',
          position: const Offset(100, 100),
          color: Colors.blue,
          createdAt: DateTime.now(),
        );

        final painter = ExplodingLettersPainter(letters: [letter]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: const Size(400, 400),
              ),
            ),
          ),
        );

        // CustomPaint widgets should be found (may be multiple in the tree)
        expect(find.byType(CustomPaint), findsWidgets);
      });
    });

    group('Ticker', () {
      test('starts and stops correctly', () async {
        var tickCount = 0;
        final ticker = Ticker((elapsed) {
          tickCount++;
        });

        ticker.start();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        ticker.stop();

        final countAfterStop = tickCount;
        expect(countAfterStop, greaterThan(0));

        // Wait more, count should not increase
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(tickCount, equals(countAfterStop));
      });

      test('can be started only once', () async {
        var tickCount = 0;
        final ticker = Ticker((elapsed) {
          tickCount++;
        });

        ticker.start();
        ticker.start(); // Second start should be ignored

        await Future<void>.delayed(const Duration(milliseconds: 100));
        ticker.stop();

        // Should have ticked, but not double
        expect(tickCount, greaterThan(0));
      });

      test('dispose stops ticker', () async {
        var tickCount = 0;
        final ticker = Ticker((elapsed) {
          tickCount++;
        });

        ticker.start();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        ticker.dispose();

        final countAfterDispose = tickCount;
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Count should not increase after dispose
        expect(tickCount, equals(countAfterDispose));
      });
    });

    group('game lifecycle', () {
      test('dispose cleans up resources', () {
        final testGame = ExplodingLettersGame();

        // Create some letters
        testGame.onKeyEvent(EventBuilder.keyDown('a'));
        testGame.onKeyEvent(EventBuilder.keyDown('b'));

        // Dispose should not throw
        expect(() => testGame.dispose(), returnsNormally);
      });

      test('can be disposed multiple times safely', () {
        final testGame = ExplodingLettersGame();
        testGame.dispose();

        // Second dispose should not throw
        expect(() => testGame.dispose(), returnsNormally);
      });
    });
  });
}
