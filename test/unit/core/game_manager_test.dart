import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyboard_playground/core/game_manager.dart';
import 'package:keyboard_playground/games/base_game.dart';
import 'package:keyboard_playground/platform/input_events.dart' as events;

/// Mock game for testing.
class MockGame extends BaseGame {
  MockGame({required this.id, this.name = 'Mock Game'});

  @override
  final String id;

  @override
  final String name;

  @override
  String get description => 'A mock game for testing';

  final List<events.KeyEvent> keyEvents = [];
  final List<events.InputEvent> mouseEvents = [];
  bool isDisposed = false;

  @override
  Widget buildUI() {
    return const SizedBox();
  }

  @override
  void onKeyEvent(events.KeyEvent event) {
    keyEvents.add(event);
  }

  @override
  void onMouseEvent(events.InputEvent event) {
    mouseEvents.add(event);
  }

  @override
  void dispose() {
    isDisposed = true;
    super.dispose();
  }
}

void main() {
  group('GameManager', () {
    late GameManager gameManager;

    setUp(() {
      gameManager = GameManager();
    });

    tearDown(() async {
      await gameManager.dispose();
    });

    group('Game Registration', () {
      test('registers a game successfully', () {
        final game = MockGame(id: 'test-game');
        gameManager.registerGame(game);

        expect(gameManager.hasGame('test-game'), isTrue);
        expect(gameManager.availableGames, contains(game));
        expect(gameManager.gameCount, equals(1));
      });

      test('replaces game with same ID when registering', () {
        final game1 = MockGame(id: 'test-game', name: 'Game 1');
        final game2 = MockGame(id: 'test-game', name: 'Game 2');

        gameManager.registerGame(game1);
        gameManager.registerGame(game2);

        expect(gameManager.gameCount, equals(1));
        expect(gameManager.getGame('test-game'), equals(game2));
        expect(game1.isDisposed, isTrue);
      });

      test('can register multiple games', () {
        final game1 = MockGame(id: 'game-1');
        final game2 = MockGame(id: 'game-2');
        final game3 = MockGame(id: 'game-3');

        gameManager.registerGame(game1);
        gameManager.registerGame(game2);
        gameManager.registerGame(game3);

        expect(gameManager.gameCount, equals(3));
        expect(gameManager.hasGames, isTrue);
      });
    });

    group('Game Unregistration', () {
      test('unregisters a game successfully', () {
        final game = MockGame(id: 'test-game');
        gameManager.registerGame(game);

        final result = gameManager.unregisterGame('test-game');

        expect(result, isTrue);
        expect(gameManager.hasGame('test-game'), isFalse);
        expect(gameManager.gameCount, equals(0));
        expect(game.isDisposed, isTrue);
      });

      test('returns false when unregistering non-existent game', () {
        final result = gameManager.unregisterGame('non-existent');

        expect(result, isFalse);
      });

      test('stops current game when unregistering it', () {
        final game = MockGame(id: 'test-game');
        gameManager.registerGame(game);
        gameManager.switchGame('test-game');

        gameManager.unregisterGame('test-game');

        expect(gameManager.currentGame, isNull);
        expect(gameManager.hasCurrentGame, isFalse);
      });
    });

    group('Game Switching', () {
      test('switches to a game successfully', () {
        final game = MockGame(id: 'test-game');
        gameManager.registerGame(game);

        final result = gameManager.switchGame('test-game');

        expect(result, isTrue);
        expect(gameManager.currentGame, equals(game));
        expect(gameManager.hasCurrentGame, isTrue);
      });

      test('returns false when switching to non-existent game', () {
        final result = gameManager.switchGame('non-existent');

        expect(result, isFalse);
        expect(gameManager.currentGame, isNull);
      });

      test('emits game change events', () async {
        final game = MockGame(id: 'test-game');
        gameManager.registerGame(game);

        expectLater(
          gameManager.currentGameStream,
          emitsInOrder([game]),
        );

        gameManager.switchGame('test-game');
      });

      test('switches between games correctly', () {
        final game1 = MockGame(id: 'game-1');
        final game2 = MockGame(id: 'game-2');
        gameManager.registerGame(game1);
        gameManager.registerGame(game2);

        gameManager.switchGame('game-1');
        expect(gameManager.currentGame, equals(game1));

        gameManager.switchGame('game-2');
        expect(gameManager.currentGame, equals(game2));
      });
    });

    group('Current Game Management', () {
      test('stops current game', () {
        final game = MockGame(id: 'test-game');
        gameManager.registerGame(game);
        gameManager.switchGame('test-game');

        gameManager.stopCurrentGame();

        expect(gameManager.currentGame, isNull);
        expect(gameManager.hasCurrentGame, isFalse);
      });

      test('stopping current game emits null to stream', () async {
        final game = MockGame(id: 'test-game');
        gameManager.registerGame(game);
        gameManager.switchGame('test-game');

        expectLater(
          gameManager.currentGameStream,
          emitsInOrder([null]),
        );

        gameManager.stopCurrentGame();
      });

      test('does not dispose game when stopping', () {
        final game = MockGame(id: 'test-game');
        gameManager.registerGame(game);
        gameManager.switchGame('test-game');

        gameManager.stopCurrentGame();

        expect(game.isDisposed, isFalse);
        expect(gameManager.hasGame('test-game'), isTrue);
      });
    });

    group('Event Handling', () {
      test('forwards key events to current game', () {
        final game = MockGame(id: 'test-game');
        gameManager.registerGame(game);
        gameManager.switchGame('test-game');

        final event = events.KeyEvent(
          keyCode: 65,
          key: 'a',
          modifiers: {},
          isDown: true,
          timestamp: DateTime.now(),
        );

        gameManager.handleKeyEvent(event);

        expect(game.keyEvents, contains(event));
        expect(game.keyEvents.length, equals(1));
      });

      test('does nothing when no game is active', () {
        final event = events.KeyEvent(
          keyCode: 65,
          key: 'a',
          modifiers: {},
          isDown: true,
          timestamp: DateTime.now(),
        );

        // Should not throw
        gameManager.handleKeyEvent(event);
      });

      test('forwards mouse button events to current game', () {
        final game = MockGame(id: 'test-game');
        gameManager.registerGame(game);
        gameManager.switchGame('test-game');

        final event = events.MouseButtonEvent(
          button: events.MouseButton.left,
          x: 100,
          y: 200,
          isDown: true,
          timestamp: DateTime.now(),
        );

        gameManager.handleMouseButtonEvent(event);

        expect(game.mouseEvents, contains(event));
        expect(game.mouseEvents.length, equals(1));
      });

      test('forwards mouse move events to current game', () {
        final game = MockGame(id: 'test-game');
        gameManager.registerGame(game);
        gameManager.switchGame('test-game');

        final event = events.MouseMoveEvent(
          x: 150,
          y: 250,
          timestamp: DateTime.now(),
        );

        gameManager.handleMouseMoveEvent(event);

        expect(game.mouseEvents, contains(event));
        expect(game.mouseEvents.length, equals(1));
      });

      test('handleInputEvent routes key events correctly', () {
        final game = MockGame(id: 'test-game');
        gameManager.registerGame(game);
        gameManager.switchGame('test-game');

        final event = events.KeyEvent(
          keyCode: 65,
          key: 'a',
          modifiers: {},
          isDown: true,
          timestamp: DateTime.now(),
        );

        gameManager.handleInputEvent(event);

        expect(game.keyEvents, contains(event));
      });

      test('handleInputEvent routes mouse events correctly', () {
        final game = MockGame(id: 'test-game');
        gameManager.registerGame(game);
        gameManager.switchGame('test-game');

        final moveEvent = events.MouseMoveEvent(
          x: 100,
          y: 200,
          timestamp: DateTime.now(),
        );
        final buttonEvent = events.MouseButtonEvent(
          button: events.MouseButton.left,
          x: 100,
          y: 200,
          isDown: true,
          timestamp: DateTime.now(),
        );
        final scrollEvent = events.MouseScrollEvent(
          deltaX: 10,
          deltaY: 20,
          timestamp: DateTime.now(),
        );

        gameManager.handleInputEvent(moveEvent);
        gameManager.handleInputEvent(buttonEvent);
        gameManager.handleInputEvent(scrollEvent);

        expect(game.mouseEvents.length, equals(3));
      });
    });

    group('Disposal', () {
      test('disposes all registered games', () async {
        final game1 = MockGame(id: 'game-1');
        final game2 = MockGame(id: 'game-2');
        gameManager.registerGame(game1);
        gameManager.registerGame(game2);

        await gameManager.dispose();

        expect(game1.isDisposed, isTrue);
        expect(game2.isDisposed, isTrue);
      });

      test('clears all games after disposal', () async {
        final game = MockGame(id: 'test-game');
        gameManager.registerGame(game);

        await gameManager.dispose();

        expect(gameManager.gameCount, equals(0));
        expect(gameManager.hasGames, isFalse);
      });

      test('clears current game after disposal', () async {
        final game = MockGame(id: 'test-game');
        gameManager.registerGame(game);
        gameManager.switchGame('test-game');

        await gameManager.dispose();

        expect(gameManager.currentGame, isNull);
      });

      test('closes stream after disposal', () async {
        await gameManager.dispose();

        expect(
          gameManager.currentGameStream.isEmpty,
          completion(isTrue),
        );
      });
    });

    group('Queries', () {
      test('getGame returns correct game', () {
        final game = MockGame(id: 'test-game');
        gameManager.registerGame(game);

        final retrieved = gameManager.getGame('test-game');

        expect(retrieved, equals(game));
      });

      test('getGame returns null for non-existent game', () {
        final retrieved = gameManager.getGame('non-existent');

        expect(retrieved, isNull);
      });

      test('hasGame returns correct status', () {
        final game = MockGame(id: 'test-game');
        gameManager.registerGame(game);

        expect(gameManager.hasGame('test-game'), isTrue);
        expect(gameManager.hasGame('other-game'), isFalse);
      });

      test('hasGames returns false initially', () {
        expect(gameManager.hasGames, isFalse);
      });

      test('hasCurrentGame returns false initially', () {
        expect(gameManager.hasCurrentGame, isFalse);
      });
    });
  });
}
