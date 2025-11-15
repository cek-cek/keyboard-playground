/// Main application shell.
///
/// Provides the core UI structure including fullscreen management, game
/// content area, exit progress indicator, and game selection menu.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keyboard_playground/core/exit_handler.dart';
import 'package:keyboard_playground/core/game_manager.dart';
import 'package:keyboard_playground/games/base_game.dart';
import 'package:keyboard_playground/platform/window_control.dart';
import 'package:keyboard_playground/ui/game_selection_menu.dart';
import 'package:keyboard_playground/widgets/exit_progress_indicator.dart';

/// The main application shell that wraps all content.
///
/// Features:
/// - Fullscreen window management
/// - Game content area
/// - Exit progress indicator overlay
/// - Game selection menu (triggered by gesture)
/// - Handles application lifecycle
///
/// Example usage:
/// ```dart
/// runApp(
///   AppShell(
///     gameManager: gameManager,
///     exitHandler: exitHandler,
///   ),
/// );
/// ```
class AppShell extends StatefulWidget {
  /// Creates the application shell.
  const AppShell({
    required this.gameManager,
    required this.exitHandler,
    super.key,
  });

  /// The game manager for switching games.
  final GameManager gameManager;

  /// The exit handler for tracking exit sequences.
  final ExitHandler exitHandler;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _showGameSelection = false;
  ExitProgress _exitProgress = const ExitProgress(
    currentStep: 0,
    totalSteps: 5,
    remainingTime: Duration(seconds: 5),
    state: ExitSequenceState.idle,
  );

  StreamSubscription<ExitProgress>? _progressSubscription;
  StreamSubscription<void>? _exitSubscription;

  @override
  void initState() {
    super.initState();
    _enterFullscreen();
    _setupListeners();
    _updateScreenSize();
  }

  /// Updates the exit handler with the actual screen size from the platform.
  Future<void> _updateScreenSize() async {
    final screenSize = await WindowControl.getScreenSize();
    widget.exitHandler.updateScreenSize(screenSize.width, screenSize.height);
    debugPrint('Screen size updated: ${screenSize.width}x${screenSize.height}');
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _exitSubscription?.cancel();
    super.dispose();
  }

  /// Enters fullscreen mode.
  Future<void> _enterFullscreen() async {
    try {
      await WindowControl.enterFullscreen();
    } catch (e) {
      // Fullscreen not supported or failed
      debugPrint('Failed to enter fullscreen: $e');
    }
  }

  /// Sets up listeners for exit handler events.
  void _setupListeners() {
    // Listen to exit progress updates
    _progressSubscription =
        widget.exitHandler.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _exitProgress = progress;
        });
      }
    });

    // Listen for exit trigger
    _exitSubscription = widget.exitHandler.exitTriggered.listen((_) {
      _handleExit();
    });
  }

  /// Handles application exit.
  Future<void> _handleExit() async {
    try {
      // Exit fullscreen before closing
      await WindowControl.exitFullscreen();

      // Give a moment for fullscreen to exit
      await Future<void>.delayed(const Duration(milliseconds: 300));

      // Exit the application
      if (mounted) {
        // Use ServicesBinding to exit the app
        await SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');
      }
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      // Force exit if normal exit fails
      if (mounted) {
        await SystemNavigator.pop();
      }
    }
  }

  /// Toggles the game selection menu.
  void _toggleGameSelection() {
    setState(() {
      _showGameSelection = !_showGameSelection;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _buildGameContent()),
          ExitProgressIndicator(progress: _exitProgress),
          if (_showGameSelection)
            GameSelectionMenu(
              gameManager: widget.gameManager,
              onGameSelected: (game) {
                widget.gameManager.switchGame(game.id);
                _toggleGameSelection();
              },
              onClose: _toggleGameSelection,
            ),
        ],
      ),
    );
  }

  /// Builds the game content widget.
  Widget _buildGameContent() {
    // Listen to game changes
    return StreamBuilder<BaseGame?>(
      stream: widget.gameManager.currentGameStream,
      initialData: widget.gameManager.currentGame,
      builder: (context, snapshot) {
        final currentGame = snapshot.data;

        if (currentGame == null) {
          return _buildNoGameScreen();
        }

        // Build the current game's UI
        try {
          return currentGame.buildUI();
        } catch (e) {
          return _buildErrorScreen('Error loading game: $e');
        }
      },
    );
  }

  /// Builds the screen shown when no game is selected.
  Widget _buildNoGameScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A), // Deep blue
            Color(0xFF6366F1), // Bright indigo
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videogame_asset,
              size: 120,
              color: Colors.white70,
            ),
            const SizedBox(height: 32),
            const Text(
              'Keyboard Playground',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No game selected',
              style: TextStyle(
                fontSize: 28,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _toggleGameSelection,
              icon: const Icon(Icons.play_arrow, size: 32),
              label: const Text(
                'Choose a Game',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 24,
                ),
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 96),
            const Text(
              'Tip: Games will automatically fill the screen',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an error screen.
  Widget _buildErrorScreen(String message) {
    return Container(
      color: Colors.red[900],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 120,
                color: Colors.white,
              ),
              const SizedBox(height: 32),
              const Text(
                'Error',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _toggleGameSelection,
                child: const Text(
                  'Choose Another Game',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
