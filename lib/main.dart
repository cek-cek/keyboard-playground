import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keyboard_playground/core/exit_handler.dart';
import 'package:keyboard_playground/core/game_manager.dart';
import 'package:keyboard_playground/games/mouse_visualizer_game.dart';
import 'package:keyboard_playground/games/placeholder_game.dart';
import 'package:keyboard_playground/platform/input_capture.dart';
import 'package:keyboard_playground/platform/window_control.dart';
import 'package:keyboard_playground/ui/app_shell.dart';
import 'package:keyboard_playground/ui/app_theme.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Setup global error handling
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint(details.stack.toString());
  };

  // Run app with error zone
  runZonedGuarded(
    () => runApp(const KeyboardPlaygroundApp()),
    (error, stack) {
      debugPrint('Uncaught Error: $error');
      debugPrint(stack.toString());
    },
  );
}

/// The main application widget that handles initialization and lifecycle.
class KeyboardPlaygroundApp extends StatefulWidget {
  /// Creates the main application.
  const KeyboardPlaygroundApp({super.key});

  @override
  State<KeyboardPlaygroundApp> createState() => _KeyboardPlaygroundAppState();
}

class _KeyboardPlaygroundAppState extends State<KeyboardPlaygroundApp> {
  late final InputCapture _inputCapture;
  late final GameManager _gameManager;
  late final ExitHandler _exitHandler;

  bool _isInitialized = false;
  String? _errorMessage;
  StreamSubscription<void>? _exitSubscription;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      debugPrint('=== Keyboard Playground Initialization ===');

      // Step 1: Initialize core components
      debugPrint('Step 1: Initializing core components...');
      _inputCapture = InputCapture();
      _gameManager = GameManager();
      _exitHandler = ExitHandler(inputCapture: _inputCapture);

      // Step 2: Check and request permissions
      debugPrint('Step 2: Checking permissions...');
      final hasPermissions = await _inputCapture.checkPermissions();
      debugPrint('Permissions status: $hasPermissions');

      if (!hasPermissions['accessibility']!) {
        debugPrint('Requesting accessibility permissions...');
        await _inputCapture.requestPermissions();

        // Wait a moment for user to grant permissions
        await Future<void>.delayed(const Duration(seconds: 2));

        final recheckPermissions = await _inputCapture.checkPermissions();
        if (!recheckPermissions['accessibility']!) {
          setState(() {
            _errorMessage = 'Accessibility permissions required.\n\n'
                'Please grant permissions in System Settings and restart.';
          });
          return;
        }
      }

      // Step 3: Enter fullscreen
      debugPrint('Step 3: Entering fullscreen...');
      final fullscreenSuccess = await WindowControl.enterFullscreen();
      if (!fullscreenSuccess) {
        debugPrint(
          'Warning: Failed to enter fullscreen (may not be supported)',
        );
      }

      // Step 4: Start input capture
      debugPrint('Step 4: Starting input capture...');
      final captureSuccess = await _inputCapture.startCapture();
      if (!captureSuccess) {
        setState(() {
          _errorMessage = 'Failed to start input capture.\n\n'
              'Check permissions and try again.';
        });
        return;
      }

      // Step 5: Setup event routing
      debugPrint('Step 5: Setting up event routing...');
      _setupEventRouting();

      // Step 6: Register games
      debugPrint('Step 6: Registering games...');
      _gameManager
        ..registerGame(PlaceholderGame())
        ..registerGame(MouseVisualizerGame())
        ..switchGame('mouse_visualizer');

      // TODO(PRD-009): Register additional games here
      // _gameManager.registerGame(ExplodingLettersGame());
      // _gameManager.registerGame(KeyboardVisualizerGame());

      setState(() {
        _isInitialized = true;
      });

      debugPrint('=== Initialization Complete! ===');
      debugPrint('Available games: ${_gameManager.gameCount}');
      debugPrint('Current game: ${_gameManager.currentGame?.name}');
    } catch (e, stack) {
      debugPrint('Initialization error: $e');
      debugPrint(stack.toString());
      setState(() {
        _errorMessage = 'Initialization failed:\n\n$e';
      });
    }
  }

  void _setupEventRouting() {
    // Route all input events to the game manager
    _inputCapture.events.listen((event) {
      _gameManager.handleInputEvent(event);
    });

    // Listen for exit trigger
    _exitSubscription = _exitHandler.exitTriggered.listen((_) {
      _handleExit();
    });
  }

  Future<void> _handleExit() async {
    debugPrint('Exit triggered, shutting down...');

    try {
      // Stop input capture
      await _inputCapture.stopCapture();

      // Exit fullscreen
      await WindowControl.exitFullscreen();

      // Give a moment for cleanup
      await Future<void>.delayed(const Duration(milliseconds: 300));

      // Exit app
      if (mounted) {
        await SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');
      }
    } catch (e) {
      debugPrint('Error during exit: $e');
      // Force exit
      if (mounted) {
        await SystemNavigator.pop();
      }
    }
  }

  @override
  void dispose() {
    _exitSubscription?.cancel();
    if (_isInitialized) {
      _inputCapture.stopCapture();
      _gameManager.dispose();
      _exitHandler.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Error state
    if (_errorMessage != null) {
      return MaterialApp(
        title: 'Keyboard Playground',
        theme: AppTheme.kidFriendlyTheme,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF7F1D1D), // Red 900
                  Color(0xFFB91C1C), // Red 700
                ],
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Initialization Error',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _isInitialized = false;
                        });
                        _initialize();
                      },
                      icon: const Icon(Icons.refresh, size: 24),
                      label: const Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFB91C1C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Loading state
    if (!_isInitialized) {
      return MaterialApp(
        title: 'Keyboard Playground',
        theme: AppTheme.kidFriendlyTheme,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E3A8A), // Blue 900
                  Color(0xFF3B82F6), // Blue 500
                ],
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      strokeWidth: 6,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(height: 32),
                  Text(
                    'Initializing Keyboard Playground...',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Please wait',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Main app
    return MaterialApp(
      title: 'Keyboard Playground',
      theme: AppTheme.kidFriendlyTheme,
      debugShowCheckedModeBanner: false,
      home: AppShell(
        gameManager: _gameManager,
        exitHandler: _exitHandler,
      ),
    );
  }
}
