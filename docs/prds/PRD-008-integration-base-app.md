# PRD-008: Integration & Base Application

**Status**: ⚪ Not Started
**Dependencies**: PRD-004, PRD-005, PRD-006, PRD-007 (ALL of Parallel Group 1)
**Estimated Effort**: 8 hours
**Priority**: P0 - CRITICAL
**Branch**: `feature/prd-008-integration-base-app`

## Overview

Integrate all components from Parallel Group 1 into a cohesive, working base application. This creates the complete foundation that games will be built upon. This is where everything comes together for the first time.

## Context

We now have:
- Input capture system (PRD-004)
- Exit mechanism (PRD-005)
- UI framework & window management (PRD-006)
- Testing infrastructure (PRD-007)

This PRD wires them all together and creates a working application that:
- Launches in fullscreen
- Captures all keyboard/mouse input
- Can be exited via the secret sequence
- Has no games yet (that's PRD-009+), but has the game management system
- Is fully tested and documented

## Goals

1. ✅ Complete GameManager implementation
2. ✅ Wire all components together in main.dart
3. ✅ Create first working build that runs
4. ✅ Comprehensive integration tests
5. ✅ User documentation for running the app
6. ✅ Developer documentation for adding games

## Non-Goals

- Implementing actual games (that's PRD-009+)
- Performance optimization (that's PRD-013)
- Polish features (that's PRD-012, 014)

## Requirements

### Functional Requirements

**FR-001**: GameManager Implementation
- Register games
- Switch between games
- Get current game
- List available games
- Notify listeners on game change

**FR-002**: Application Initialization
- Initialize all components in correct order
- Handle permission requests
- Enter fullscreen
- Start input capture
- Show initial state (no game selected message)

**FR-003**: Component Integration
- InputCapture feeds events to ExitHandler
- InputCapture feeds events to current game (when games exist)
- ExitHandler triggers app shutdown
- GameManager switches games smoothly
- UI reflects all state changes

**FR-004**: Error Handling
- Graceful handling of permission denial
- Clear error messages
- Fallback behavior when capture fails
- Logging for debugging

**FR-005**: State Management
- Clean state management pattern (Provider recommended)
- All components properly disposed
- No memory leaks

### Non-Functional Requirements

**NFR-001**: Quality
- All integration tests pass
- End-to-end app flow works
- No crashes or exceptions
- Clean shutdown on exit

**NFR-002**: Documentation
- README updated with run instructions
- Troubleshooting guide created
- Architecture diagram updated
- Code well-commented

**NFR-003**: Developer Experience
- Easy to add new games (documented pattern)
- Clear separation of concerns
- Good error messages

## Technical Specifications

### GameManager Implementation

```dart
// lib/core/game_manager.dart

import 'package:flutter/foundation.dart';
import 'package:keyboard_playground/games/base_game.dart';
import 'package:keyboard_playground/platform/input_events.dart';

/// Manages available games and handles game switching.
class GameManager extends ChangeNotifier {
  final Map<String, BaseGame> _games = {};
  BaseGame? _currentGame;

  /// Currently active game, or null if none selected.
  BaseGame? get currentGame => _currentGame;

  /// List of all available games.
  List<BaseGame> get availableGames => _games.values.toList();

  /// Registers a new game.
  void registerGame(BaseGame game) {
    if (_games.containsKey(game.id)) {
      throw ArgumentError('Game with id ${game.id} already registered');
    }
    _games[game.id] = game;
    notifyListeners();
  }

  /// Switches to a different game by ID.
  bool switchGame(String gameId) {
    final game = _games[gameId];
    if (game == null) {
      debugPrint('Game not found: $gameId');
      return false;
    }

    // Dispose old game if any
    _currentGame?.dispose();

    _currentGame = game;
    notifyListeners();

    debugPrint('Switched to game: ${game.name}');
    return true;
  }

  /// Dispatches a keyboard event to the current game.
  void handleKeyEvent(KeyEvent event) {
    _currentGame?.onKeyEvent(event);
  }

  /// Dispatches a mouse event to the current game.
  void handleMouseEvent(InputEvent event) {
    if (event is MouseMoveEvent ||
        event is MouseButtonEvent ||
        event is MouseScrollEvent) {
      _currentGame?.onMouseEvent(event);
    }
  }

  @override
  void dispose() {
    _currentGame?.dispose();
    for (final game in _games.values) {
      game.dispose();
    }
    super.dispose();
  }
}
```

### Application Initialization

```dart
// lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:keyboard_playground/app.dart';
import 'package:keyboard_playground/core/game_manager.dart';
import 'package:keyboard_playground/core/exit_handler.dart';
import 'package:keyboard_playground/platform/input_capture.dart';
import 'package:keyboard_playground/platform/window_control.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Setup error handling
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

// lib/app.dart (updated from PRD-002)

class KeyboardPlaygroundApp extends StatefulWidget {
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

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Step 1: Initialize components
      _inputCapture = InputCapture();
      _gameManager = GameManager();
      _exitHandler = ExitHandler(inputCapture: _inputCapture);

      // Step 2: Request permissions
      final hasPermissions = await _inputCapture.checkPermissions();
      if (!hasPermissions['accessibility']) {
        debugPrint('Requesting accessibility permissions...');
        await _inputCapture.requestPermissions();

        // Wait a moment for user to grant permissions
        await Future.delayed(const Duration(seconds: 2));

        final recheckPermissions = await _inputCapture.checkPermissions();
        if (!recheckPermissions['accessibility']) {
          setState(() {
            _errorMessage = 'Accessibility permissions required. '
                'Please grant permissions in System Settings.';
          });
          return;
        }
      }

      // Step 3: Enter fullscreen
      final fullscreenSuccess = await WindowControl.enterFullscreen();
      if (!fullscreenSuccess) {
        debugPrint('Warning: Failed to enter fullscreen');
      }

      // Step 4: Start input capture
      final captureSuccess = await _inputCapture.startCapture();
      if (!captureSuccess) {
        setState(() {
          _errorMessage = 'Failed to start input capture. '
              'Check permissions and try again.';
        });
        return;
      }

      // Step 5: Setup event routing
      _setupEventRouting();

      // Step 6: Register games (none yet, but setup the structure)
      // TODO(PRD-009+): Register games here
      // _gameManager.registerGame(ExplodingLettersGame());

      setState(() {
        _isInitialized = true;
      });

      debugPrint('Keyboard Playground initialized successfully!');
    } catch (e, stack) {
      debugPrint('Initialization error: $e');
      debugPrint(stack.toString());
      setState(() {
        _errorMessage = 'Initialization failed: $e';
      });
    }
  }

  void _setupEventRouting() {
    // Route input events to both exit handler and game manager
    _inputCapture.events.listen((event) {
      // Exit handler gets all events (to detect exit sequence)
      // GameManager gets events for current game
      if (event is KeyEvent) {
        _gameManager.handleKeyEvent(event);
      } else {
        _gameManager.handleMouseEvent(event);
      }
    });

    // Listen for exit trigger
    _exitHandler.exitTriggered.listen((_) {
      _handleExit();
    });
  }

  Future<void> _handleExit() async {
    debugPrint('Exit triggered, shutting down...');

    // Stop input capture
    await _inputCapture.stopCapture();

    // Exit fullscreen
    await WindowControl.exitFullscreen();

    // Dispose components
    _exitHandler.dispose();
    _gameManager.dispose();
    await _inputCapture.dispose();

    // Exit app
    if (mounted) {
      SystemNavigator.pop();
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _inputCapture.stopCapture();
      _exitHandler.dispose();
      _gameManager.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Error',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                      _initialize();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 24),
                Text(
                  'Initializing Keyboard Playground...',
                  style: TextStyle(fontSize: 20),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Provide components via Provider for descendant widgets
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _gameManager),
        Provider.value(value: _exitHandler),
        Provider.value(value: _inputCapture),
      ],
      child: MaterialApp(
        title: 'Keyboard Playground',
        theme: AppTheme.kidFriendlyTheme,
        home: AppShell(
          gameManager: _gameManager,
          exitHandler: _exitHandler,
        ),
      ),
    );
  }
}
```

### Placeholder Game (For Testing)

```dart
// lib/games/placeholder_game.dart

import 'package:flutter/material.dart';
import 'package:keyboard_playground/games/base_game.dart';
import 'package:keyboard_playground/platform/input_events.dart';

/// Placeholder game that shows input events (for testing integration).
class PlaceholderGame extends BaseGame {
  final List<String> _recentEvents = [];
  final ValueNotifier<List<String>> _eventsNotifier =
      ValueNotifier<List<String>>([]);

  @override
  String get id => 'placeholder';

  @override
  String get name => 'Input Display';

  @override
  String get description => 'Shows keyboard and mouse events';

  @override
  Widget buildUI() {
    return Container(
      color: Colors.black,
      child: Center(
        child: ValueListenableBuilder<List<String>>(
          valueListenable: _eventsNotifier,
          builder: (context, events, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Keyboard Playground',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Press any key or move the mouse',
                  style: TextStyle(fontSize: 24, color: Colors.white70),
                ),
                const SizedBox(height: 48),
                Container(
                  width: 600,
                  height: 400,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    border: Border.all(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Events:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                events[index],
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: 'Courier',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void onKeyEvent(KeyEvent event) {
    final eventStr = '${event.isDown ? "↓" : "↑"} ${event.key} '
        '${event.modifiers.isNotEmpty ? "(${event.modifiers.join(", ")})" : ""}';

    _recentEvents.insert(0, eventStr);
    if (_recentEvents.length > 20) {
      _recentEvents.removeLast();
    }

    _eventsNotifier.value = List.from(_recentEvents);
  }

  @override
  void onMouseEvent(InputEvent event) {
    String eventStr;

    if (event is MouseMoveEvent) {
      eventStr = '🖱️ Move (${event.x.toInt()}, ${event.y.toInt()})';
    } else if (event is MouseButtonEvent) {
      eventStr = '🖱️ ${event.isDown ? "↓" : "↑"} ${event.button.name} '
          '(${event.x.toInt()}, ${event.y.toInt()})';
    } else if (event is MouseScrollEvent) {
      eventStr = '🖱️ Scroll (Δx: ${event.deltaX}, Δy: ${event.deltaY})';
    } else {
      return;
    }

    _recentEvents.insert(0, eventStr);
    if (_recentEvents.length > 20) {
      _recentEvents.removeLast();
    }

    _eventsNotifier.value = List.from(_recentEvents);
  }

  @override
  void dispose() {
    _eventsNotifier.dispose();
  }
}
```

Update main.dart to register the placeholder game:

```dart
// In _initialize() method, after Step 6:
_gameManager.registerGame(PlaceholderGame());
_gameManager.switchGame('placeholder');  // Start with placeholder
```

## Acceptance Criteria

### Components Integrated

- [ ] GameManager fully implemented
- [ ] main.dart initializes all components correctly
- [ ] Input events route to both ExitHandler and GameManager
- [ ] Exit sequence triggers app shutdown
- [ ] All components dispose cleanly

### Application Works

- [ ] App launches in fullscreen
- [ ] Permission prompt works (macOS)
- [ ] Input capture starts successfully
- [ ] Placeholder game displays and shows events
- [ ] Exit sequence (Alt+Ctrl+Right+Esc+Q) closes app
- [ ] No crashes or exceptions

### Error Handling

- [ ] Permission denial shows error message
- [ ] Input capture failure shows error message
- [ ] Retry button works after error
- [ ] Graceful degradation when possible

### Testing

- [ ] Integration tests pass for full app flow
- [ ] Unit tests for GameManager
- [ ] Manual testing on all platforms
- [ ] No memory leaks verified

### Documentation

- [ ] README updated with:
  - How to run the app
  - How to grant permissions
  - What to expect
  - Exit sequence documentation
- [ ] Troubleshooting guide created
- [ ] Architecture diagram updated
- [ ] Code comments complete

## Implementation Steps

### Step 1: Implement GameManager (2 hours)

1. Create `lib/core/game_manager.dart`
2. Implement all methods
3. Unit tests

### Step 2: Create PlaceholderGame (1 hour)

1. Create `lib/games/placeholder_game.dart`
2. Implement event display
3. Test manually

### Step 3: Update main.dart (2 hours)

1. Implement initialization sequence
2. Wire up all components
3. Add error handling

### Step 4: Integration Testing (2 hours)

1. Write integration tests
2. Test on macOS
3. Test on Linux
4. Test on Windows

### Step 5: Documentation (1 hour)

1. Update README.md
2. Create troubleshooting guide
3. Update architecture docs

## Testing Requirements

### Unit Tests

```dart
// test/unit/core/game_manager_test.dart
void main() {
  group('GameManager', () {
    late GameManager gameManager;

    setUp(() {
      gameManager = GameManager();
    });

    test('registers game successfully', () {
      final game = TestGame();
      gameManager.registerGame(game);

      expect(gameManager.availableGames, contains(game));
    });

    test('switches game correctly', () {
      final game = TestGame();
      gameManager.registerGame(game);

      expect(gameManager.switchGame(game.id), isTrue);
      expect(gameManager.currentGame, equals(game));
    });

    test('routes events to current game', () {
      final game = MockGame();
      gameManager.registerGame(game);
      gameManager.switchGame(game.id);

      final event = EventBuilder.keyDown('A');
      gameManager.handleKeyEvent(event);

      verify(() => game.onKeyEvent(event)).called(1);
    });
  });
}
```

### Integration Tests

```dart
// test/integration/full_app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Full App Integration', () {
    testWidgets('App initializes and runs', (tester) async {
      await tester.pumpWidget(const KeyboardPlaygroundApp());

      // Wait for initialization
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify app loaded
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.text('Keyboard Playground'), findsOneWidget);
    });

    testWidgets('Exit sequence works', (tester) async {
      await tester.pumpWidget(const KeyboardPlaygroundApp());
      await tester.pumpAndSettle();

      // Simulate exit sequence
      // (Implementation depends on test capabilities)

      // Verify app is exiting
    });
  });
}
```

### Manual Testing Checklist

- [ ] **macOS**:
  - [ ] Permission prompt appears
  - [ ] Fullscreen works
  - [ ] Input capture works
  - [ ] Events display in placeholder game
  - [ ] Exit sequence closes app
- [ ] **Linux**:
  - [ ] Same as macOS
- [ ] **Windows**:
  - [ ] Same as macOS

## Definition of Done

- [ ] All acceptance criteria met
- [ ] Works on macOS, Linux, Windows
- [ ] All tests pass
- [ ] Documentation complete
- [ ] Code review passed
- [ ] No memory leaks
- [ ] Clean shutdown verified
- [ ] DEPENDENCIES.md updated
- [ ] PRD-009+ can start immediately

## Notes for AI Agents

### This is a Major Milestone

This PRD completes Phase 1 (Foundation). After this merges, we have a working application! It doesn't have real games yet, but all the hard infrastructure is done.

### Key Integration Points

1. **Initialization Order Matters**:
   - Permissions → Fullscreen → Input Capture → Game Setup

2. **Event Routing**:
   - InputCapture → ExitHandler (always)
   - InputCapture → GameManager → CurrentGame

3. **State Management**:
   - Using Provider for dependency injection
   - ChangeNotifier for reactive state

### Time Breakdown

- GameManager: 2 hours
- PlaceholderGame: 1 hour
- Main integration: 2 hours
- Testing: 2 hours
- Documentation: 1 hour
- **Total**: 8 hours

### Testing Priorities

1. Initialization sequence
2. Event routing
3. Exit sequence
4. Error handling
5. Clean shutdown

### Common Issues

- **Permissions not working**: Check platform-specific permission handling
- **Events not routing**: Check stream subscriptions
- **Memory leaks**: Ensure all `dispose()` called
- **Fullscreen issues**: Platform-specific APIs vary

## References

- PRD-004 (Input Capture)
- PRD-005 (Exit Mechanism)
- PRD-006 (UI Framework)
- PRD-007 (Testing Infrastructure)
- [Provider Package](https://pub.dev/packages/provider)

---

**This is the big integration PRD! After this, we can build games!**
