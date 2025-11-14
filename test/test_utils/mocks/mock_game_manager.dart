/// Mock implementation of GameManager for testing.
library;

import 'dart:async';

import 'package:keyboard_playground/games/base_game.dart';
import 'package:keyboard_playground/platform/input_events.dart';

/// Mock implementation of GameManager for testing.
///
/// Provides a simplified game manager for testing without requiring actual
/// game implementations.
///
/// Example usage:
/// ```dart
/// final mockManager = MockGameManager();
/// mockManager.registerGame(testGame);
/// mockManager.switchGame(testGame.id);
/// ```
class MockGameManager {
  final Map<String, BaseGame> _games = {};
  BaseGame? _currentGame;

  final StreamController<BaseGame?> _currentGameController =
      StreamController<BaseGame?>.broadcast();

  /// Stream that emits whenever the current game changes.
  Stream<BaseGame?> get currentGameStream => _currentGameController.stream;

  /// The currently active game, or null if no game is active.
  BaseGame? get currentGame => _currentGame;

  /// List of all registered games.
  List<BaseGame> get availableGames => _games.values.toList();

  /// Registers a game.
  void registerGame(BaseGame game) {
    if (_games.containsKey(game.id)) {
      _games[game.id]?.dispose();
    }
    _games[game.id] = game;
  }

  /// Unregisters a game by its ID.
  bool unregisterGame(String gameId) {
    if (!_games.containsKey(gameId)) {
      return false;
    }

    if (_currentGame?.id == gameId) {
      stopCurrentGame();
    }

    _games[gameId]?.dispose();
    _games.remove(gameId);
    return true;
  }

  /// Switches to the game with the given ID.
  bool switchGame(String gameId) {
    if (!_games.containsKey(gameId)) {
      return false;
    }

    if (_currentGame != null) {
      stopCurrentGame();
    }

    _currentGame = _games[gameId];
    _currentGameController.add(_currentGame);

    return true;
  }

  /// Stops the current game.
  void stopCurrentGame() {
    if (_currentGame != null) {
      _currentGame = null;
      _currentGameController.add(null);
    }
  }

  /// Gets a game by its ID.
  BaseGame? getGame(String gameId) {
    return _games[gameId];
  }

  /// Checks if a game with the given ID is registered.
  bool hasGame(String gameId) {
    return _games.containsKey(gameId);
  }

  /// Forwards a keyboard event to the current game.
  void handleKeyEvent(KeyEvent event) {
    // Mock implementation - does nothing
  }

  /// Forwards a mouse button event to the current game.
  void handleMouseButtonEvent(MouseButtonEvent event) {
    // Mock implementation - does nothing
  }

  /// Forwards a mouse move event to the current game.
  void handleMouseMoveEvent(MouseMoveEvent event) {
    // Mock implementation - does nothing
  }

  /// Disposes of all resources.
  Future<void> dispose() async {
    for (final game in _games.values) {
      game.dispose();
    }
    _games.clear();
    _currentGame = null;
    await _currentGameController.close();
  }

  /// Gets the number of registered games.
  int get gameCount => _games.length;

  /// Checks if there are any registered games.
  bool get hasGames => _games.isNotEmpty;

  /// Checks if a game is currently active.
  bool get hasCurrentGame => _currentGame != null;
}
