import 'package:flutter/material.dart';
import 'package:keyboard_playground/core/exit_handler.dart';
import 'package:keyboard_playground/core/game_manager.dart';
import 'package:keyboard_playground/platform/input_capture.dart';
import 'package:keyboard_playground/ui/app_shell.dart';

void main() {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize input capture
  final inputCapture = InputCapture();

  // Initialize exit handler
  final exitHandler = ExitHandler(
    inputCapture: inputCapture,
  );

  // Initialize game manager
  final gameManager = GameManager();

  // TODO(PRD-008): Register games here when available
  // gameManager.registerGame(ExplodingLettersGame());
  // gameManager.registerGame(KeyboardVisualizerGame());

  // Run the application with AppShell
  runApp(
    AppShell(
      gameManager: gameManager,
      exitHandler: exitHandler,
    ),
  );
}
