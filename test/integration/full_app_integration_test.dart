import 'package:flutter_test/flutter_test.dart';
import 'package:keyboard_playground/core/game_manager.dart';
import 'package:keyboard_playground/games/placeholder_game.dart';
import 'package:keyboard_playground/platform/input_events.dart' as events;

/// Integration tests for the full application flow.
///
/// These tests verify that all components work together correctly:
/// - GameManager
/// - PlaceholderGame
/// - Event routing
/// - Game lifecycle
void main() {
  group('Full Application Integration', () {
    late GameManager gameManager;
    late PlaceholderGame placeholderGame;

    setUp(() {
      gameManager = GameManager();
      placeholderGame = PlaceholderGame();
    });

    tearDown(() async {
      await gameManager.dispose();
    });

    test('can register and switch to placeholder game', () {
      gameManager.registerGame(placeholderGame);

      expect(gameManager.hasGame('placeholder'), isTrue);
      expect(gameManager.gameCount, equals(1));

      final switched = gameManager.switchGame('placeholder');

      expect(switched, isTrue);
      expect(gameManager.currentGame, equals(placeholderGame));
      expect(gameManager.currentGame?.name, equals('Input Display'));
    });

    test('placeholder game receives and processes keyboard events', () {
      gameManager.registerGame(placeholderGame);
      gameManager.switchGame('placeholder');

      // Simulate key press
      final keyDownEvent = events.KeyEvent(
        keyCode: 65,
        key: 'a',
        modifiers: {events.KeyModifier.shift},
        isDown: true,
        timestamp: DateTime.now(),
      );

      gameManager.handleKeyEvent(keyDownEvent);

      // Note: We can't directly test the UI updates without a full widget test,
      // but we can verify the event was processed without errors
      expect(gameManager.currentGame, equals(placeholderGame));
    });

    test('placeholder game receives and processes mouse events', () {
      gameManager.registerGame(placeholderGame);
      gameManager.switchGame('placeholder');

      // Simulate mouse move
      final moveEvent = events.MouseMoveEvent(
        x: 100,
        y: 200,
        timestamp: DateTime.now(),
      );

      gameManager.handleMouseMoveEvent(moveEvent);

      // Simulate mouse click
      final clickEvent = events.MouseButtonEvent(
        button: events.MouseButton.left,
        x: 100,
        y: 200,
        isDown: true,
        timestamp: DateTime.now(),
      );

      gameManager.handleMouseButtonEvent(clickEvent);

      // Verify game is still running
      expect(gameManager.currentGame, equals(placeholderGame));
    });

    test('game manager routes events through handleInputEvent', () {
      gameManager.registerGame(placeholderGame);
      gameManager.switchGame('placeholder');

      // Test various event types
      final eventList = [
        events.KeyEvent(
          keyCode: 65,
          key: 'a',
          modifiers: {},
          isDown: true,
          timestamp: DateTime.now(),
        ),
        events.MouseMoveEvent(
          x: 150,
          y: 250,
          timestamp: DateTime.now(),
        ),
        events.MouseButtonEvent(
          button: events.MouseButton.left,
          x: 150,
          y: 250,
          isDown: true,
          timestamp: DateTime.now(),
        ),
        events.MouseScrollEvent(
          deltaX: 10,
          deltaY: 20,
          timestamp: DateTime.now(),
        ),
      ];

      // Route all events
      for (final event in eventList) {
        gameManager.handleInputEvent(event);
      }

      // Verify game is still running
      expect(gameManager.currentGame, equals(placeholderGame));
    });

    test('can switch away from placeholder game', () {
      // Create a second mock game
      final mockGame = _SimpleMockGame();

      gameManager.registerGame(placeholderGame);
      gameManager.registerGame(mockGame);

      gameManager.switchGame('placeholder');
      expect(gameManager.currentGame, equals(placeholderGame));

      gameManager.switchGame('mock');
      expect(gameManager.currentGame, equals(mockGame));
    });

    test('game lifecycle: register -> switch -> events -> stop -> dispose',
        () async {
      // Register
      gameManager.registerGame(placeholderGame);
      expect(gameManager.hasGame('placeholder'), isTrue);

      // Switch
      final switched = gameManager.switchGame('placeholder');
      expect(switched, isTrue);

      // Send events
      gameManager.handleKeyEvent(
        events.KeyEvent(
          keyCode: 65,
          key: 'a',
          modifiers: {},
          isDown: true,
          timestamp: DateTime.now(),
        ),
      );
      gameManager.handleMouseMoveEvent(
        events.MouseMoveEvent(
          x: 100,
          y: 200,
          timestamp: DateTime.now(),
        ),
      );

      // Stop
      gameManager.stopCurrentGame();
      expect(gameManager.currentGame, isNull);

      // Dispose
      await gameManager.dispose();
      expect(gameManager.gameCount, equals(0));
    });

    test('multiple games can coexist and switch between them', () {
      final game1 = PlaceholderGame();
      final game2 = _SimpleMockGame();

      gameManager.registerGame(game1);
      gameManager.registerGame(game2);

      expect(gameManager.gameCount, equals(2));

      // Switch between games
      gameManager.switchGame('placeholder');
      expect(gameManager.currentGame?.id, equals('placeholder'));

      gameManager.switchGame('mock');
      expect(gameManager.currentGame?.id, equals('mock'));

      gameManager.switchGame('placeholder');
      expect(gameManager.currentGame?.id, equals('placeholder'));
    });

    test('game manager emits game change stream events', () async {
      gameManager.registerGame(placeholderGame);

      // Listen to stream
      final streamEvents = <PlaceholderGame?>[];
      final subscription = gameManager.currentGameStream.listen((game) {
        streamEvents.add(game as PlaceholderGame?);
      });

      // Switch game
      gameManager.switchGame('placeholder');

      // Wait for stream event
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(streamEvents, contains(placeholderGame));

      await subscription.cancel();
    });
  });

  group('PlaceholderGame Standalone', () {
    test('builds UI without errors', () {
      final game = PlaceholderGame();

      expect(() => game.buildUI(), returnsNormally);
      expect(game.buildUI(), isNotNull);

      game.dispose();
    });

    test('has correct metadata', () {
      final game = PlaceholderGame();

      expect(game.id, equals('placeholder'));
      expect(game.name, equals('Input Display'));
      expect(game.description, isNotEmpty);

      game.dispose();
    });

    test('handles events without throwing', () {
      final game = PlaceholderGame();

      expect(
        () => game.onKeyEvent(
          events.KeyEvent(
            keyCode: 65,
            key: 'a',
            modifiers: {},
            isDown: true,
            timestamp: DateTime.now(),
          ),
        ),
        returnsNormally,
      );

      expect(
        () => game.onMouseEvent(
          events.MouseMoveEvent(
            x: 100,
            y: 200,
            timestamp: DateTime.now(),
          ),
        ),
        returnsNormally,
      );

      game.dispose();
    });

    test('disposes without errors', () {
      final game = PlaceholderGame();

      expect(() => game.dispose(), returnsNormally);
    });
  });
}

/// Simple mock game for testing.
class _SimpleMockGame extends PlaceholderGame {
  @override
  String get id => 'mock';

  @override
  String get name => 'Mock Game';

  @override
  String get description => 'A simple mock game';
}
