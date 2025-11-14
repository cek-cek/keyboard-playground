import 'package:flutter/widgets.dart';
import 'package:keyboard_playground/platform/input_events.dart' as events;

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
  /// [event] contains information about the key press/release and modifiers.
  void onKeyEvent(events.KeyEvent event) {
    // Default implementation does nothing
    // Games can override to handle keyboard input
  }

  /// Called when a mouse event occurs.
  ///
  /// [event] can be a mouse move, button, or scroll event.
  void onMouseEvent(events.InputEvent event) {
    // Default implementation does nothing
    // Games can override to handle mouse input
  }

  /// Called when the game is being disposed.
  ///
  /// Clean up any resources here.
  void dispose() {}
}
