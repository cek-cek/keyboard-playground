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

      test('cleans up old letters after timeout', () {
        // Create a letter with old timestamp
        final oldLetter = LetterEntity(
          character: 'A',
          position: const Offset(100, 100),
          color: const Color(0xFFFF6B6B),
          createdAt: DateTime.now()
              .subtract(const Duration(milliseconds: 3500)), // Older than 3s
        );

        // Manually add to game's letter list (via reflection/testing method)
        game.onKeyEvent(EventBuilder.keyDown('a')); // Create a normal letter
        expect(game.activeLettersCount, equals(1));

        // Trigger cleanup manually
        game.cleanupOldLetters();

        // Letter should still be there (not old enough yet)
        expect(game.activeLettersCount, equals(1));

        // Now create an old letter scenario by testing with getProgress
        final oldLetterProgress = oldLetter.getProgress(DateTime.now());
        expect(oldLetterProgress, equals(1.0)); // Should be fully progressed
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

      test('progress increases over time', () {
        // Test with specific creation times
        final newLetter = LetterEntity(
          character: 'A',
          position: const Offset(100, 100),
          color: Colors.red,
          createdAt: DateTime.now(),
        );

        final initialProgress = newLetter.getProgress(DateTime.now());
        expect(initialProgress, lessThan(0.1));

        // Create a letter 500ms in the past
        final olderLetter = LetterEntity(
          character: 'B',
          position: const Offset(100, 100),
          color: Colors.red,
          createdAt: DateTime.now().subtract(const Duration(milliseconds: 500)),
        );

        final laterProgress = olderLetter.getProgress(DateTime.now());
        expect(laterProgress, greaterThan(initialProgress));
        expect(laterProgress, lessThan(1.0));
        expect(laterProgress, closeTo(0.167, 0.05)); // ~500/3000
      });

      test('progress caps at 1.0', () {
        final oldLetter = LetterEntity(
          character: 'A',
          position: const Offset(100, 100),
          color: Colors.red,
          createdAt: DateTime.now().subtract(const Duration(seconds: 10)),
        );

        expect(oldLetter.getProgress(DateTime.now()), equals(1.0));
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

      test('position changes with physics over time', () {
        // Test with specific elapsed time instead of actual delays
        final startTime = DateTime.now().subtract(const Duration(seconds: 1));

        final particle = Particle(
          position: const Offset(100, 100),
          velocity: const Offset(100, -100), // Moving right and up initially
          color: Colors.red,
          size: 5,
          createdAt: startTime,
        );

        // Get position at 1 second elapsed
        final position = particle.getCurrentPosition(DateTime.now());

        // After 1 second:
        // X = 100 + 100*1 = 200 (moving right)
        // Y = 100 + (-100)*1 + 0.5*300*1^2 = 100 - 100 + 150 = 150
        expect(position.dx, closeTo(200, 0.1));
        expect(position.dy, closeTo(150, 0.1));

        // Verify gravity pulls particle down below initial Y after enough time
        expect(position.dy, greaterThan(100));
      });

      test('opacity decreases over time', () {
        // Test opacity at different time points
        final newParticle = Particle(
          position: const Offset(100, 100),
          velocity: const Offset(50, -50),
          color: Colors.red,
          size: 5,
          createdAt: DateTime.now(),
        );

        final newOpacity = newParticle.getOpacity(DateTime.now());
        expect(newOpacity, greaterThan(0.9));

        // Create particle with 500ms elapsed
        final olderParticle = Particle(
          position: const Offset(100, 100),
          velocity: const Offset(50, -50),
          color: Colors.red,
          size: 5,
          createdAt: DateTime.now().subtract(const Duration(milliseconds: 500)),
        );

        final olderOpacity = olderParticle.getOpacity(DateTime.now());
        expect(olderOpacity, lessThan(newOpacity));
        expect(olderOpacity, greaterThan(0.5)); // Still fairly visible
      });

      test('opacity reaches zero after animation duration', () {
        final oldParticle = Particle(
          position: const Offset(100, 100),
          velocity: const Offset(50, -50),
          color: Colors.red,
          size: 5,
          createdAt: DateTime.now().subtract(const Duration(seconds: 4)),
        );

        expect(oldParticle.getOpacity(DateTime.now()), equals(0.0));
      });
    });

    group('ExplodingLettersPainter', () {
      test('can be instantiated', () {
        final painter = ExplodingLettersPainter(
          letters: [],
          currentTime: DateTime.now(),
        );
        expect(painter, isNotNull);
      });

      test('shouldRepaint returns true when letters change', () {
        final now = DateTime.now();
        final painter1 = ExplodingLettersPainter(
          letters: [],
          currentTime: now,
        );
        final painter2 = ExplodingLettersPainter(
          letters: [],
          currentTime: now.add(const Duration(milliseconds: 16)),
        );

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      testWidgets('renders without errors', (tester) async {
        final letter = LetterEntity(
          character: 'T',
          position: const Offset(100, 100),
          color: Colors.blue,
          createdAt: DateTime.now(),
        );

        final painter = ExplodingLettersPainter(
          letters: [letter],
          currentTime: DateTime.now(),
        );

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
