/// Keyboard visualizer game that displays real-time keyboard state.
///
/// This game shows a visual representation of a keyboard with keys that
/// highlight when pressed. Different key types (letters, numbers, modifiers)
/// are color-coded for easy identification.
library;
// ignore_for_file: lines_longer_than_80_chars

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

  /// Exposes current key states for testing (read-only copy).
  @visibleForTesting
  Map<String, bool> get keyStates => Map.unmodifiable(_keyStates);

  // No periodic timer needed; UI updates on key events only.

  bool _initialized = false;

  void _ensureFirstFrame() {
    if (_initialized) return;
    _initialized = true;
    // Force a rebuild after first frame to avoid any platform-specific
    // blank surface glitches before first input.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _stateNotifier.value++;
    });
  }

  @override
  String get id => 'keyboard_visualizer';

  @override
  String get name => 'Keyboard Visualizer';

  @override
  String get description => 'Watch your keyboard light up as you type! '
      'See which keys are pressed in real-time.';

  @override
  Widget buildUI() {
    return LayoutBuilder(
      builder: (context, constraints) {
        _ensureFirstFrame();
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final smallHeight = screenHeight < 400;
        final baseUnit = _computeBaseUnitWidth(screenWidth);
        // Compute intrinsic keyboard height (unscaled) for potential scaling.
        final rowCount = KeyboardLayoutWidget._keyboardLayout.length;
        final rowSpacing = baseUnit * 0.16;
        final keyboardPadding = baseUnit * 0.8; // inside container total vertical padding
        final intrinsicKeyboardHeight = rowCount * baseUnit + (rowSpacing * (rowCount - 1)) + keyboardPadding;
        // Overhead (title + top/bottom spacers + legend) approximate and adaptive.
        final titleFontSize = smallHeight ? 28.0 : 48.0;
        final topSpacer = smallHeight ? 12.0 : 24.0;
        final afterTitleSpacer = smallHeight ? 8.0 : 16.0;
        final bottomSpacer = smallHeight ? 12.0 : 24.0;
        // legendHeight previously part of overhead calc; kept commented for reference
        // final legendHeight = smallHeight ? 40.0 : 56.0;
        // overhead previously used for manual scaling; retained for potential future tuning
        // (ignored intentionally)
        // We will fit the keyboard using a FittedBox inside Expanded to avoid overflow.
        final fittedKeyboardHeight = intrinsicKeyboardHeight;
        return Container(
          constraints: const BoxConstraints.expand(),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F172A),
                Color(0xFF1E293B),
              ],
            ),
          ),
          child: RepaintBoundary(
            child: ValueListenableBuilder<int>(
            valueListenable: _stateNotifier,
            builder: (context, _, __) {
              final keyboard = KeyboardLayoutWidget(
                keyStates: _keyStates,
                baseUnit: baseUnit,
              );
              final columnChildren = <Widget>[
                SizedBox(height: topSpacer),
                Text(
                  'Keyboard Visualizer',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: afterTitleSpacer),
                // Scaled keyboard
                SizedBox(
                  height: screenHeight * 0.42, // allocate portion of screen height
                  child: FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: fittedKeyboardHeight,
                      child: keyboard,
                    ),
                  ),
                ),
                SizedBox(height: smallHeight ? 8 : 12),
                _buildLegend(compact: smallHeight),
                SizedBox(height: bottomSpacer),
              ];
              return ListView(
                padding: EdgeInsets.zero,
                children: columnChildren,
              );
            },
          ),
          ),
        );
      },
    );
  }
  double _computeBaseUnitWidth(double screenWidth) {
    const numberRowUnits = 1 + 10 + 1 + 1 + 2; // simplified unit count
    final targetWidth = screenWidth * 0.70; // shrink for test environment to avoid vertical overflow
    final base = targetWidth / (numberRowUnits * 1.15);
    return base.clamp(18.0, 90.0);
  }

  /// Builds the color legend showing key types.
  Widget _buildLegend({bool compact = false}) {
    final spacing = compact ? 12.0 : 24.0;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
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
          SizedBox(width: spacing),
          _buildLegendItem('Numbers', AppTheme.brightGreen),
          SizedBox(width: spacing),
            _buildLegendItem('Modifiers', AppTheme.brightOrange),
          SizedBox(width: spacing),
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
            color: color.withValues(alpha: 0.3),
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
    // Normalize incoming key names to match layout expectations.
    // Native events on Linux emit base modifier names.
    // (Shift, Control, Alt, Meta) layout uses left/right variants.
    // We light both sides for generic modifiers. Letters uppercased.
    final normalized = _normalizeForLayout(event.key);

    if (_isGenericModifier(normalized)) {
      _setKeyState('${normalized}Left', event.isDown);
      _setKeyState('${normalized}Right', event.isDown);
    } else if (normalized == 'ShiftLeft' ||
        normalized == 'ShiftRight' ||
        normalized == 'ControlLeft' ||
        normalized == 'ControlRight' ||
        normalized == 'AltLeft' ||
        normalized == 'AltRight' ||
        normalized == 'MetaLeft' ||
        normalized == 'MetaRight') {
      _setKeyState(normalized, event.isDown);
    } else if (normalized == 'Return') {
      // Map Return to Enter key in layout
      _setKeyState('Enter', event.isDown);
    } else if (normalized == 'Space' || normalized == ' ') {
      // Layout uses a single space character as key identifier
      _setKeyState(' ', event.isDown);
    } else {
      _setKeyState(normalized, event.isDown);
    }

    // Trigger rebuild
    _stateNotifier.value++;
  }

  bool _isGenericModifier(String key) {
    return key == 'Shift' || key == 'Control' || key == 'Alt' || key == 'Meta';
  }

  void _setKeyState(String key, bool isDown) {
    _keyStates[key] = isDown;
  }

  String _normalizeForLayout(String key) {
    if (key.length == 1 && key.toUpperCase() != key.toLowerCase()) {
      return key.toUpperCase();
    }
    return key;
  }

  @override
  void dispose() {
    _stateNotifier.dispose();
    super.dispose();
  }
}

/// Widget that displays a visual keyboard layout.
class KeyboardLayoutWidget extends StatelessWidget {
  /// Creates a keyboard layout widget.
  const KeyboardLayoutWidget({
    required this.keyStates,
    required this.baseUnit,
    super.key,
  });

  /// Current state of all keys (true = pressed, false/absent = released).
  final Map<String, bool> keyStates;

  /// Base unit width for a single standard key.
  final double baseUnit;

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
      // Space key: Uses ' ' (single space) as key name to match input system
      KeyInfo(' ', width: 6.25, label: 'Space'),
      KeyInfo('AltRight', width: 1.25, label: 'Alt'),
      KeyInfo('MetaRight', width: 1.25, label: '⌘'),
      KeyInfo('ContextMenu', width: 1.25, label: '☰'),
      KeyInfo('ControlRight', width: 1.25, label: 'Ctrl'),
    ],
    // Arrow keys row
    [
      // gap spacer to align under right side
      KeyInfo(null, width: 2),
      KeyInfo(
        'ArrowUp',
        width: 1,
        label: '↑',
      ),
      KeyInfo(null, width: 0.5),
      KeyInfo(
        'ArrowLeft',
        width: 1,
        label: '←',
      ),
      KeyInfo(
        'ArrowDown',
        width: 1,
        label: '↓',
      ),
      KeyInfo(
        'ArrowRight',
        width: 1,
        label: '→',
      ),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final keyHeight = baseUnit;
    return Container(
      padding: EdgeInsets.all(baseUnit * 0.4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border.all(
          color: const Color(0xFF475569),
          width: baseUnit * 0.05,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: baseUnit * 0.35,
            spreadRadius: baseUnit * 0.08,
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
                  bottom: i < _keyboardLayout.length - 1 ? keyHeight * 0.16 : 0,
                  top: i == 1 ? keyHeight * 0.16 : 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final keyInfo in _keyboardLayout[i])
                      if (keyInfo.key != null)
                        KeyWidget(
                          keyInfo: keyInfo,
                          isPressed: keyStates[keyInfo.key] ?? false,
                          baseUnit: baseUnit,
                        )
                      else
                        SizedBox(width: keyInfo.width * baseUnit),
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
    required this.baseUnit,
    super.key,
  });

  /// Information about the key to display.
  final KeyInfo keyInfo;

  /// Whether the key is currently pressed.
  final bool isPressed;

  /// Base key size unit.
  final double baseUnit;

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
    final width = baseUnit * keyInfo.width - (baseUnit * 0.06);
    final height = baseUnit;

    return Container(
      width: width,
      height: height,
      margin: EdgeInsets.all(baseUnit * 0.03),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isPressed
              ? color.withValues(alpha: 0.85)
              : const Color(0xFF475569).withValues(alpha: 0.65),
          border: Border.all(
            color: isPressed ? color : color.withValues(alpha: 0.35),
            width: isPressed ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: isPressed
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
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
              // Use smaller font for longer labels to fit within key
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
