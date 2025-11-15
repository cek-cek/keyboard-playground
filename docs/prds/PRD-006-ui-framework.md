# PRD-006: UI Framework & Window Management

**Status**: ⚪ Not Started
**Dependencies**: PRD-003 (Build System & CI/CD)
**Estimated Effort**: 8 hours
**Priority**: P0 - CRITICAL
**Branch**: `feature/prd-006-ui-framework`

## Overview

Implement the core UI framework including fullscreen window management, game switching interface, and reusable widget components. This provides the visual shell for all games and user interactions.

## Context

The app needs:
- Fullscreen mode that's hard to exit (uses PRD-005)
- Clean interface for switching between games
- Reusable components for game UIs
- Kid-friendly visual design (high contrast, large targets)
- Responsive layout that adapts to different screen sizes

## Goals

1. ✅ Fullscreen window management across all platforms
2. ✅ Game selection/switching UI
3. ✅ Application shell with consistent layout
4. ✅ Reusable widget library for games
5. ✅ Kid-friendly theme and styling
6. ✅ Screen size/resolution detection

## Non-Goals

- Specific game implementations (that's PRD-009+)
- Input capture (that's PRD-004)
- Exit mechanism UI (that's PRD-005, but we integrate it)

## Requirements

### Functional Requirements

**FR-001**: Fullscreen Window Management
- Launch directly into fullscreen
- Prevent window resize/minimize
- Handle multi-monitor setups (use primary monitor)
- Platform-specific fullscreen APIs

**FR-002**: Application Shell
- AppShell widget that wraps all content
- Persistent overlay for exit progress indicator
- Game content area (fills remaining space)
- Optional overlay menu for game selection

**FR-003**: Game Selection UI
- Trigger via multiple methods:
  - Double-click any screen corner (within 100px radius)
  - Hold Alt+Ctrl+Esc simultaneously for 1 second
- Grid of game cards with icon, name, description
- Large touch targets (minimum 100x100px)
- Full keyboard navigation support (arrow keys to navigate, Enter to select)
- Full mouse support (hover highlighting, click to select)
- Escape or click outside to close without switching
- Visual feedback on corner hover (subtle corner indicator)

**FR-004**: Theme & Styling
- High-contrast color scheme
- Large, readable fonts (minimum 18px)
- Smooth animations (60 FPS)
- Consistent spacing and padding
- Kid-friendly color palette

**FR-005**: Screen Detection
- Get screen dimensions
- Calculate safe areas
- Provide to games and UI components

### Non-Functional Requirements

**NFR-001**: Performance
- Maintain 60 FPS during animations
- Smooth game switching (<100ms)
- No visual glitches

**NFR-002**: Responsiveness
- UI adapts to any screen size (min 1024x768)
- Touch targets sized appropriately
- Keyboard and mouse navigation

**NFR-003**: Accessibility
- High contrast ratios (WCAG AA minimum)
- Keyboard navigation for all functions
- Clear visual feedback

## Technical Specifications

### Architecture

```
AppShell
├── Exit Progress Indicator (overlay, top-right)
├── Game Content Area (fills screen)
│   └── [Current Game Widget]
└── Game Selection Menu (overlay, triggered by gesture)
    └── Grid of Game Cards
```

### Window Management

```dart
// lib/platform/window_control.dart

class WindowControl {
  static const _methodChannel = MethodChannel(
    'com.keyboardplayground/window_control',
  );

  /// Enters fullscreen mode
  static Future<bool> enterFullscreen() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('enterFullscreen');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Exits fullscreen mode
  static Future<bool> exitFullscreen() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('exitFullscreen');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Gets screen dimensions
  static Future<Size> getScreenSize() async {
    try {
      final result = await _methodChannel.invokeMapMethod<String, double>(
        'getScreenSize',
      );
      return Size(
        result?['width'] ?? 1920,
        result?['height'] ?? 1080,
      );
    } catch (e) {
      return const Size(1920, 1080);
    }
  }
}
```

### Platform-specific implementations needed:
- **macOS**: `NSWindow.toggleFullScreen()`, `NSScreen.mainScreen.frame`
- **Linux**: X11 fullscreen, screen dimensions
- **Windows**: Win32 fullscreen, `GetSystemMetrics()`

### Application Shell

```dart
// lib/ui/app_shell.dart

class AppShell extends StatefulWidget {
  final GameManager gameManager;
  final ExitHandler exitHandler;

  const AppShell({
    super.key,
    required this.gameManager,
    required this.exitHandler,
  });

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

  @override
  void initState() {
    super.initState();
    _enterFullscreen();
    _setupListeners();
  }

  Future<void> _enterFullscreen() async {
    await WindowControl.enterFullscreen();
  }

  void _setupListeners() {
    widget.exitHandler.progressStream.listen((progress) {
      setState(() {
        _exitProgress = progress;
      });
    });

    widget.exitHandler.exitTriggered.listen((_) {
      _handleExit();
    });

    _setupGameSelectionGestures();
  }

  void _setupGameSelectionGestures() {
    // Listen for Alt+Ctrl+Esc hold (1 second)
    // Listen for corner double-clicks
  }

  Future<void> _handleExit() async {
    await WindowControl.exitFullscreen();
    // Cleanup
    if (mounted) {
      // Exit app
      ServicesBinding.instance.exitApplication(0);
    }
  }

  void _toggleGameSelection() {
    setState(() {
      _showGameSelection = !_showGameSelection;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.kidFriendlyTheme,
      home: Scaffold(
        body: Stack(
          children: [
            // Game content (fills screen)
            Positioned.fill(
              child: widget.gameManager.currentGame?.buildUI() ??
                  const Center(
                    child: Text(
                      'No game selected',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
            ),

            // Exit progress indicator (top-right overlay)
            ExitProgressIndicator(progress: _exitProgress),

            // Game selection menu (center overlay)
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
      ),
    );
  }
}
```

### Game Selection Menu

```dart
// lib/ui/game_selection_menu.dart

class GameSelectionMenu extends StatefulWidget {
  final GameManager gameManager;
  final void Function(BaseGame) onGameSelected;
  final VoidCallback onClose;

  const GameSelectionMenu({
    super.key,
    required this.gameManager,
    required this.onGameSelected,
    required this.onClose,
  });

  @override
  State<GameSelectionMenu> createState() => _GameSelectionMenuState();
}

class _GameSelectionMenuState extends State<GameSelectionMenu> {
  int _selectedIndex = 0;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final games = widget.gameManager.availableGames;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        setState(() => _selectedIndex = (_selectedIndex - 1) % games.length);
        break;
      case LogicalKeyboardKey.arrowRight:
        setState(() => _selectedIndex = (_selectedIndex + 1) % games.length);
        break;
      case LogicalKeyboardKey.arrowUp:
        // Navigate up in grid (assume 3 columns)
        setState(() => _selectedIndex = (_selectedIndex - 3) % games.length);
        break;
      case LogicalKeyboardKey.arrowDown:
        // Navigate down in grid
        setState(() => _selectedIndex = (_selectedIndex + 3) % games.length);
        break;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.space:
        widget.onGameSelected(games[_selectedIndex]);
        break;
      case LogicalKeyboardKey.escape:
        widget.onClose();
        break;
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
        child: Container(
          color: Colors.black87,
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent closing when clicking on menu
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Choose a Game',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: games.asMap().entries.map((entry) {
                        return GameCard(
                          game: entry.value,
                          isSelected: entry.key == _selectedIndex,
                          onTap: () => widget.onGameSelected(entry.value),
                          onHover: () => setState(() => _selectedIndex = entry.key),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Use arrow keys to navigate, Enter to select, Esc to cancel',
                      style: TextStyle(fontSize: 16, color: Colors.white54),
                    ),
                    const SizedBox(height: 16),
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

class GameCard extends StatefulWidget {
  final BaseGame game;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onHover;

  const GameCard({
    super.key,
    required this.game,
    required this.isSelected,
    required this.onTap,
    required this.onHover,
  });

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = widget.isSelected || _isHovered;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onHover();
      },
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 200,
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isHighlighted
              ? Colors.blue.withOpacity(0.5)
              : Colors.blue.withOpacity(0.3),
            border: Border.all(
              color: isHighlighted ? Colors.blueAccent : Colors.blue,
              width: isHighlighted ? 4 : 2,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // TODO: Add game icon
              Icon(
                Icons.videogame_asset,
                size: isHighlighted ? 72 : 64,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                widget.game.name,
                style: TextStyle(
                  fontSize: isHighlighted ? 22 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.game.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Theme

```dart
// lib/ui/app_theme.dart

class AppTheme {
  static ThemeData get kidFriendlyTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
        primary: Colors.blue,
        secondary: Colors.green,
        surface: Colors.grey[900]!,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: 28),
        bodyLarge: TextStyle(fontSize: 20),
        bodyMedium: TextStyle(fontSize: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(fontSize: 20),
          minimumSize: const Size(100, 60),
        ),
      ),
    );
  }
}
```

### Reusable Widgets Library

```dart
// lib/widgets/big_button.dart
/// Large, kid-friendly button with haptic feedback
class BigButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;

  const BigButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(150, 80),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// lib/widgets/animated_background.dart
/// Animated gradient background for games
class AnimatedBackground extends StatefulWidget {
  final List<Color> colors;
  final Duration duration;

  const AnimatedBackground({
    super.key,
    required this.colors,
    this.duration = const Duration(seconds: 5),
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.colors,
              stops: [
                _controller.value,
                (_controller.value + 0.5) % 1.0,
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## Acceptance Criteria

### Window Management

- [ ] App launches in fullscreen on all platforms
- [ ] Fullscreen cannot be exited except via exit sequence
- [ ] Screen dimensions correctly detected
- [ ] Works on multi-monitor setups (uses primary)

### Application Shell

- [ ] AppShell wraps all content
- [ ] Exit progress indicator displays correctly
- [ ] Game content area fills screen
- [ ] No visual glitches or tearing

### Game Selection

- [ ] Game selection menu triggered by corner double-click (all 4 corners)
- [ ] Game selection menu triggered by Alt+Ctrl+Esc hold (1 second)
- [ ] Visual corner indicators on hover (subtle)
- [ ] All available games displayed as cards
- [ ] Full keyboard navigation (arrow keys to navigate, Enter to select)
- [ ] Full mouse support (hover highlighting, click to select)
- [ ] Selected game highlighted with border and glow
- [ ] Game switching works smoothly
- [ ] Escape or click outside closes menu without switching
- [ ] Help text shown at bottom of menu

### Theme & Styling

- [ ] Kid-friendly colors applied
- [ ] Large fonts throughout
- [ ] High contrast ratios (WCAG AA)
- [ ] Consistent spacing

### Reusable Widgets

- [ ] BigButton widget works
- [ ] AnimatedBackground widget works
- [ ] Other common widgets created

### Testing

- [ ] Widget tests for AppShell
- [ ] Widget tests for GameSelectionMenu
- [ ] Widget tests for all reusable widgets
- [ ] Integration test for game switching
- [ ] Manual testing on all platforms

## Implementation Steps

### Step 1: Window Management (2 hours)

1. Create `lib/platform/window_control.dart`
2. Implement platform channels
3. Implement native code (macOS, Linux, Windows)
4. Test fullscreen on all platforms

### Step 2: Theme & Reusable Widgets (2 hours)

1. Create `lib/ui/app_theme.dart`
2. Create widget library in `lib/widgets/`
3. Widget tests

### Step 3: Application Shell (2 hours)

1. Create `lib/ui/app_shell.dart`
2. Integrate with GameManager (placeholder OK)
3. Integrate with ExitHandler (from PRD-005)
4. Widget tests

### Step 4: Game Selection UI (2 hours)

1. Create `lib/ui/game_selection_menu.dart`
2. Implement gesture detection
3. Implement keyboard navigation
4. Widget tests

## Testing Requirements

### Widget Tests

```dart
// test/widget/ui/app_shell_test.dart
void main() {
  testWidgets('AppShell displays game content', (tester) async {
    // Test app shell renders correctly
  });

  testWidgets('AppShell shows exit progress', (tester) async {
    // Test exit progress indicator
  });
}

// test/widget/ui/game_selection_menu_test.dart
void main() {
  testWidgets('GameSelectionMenu displays games', (tester) async {
    // Test game cards display
  });

  testWidgets('GameSelectionMenu handles selection', (tester) async {
    // Test game selection
  });
}
```

### Manual Testing

- [ ] Launch app, verify fullscreen
- [ ] Try to minimize/resize (should fail)
- [ ] Trigger game selection menu
- [ ] Navigate with keyboard
- [ ] Select different games
- [ ] Test on different screen sizes
- [ ] Test on all platforms

## Definition of Done

- [ ] All acceptance criteria met
- [ ] Works on macOS, Linux, Windows
- [ ] Widget tests pass
- [ ] Integration tests pass
- [ ] Manual testing complete
- [ ] Code review passed
- [ ] DEPENDENCIES.md updated

## Notes for AI Agents

### Key Design Decisions

**Why fullscreen is critical:**
- Prevents accidental window switching
- Creates immersive environment
- Hides desktop distractions

**Why hidden game selection gesture:**
- Prevents kids from accidentally triggering it
- Adults can discover it (documented in docs)

### Time Breakdown

- Window management: 2 hours
- Theme & widgets: 2 hours
- App shell: 2 hours
- Game selection: 2 hours
- **Total**: 8 hours

### Common Issues

- Fullscreen behavior varies by platform
- Need to handle window focus
- Multi-monitor support can be tricky

## References

- Exit handler (PRD-005)
- Game manager (PRD-008)

---

**Can start in parallel with PRD-004, 005, 007 after PRD-003!**
