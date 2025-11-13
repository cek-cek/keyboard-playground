import 'package:flutter/widgets.dart';

/// Base interface for all games in Keyboard Playground.
///
/// Each game should extend this class and implement the required methods.
/// Games will be registered with the game manager and can be switched
/// at runtime.
abstract class BaseGame {
  /// Unique identifier for this game.
  String get id;

  /// Display name for this game.
  String get name;

  /// Short description of what this game does.
  String get description;

  /// Builds the UI for this game.
  Widget buildUI();

  /// Called when a keyboard event occurs.
  ///
  /// This will be implemented in PRD-004 with proper event types.
  void onKeyEvent(/* KeyEvent event */) {
    // TODO(PRD-004): Implement with proper event type
  }

  /// Called when a mouse event occurs.
  ///
  /// This will be implemented in PRD-004 with proper event types.
  void onMouseEvent(/* MouseEvent event */) {
    // TODO(PRD-004): Implement with proper event type
  }

  /// Called when the game is being disposed.
  ///
  /// Clean up any resources here.
  void dispose() {}
}
