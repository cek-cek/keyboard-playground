/// Game management system for Keyboard Playground.
///
/// Handles registration, switching, and lifecycle management of games.
library;

import 'dart:async';

import 'package:keyboard_playground/games/base_game.dart';
import 'package:keyboard_playground/platform/input_events.dart';

/// Manages the collection of available games and the current active game.
///
/// Responsibilities:
/// - Register and maintain list of available games
/// - Switch between games
/// - Forward input events to the active game
/// - Manage game lifecycle (initialization, disposal)
///
/// Example usage:
/// ```dart
/// final gameManager = GameManager();
///
/// // Register games
/// gameManager.registerGame(ExplodingLettersGame());
/// gameManager.registerGame(KeyboardVisualizerGame());
///
/// // Switch to a game
/// gameManager.switchGame('exploding_letters');
///
/// // Listen for game changes
/// gameManager.currentGameStream.listen((game) {
///   print('Switched to: ${game?.name}');
/// });
/// ```
class GameManager {
  /// Creates a game manager.
  GameManager();

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

  /// Registers a game to make it available for play.
  ///
  /// If a game with the same ID is already registered, it will be replaced.
  ///
  /// Example:
  /// ```dart
  /// gameManager.registerGame(MyGame());
  /// ```
  void registerGame(BaseGame game) {
    // Dispose old game with same ID if it exists
    if (_games.containsKey(game.id)) {
      _games[game.id]?.dispose();
    }

    _games[game.id] = game;
  }

  /// Unregisters a game by its ID.
  ///
  /// If the game is currently active, it will be stopped first.
  /// Returns true if a game was unregistered, false if no game with that ID
  /// was found.
  bool unregisterGame(String gameId) {
    if (!_games.containsKey(gameId)) {
      return false;
    }

    // If this is the current game, stop it first
    if (_currentGame?.id == gameId) {
      stopCurrentGame();
    }

    // Dispose and remove the game
    _games[gameId]?.dispose();
    _games.remove(gameId);
    return true;
  }

  /// Switches to the game with the given ID.
  ///
  /// If a game is currently active, it will be stopped before switching.
  /// Returns true if the game was successfully switched, false if no game
  /// with that ID exists.
  ///
  /// Example:
  /// ```dart
  /// if (gameManager.switchGame('exploding_letters')) {
  ///   print('Switched to Exploding Letters');
  /// } else {
  ///   print('Game not found');
  /// }
  /// ```
  bool switchGame(String gameId) {
    // Check if game exists
    if (!_games.containsKey(gameId)) {
      return false;
    }

    // Stop current game if any
    if (_currentGame != null) {
      stopCurrentGame();
    }

    // Switch to new game
    _currentGame = _games[gameId];
    _currentGameController.add(_currentGame);

    return true;
  }

  /// Stops the current game and clears the current game state.
  ///
  /// The game remains registered and can be switched to again later.
  void stopCurrentGame() {
    if (_currentGame != null) {
      // Note: We don't dispose the game here since it's still registered
      // and may be played again. Only dispose when unregistering.
      _currentGame = null;
      _currentGameController.add(null);
    }
  }

  /// Gets a game by its ID.
  ///
  /// Returns null if no game with that ID is registered.
  BaseGame? getGame(String gameId) {
    return _games[gameId];
  }

  /// Checks if a game with the given ID is registered.
  bool hasGame(String gameId) {
    return _games.containsKey(gameId);
  }

  /// Forwards a keyboard event to the current game.
  ///
  /// Does nothing if no game is currently active.
  void handleKeyEvent(KeyEvent event) {
    _currentGame?.onKeyEvent(/* event */);
  }

  /// Forwards a mouse button event to the current game.
  ///
  /// Does nothing if no game is currently active.
  void handleMouseButtonEvent(MouseButtonEvent event) {
    _currentGame?.onMouseEvent(/* event */);
  }

  /// Forwards a mouse move event to the current game.
  ///
  /// Does nothing if no game is currently active.
  void handleMouseMoveEvent(MouseMoveEvent event) {
    _currentGame?.onMouseEvent(/* event */);
  }

  /// Disposes of all resources used by the game manager.
  ///
  /// This will dispose of all registered games and close all streams.
  /// After calling dispose, this game manager should not be used.
  Future<void> dispose() async {
    // Dispose all games
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
