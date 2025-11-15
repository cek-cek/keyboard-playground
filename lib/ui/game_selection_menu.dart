/// Game selection menu UI.
///
/// Displays available games in a grid layout with large, accessible cards.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keyboard_playground/core/game_manager.dart';
import 'package:keyboard_playground/games/base_game.dart';

/// Overlay menu for selecting games.
///
/// Features:
/// - Semi-transparent dark background
/// - Grid of game cards
/// - Large touch targets
/// - Keyboard navigation support
/// - Close on background tap or Escape key
///
/// Example usage:
/// ```dart
/// if (_showGameSelection) {
///   GameSelectionMenu(
///     gameManager: gameManager,
///     onGameSelected: (game) {
///       gameManager.switchGame(game.id);
///       setState(() => _showGameSelection = false);
///     },
///     onClose: () => setState(() => _showGameSelection = false),
///   )
/// }
/// ```
class GameSelectionMenu extends StatefulWidget {
  /// Creates a game selection menu.
  const GameSelectionMenu({
    required this.gameManager,
    required this.onGameSelected,
    required this.onClose,
    super.key,
  });

  /// The game manager containing available games.
  final GameManager gameManager;

  /// Callback when a game is selected.
  final void Function(BaseGame) onGameSelected;

  /// Callback when the menu is closed without selecting a game.
  final VoidCallback onClose;

  @override
  State<GameSelectionMenu> createState() => _GameSelectionMenuState();
}

class _GameSelectionMenuState extends State<GameSelectionMenu> {
  int _selectedIndex = 0;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // Request focus when menu appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final games = widget.gameManager.availableGames;
    if (games.isEmpty) return;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        setState(() {
          _selectedIndex = (_selectedIndex - 1) % games.length;
          if (_selectedIndex < 0) _selectedIndex = games.length - 1;
        });

      case LogicalKeyboardKey.arrowRight:
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % games.length;
        });

      case LogicalKeyboardKey.arrowUp:
        // Move up one row (assume 3 columns)
        setState(() {
          _selectedIndex = (_selectedIndex - 3) % games.length;
          if (_selectedIndex < 0) _selectedIndex += games.length;
        });

      case LogicalKeyboardKey.arrowDown:
        // Move down one row (assume 3 columns)
        setState(() {
          _selectedIndex = (_selectedIndex + 3) % games.length;
        });

      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.space:
        if (_selectedIndex < games.length) {
          widget.onGameSelected(games[_selectedIndex]);
        }

      case LogicalKeyboardKey.escape:
        widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final games = widget.gameManager.availableGames;

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onClose,
        behavior: HitTestBehavior.opaque,
        child: ColoredBox(
          color: Colors.black87,
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent taps from propagating to background
              child: Container(
                constraints: const BoxConstraints(maxWidth: 900),
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    const Text(
                      'Choose a Game',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Games grid
                    if (games.isEmpty)
                      const Text(
                        'No games available',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white70,
                        ),
                      )
                    else
                      Flexible(
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 24,
                            runSpacing: 24,
                            alignment: WrapAlignment.center,
                            children: games.asMap().entries.map((entry) {
                              final index = entry.key;
                              final game = entry.value;
                              return GameCard(
                                game: game,
                                isSelected: index == _selectedIndex,
                                onTap: () => widget.onGameSelected(game),
                                onHover: (hovering) {
                                  if (hovering) {
                                    setState(() => _selectedIndex = index);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                    const SizedBox(height: 48),

                    // Cancel button
                    TextButton(
                      onPressed: widget.onClose,
                      child: const Text(
                        'Cancel (Esc)',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Card representing a single game in the selection menu.
///
/// Features:
/// - Large size (220x220) for easy tapping
/// - Game icon, name, and description
/// - Hover and selection states
/// - Smooth animations
class GameCard extends StatefulWidget {
  /// Creates a game card.
  const GameCard({
    required this.game,
    required this.onTap,
    this.onHover,
    super.key,
    this.isSelected = false,
  });

  /// The game to display.
  final BaseGame game;

  /// Callback when the card is tapped.
  final VoidCallback onTap;

  /// Callback when hover state changes.
  // ignore: avoid_positional_boolean_parameters
  final void Function(bool hovering)? onHover;

  /// Whether this card is currently selected (for keyboard navigation).
  final bool isSelected;

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = _isHovering || widget.isSelected;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovering = true);
        widget.onHover?.call(true);
      },
      onExit: (_) {
        setState(() => _isHovering = false);
        widget.onHover?.call(false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..scale(
            isHighlighted ? 1.05 : 1.0,
            isHighlighted ? 1.05 : 1.0,
          ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 220,
            height: 220,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? Colors.blue.withOpacity(0.4)
                  : Colors.blue.withOpacity(0.2),
              border: Border.all(
                color: isHighlighted ? Colors.blueAccent : Colors.blue,
                width: isHighlighted ? 4 : 2,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: isHighlighted
                  ? [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Game icon (placeholder for now)
                Icon(
                  Icons.videogame_asset,
                  size: 72,
                  color: isHighlighted ? Colors.white : Colors.white70,
                ),
                const SizedBox(height: 16),

                // Game name
                Text(
                  widget.game.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isHighlighted ? Colors.white : Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Game description
                Flexible(
                  child: Text(
                    widget.game.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isHighlighted ? Colors.white70 : Colors.white60,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
