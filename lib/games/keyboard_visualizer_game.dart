/// Keyboard visualizer game that displays real-time keyboard state.
///
/// This game shows a visual representation of a keyboard with keys that
/// highlight when pressed. Different key types (letters, numbers, modifiers)
/// are color-coded for easy identification.
library;

import 'package:flutter/material.dart';
import 'package:keyboard_playground/games/base_game.dart';
import 'package:keyboard_playground/platform/input_events.dart' as events;
import 'package:keyboard_playground/ui/app_theme.dart';

/// A game that visualizes keyboard state in real-time.
///
/// Features:
/// - Visual keyboard layout matching physical keyboard
/// - Keys highlight when pressed with glow effect
/// - Different colors for different key types
/// - Supports all modifier keys (Shift, Ctrl, Alt, Meta)
/// - Responsive to rapid key presses
class KeyboardVisualizerGame extends BaseGame {
  /// Creates a new keyboard visualizer game.
  KeyboardVisualizerGame();

  /// Map of key names to their pressed state.
  final Map<String, bool> _keyStates = {};

  /// Notifier for key state changes.
  final ValueNotifier<int> _stateNotifier = ValueNotifier<int>(0);

  @override
  String get id => 'keyboard_visualizer';

  @override
  String get name => 'Keyboard Visualizer';

  @override
  String get description => 'Watch your keyboard light up as you type! '
      'See which keys are pressed in real-time.';

  @override
  Widget buildUI() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A), // Slate 900
            Color(0xFF1E293B), // Slate 800
          ],
        ),
      ),
      child: Center(
        child: ValueListenableBuilder<int>(
          valueListenable: _stateNotifier,
          builder: (context, _, __) {
            return SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),
                  // Title
                  const Text(
                    'Keyboard Visualizer',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Press any key to see it light up!',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Keyboard layout
                  KeyboardLayoutWidget(keyStates: _keyStates),

                  const SizedBox(height: 32),

                  // Legend
                  _buildLegend(),
                  const SizedBox(height: 48),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds the color legend showing key types.
  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white24,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLegendItem('Letters', AppTheme.brightBlue),
          const SizedBox(width: 24),
          _buildLegendItem('Numbers', AppTheme.brightGreen),
          const SizedBox(width: 24),
          _buildLegendItem('Modifiers', AppTheme.brightOrange),
          const SizedBox(width: 24),
          _buildLegendItem('Special', AppTheme.brightPurple),
        ],
      ),
    );
  }

  /// Builds a single legend item.
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  void onKeyEvent(events.KeyEvent event) {
    _keyStates[event.key] = event.isDown;
    _stateNotifier.value++;
  }

  @override
  void dispose() {
    _stateNotifier.dispose();
  }
}

/// Widget that displays a visual keyboard layout.
class KeyboardLayoutWidget extends StatelessWidget {
  /// Creates a keyboard layout widget.
  const KeyboardLayoutWidget({
    required this.keyStates,
    super.key,
  });

  /// Current state of all keys (true = pressed, false/absent = released).
  final Map<String, bool> keyStates;

  /// Keyboard layout organized in rows.
  /// Each row is a list of key definitions.
  static const List<List<KeyInfo>> _keyboardLayout = [
    // Function row
    [
      KeyInfo('Escape', width: 1),
      KeyInfo(null, width: 0.5), // Gap
      KeyInfo('F1', width: 1),
      KeyInfo('F2', width: 1),
      KeyInfo('F3', width: 1),
      KeyInfo('F4', width: 1),
      KeyInfo(null, width: 0.5), // Gap
      KeyInfo('F5', width: 1),
      KeyInfo('F6', width: 1),
      KeyInfo('F7', width: 1),
      KeyInfo('F8', width: 1),
      KeyInfo(null, width: 0.5), // Gap
      KeyInfo('F9', width: 1),
      KeyInfo('F10', width: 1),
      KeyInfo('F11', width: 1),
      KeyInfo('F12', width: 1),
    ],
    // Number row
    [
      KeyInfo('`', width: 1, label: '`'),
      KeyInfo('1', width: 1),
      KeyInfo('2', width: 1),
      KeyInfo('3', width: 1),
      KeyInfo('4', width: 1),
      KeyInfo('5', width: 1),
      KeyInfo('6', width: 1),
      KeyInfo('7', width: 1),
      KeyInfo('8', width: 1),
      KeyInfo('9', width: 1),
      KeyInfo('0', width: 1),
      KeyInfo('-', width: 1),
      KeyInfo('=', width: 1),
      KeyInfo('Backspace', width: 2, label: '⌫'),
    ],
    // QWERTY row
    [
      KeyInfo('Tab', width: 1.5, label: '⇥'),
      KeyInfo('Q', width: 1),
      KeyInfo('W', width: 1),
      KeyInfo('E', width: 1),
      KeyInfo('R', width: 1),
      KeyInfo('T', width: 1),
      KeyInfo('Y', width: 1),
      KeyInfo('U', width: 1),
      KeyInfo('I', width: 1),
      KeyInfo('O', width: 1),
      KeyInfo('P', width: 1),
      KeyInfo('[', width: 1),
      KeyInfo(']', width: 1),
      KeyInfo(r'\', width: 1.5, label: r'\'),
    ],
    // Home row
    [
      KeyInfo('CapsLock', width: 1.75, label: '⇪'),
      KeyInfo('A', width: 1),
      KeyInfo('S', width: 1),
      KeyInfo('D', width: 1),
      KeyInfo('F', width: 1),
      KeyInfo('G', width: 1),
      KeyInfo('H', width: 1),
      KeyInfo('J', width: 1),
      KeyInfo('K', width: 1),
      KeyInfo('L', width: 1),
      KeyInfo(';', width: 1),
      KeyInfo("'", width: 1),
      KeyInfo('Enter', width: 2.25, label: '⏎'),
    ],
    // Bottom row
    [
      KeyInfo('ShiftLeft', width: 2.25, label: '⇧'),
      KeyInfo('Z', width: 1),
      KeyInfo('X', width: 1),
      KeyInfo('C', width: 1),
      KeyInfo('V', width: 1),
      KeyInfo('B', width: 1),
      KeyInfo('N', width: 1),
      KeyInfo('M', width: 1),
      KeyInfo(',', width: 1),
      KeyInfo('.', width: 1),
      KeyInfo('/', width: 1),
      KeyInfo('ShiftRight', width: 2.75, label: '⇧'),
    ],
    // Modifier row
    [
      KeyInfo('ControlLeft', width: 1.25, label: 'Ctrl'),
      KeyInfo('MetaLeft', width: 1.25, label: '⌘'),
      KeyInfo('AltLeft', width: 1.25, label: 'Alt'),
      KeyInfo('Space', width: 6.25, label: 'Space'),
      KeyInfo('AltRight', width: 1.25, label: 'Alt'),
      KeyInfo('MetaRight', width: 1.25, label: '⌘'),
      KeyInfo('ContextMenu', width: 1.25, label: '☰'),
      KeyInfo('ControlRight', width: 1.25, label: 'Ctrl'),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border.all(
          color: const Color(0xFF475569),
          width: 3,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _keyboardLayout.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i < _keyboardLayout.length - 1 ? 8.0 : 0,
                  top: i == 1 ? 8.0 : 0, // Extra space after function row
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final keyInfo in _keyboardLayout[i])
                      if (keyInfo.key != null)
                        KeyWidget(
                          keyInfo: keyInfo,
                          isPressed: keyStates[keyInfo.key] ?? false,
                        )
                      else
                        SizedBox(width: keyInfo.width * 50),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Information about a key in the layout.
class KeyInfo {
  /// Creates a key info object.
  const KeyInfo(
    this.key, {
    required this.width,
    this.label,
  });

  /// The key name (null for gaps).
  final String? key;

  /// Width multiplier (1.0 = standard key width).
  final double width;

  /// Display label (defaults to key name).
  final String? label;

  /// Gets the display label for this key.
  String get displayLabel => label ?? key ?? '';
}

/// Widget that displays a single key.
class KeyWidget extends StatelessWidget {
  /// Creates a key widget.
  const KeyWidget({
    required this.keyInfo,
    required this.isPressed,
    super.key,
  });

  /// Information about the key to display.
  final KeyInfo keyInfo;

  /// Whether the key is currently pressed.
  final bool isPressed;

  /// Gets the color for this key based on its type.
  Color _getKeyColor() {
    final key = keyInfo.key ?? '';

    // Letters (A-Z)
    if (key.length == 1 && key.toUpperCase() != key.toLowerCase()) {
      return AppTheme.brightBlue;
    }

    // Numbers (0-9)
    if (key.length == 1 && int.tryParse(key) != null) {
      return AppTheme.brightGreen;
    }

    // Modifiers (Shift, Ctrl, Alt, Meta, etc.)
    if (key.contains('Shift') ||
        key.contains('Control') ||
        key.contains('Alt') ||
        key.contains('Meta') ||
        key == 'CapsLock') {
      return AppTheme.brightOrange;
    }

    // Special keys (everything else)
    return AppTheme.brightPurple;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getKeyColor();
    const baseWidth = 50.0;
    final width = baseWidth * keyInfo.width - 4; // 4px margin
    const height = 50.0;

    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.all(2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isPressed
              ? color.withOpacity(0.8)
              : const Color(0xFF334155).withOpacity(0.5),
          border: Border.all(
            color: isPressed ? color : color.withOpacity(0.3),
            width: isPressed ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: isPressed
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            keyInfo.displayLabel,
            style: TextStyle(
              // Use a smaller font for longer labels to ensure they fit within the key.
              fontSize: keyInfo.displayLabel.length > 5 ? 12 : 14,
              fontWeight: isPressed ? FontWeight.bold : FontWeight.w500,
              color: isPressed ? Colors.white : Colors.white70,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
