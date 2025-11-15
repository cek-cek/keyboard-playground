# Architecture Overview

This document provides a high-level overview of the Keyboard Playground application architecture, including component interactions, data flow, and key design decisions.

## Table of Contents

- [System Architecture](#system-architecture)
- [Component Diagram](#component-diagram)
- [Layer Breakdown](#layer-breakdown)
- [Data Flow](#data-flow)
- [Platform Channels](#platform-channels)
- [State Management](#state-management)
- [Key Design Decisions](#key-design-decisions)
- [Directory Structure](#directory-structure)

## System Architecture

Keyboard Playground uses a **layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────┐
│                   Presentation Layer                │
│            (Flutter Widgets & UI)                   │
│  • AppShell • GameSelectionMenu • ExitProgress      │
└────────────────────┬────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────┐
│                   Game Layer                        │
│         (Game Implementations)                      │
│  • ExplodingLetters • KeyboardVisualizer            │
│  • MouseVisualizer • BaseGame (interface)           │
└────────────────────┬────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────┐
│                   Core Layer                        │
│         (Business Logic & Management)               │
│  • GameManager • ExitHandler                        │
└────────────────────┬────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────┐
│                  Platform Layer                     │
│        (Platform Channel Abstraction)               │
│  • InputCapture • WindowControl • InputEvents       │
└────────────────────┬────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────┐
│                  Native Layer                       │
│           (Platform-Specific Code)                  │
│  • macOS (Swift) • Linux (C++) • Windows (C++)      │
└─────────────────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────┐
│              Operating System APIs                  │
│  • CGEvent (macOS) • X11 (Linux) • Win32 (Windows)  │
└─────────────────────────────────────────────────────┘
```

## Component Diagram

### Core Components and Their Relationships

```
┌──────────────────────────────────────────────────────────────┐
│                        main.dart                              │
│  (App Entry Point & Initialization)                          │
│                                                               │
│  ┌────────────┐  ┌──────────────┐  ┌────────────────┐       │
│  │ Input      │  │ Game         │  │ Exit           │       │
│  │ Capture    │  │ Manager      │  │ Handler        │       │
│  └─────┬──────┘  └──────┬───────┘  └────────┬───────┘       │
│        │                │                    │               │
└────────┼────────────────┼────────────────────┼───────────────┘
         │                │                    │
         │                │                    │
    ┌────▼────┐      ┌────▼─────┐       ┌─────▼──────┐
    │ Event   │      │ Active   │       │ Exit       │
    │ Stream  │────▶ │ Game     │       │ Sequence   │
    └─────────┘      └──────────┘       │ Tracker    │
                           │             └────────────┘
                           │
                     ┌─────▼──────┐
                     │ Game UI    │
                     │ Widget     │
                     └────────────┘
```

### Component Responsibilities

| Component | Responsibility |
|-----------|---------------|
| **main.dart** | App entry, initialization, error handling, lifecycle management |
| **InputCapture** | Platform channel communication, event stream management |
| **GameManager** | Game registration, switching, event routing to active game |
| **ExitHandler** | Exit sequence tracking (keyboard & mouse), progress notifications |
| **BaseGame** | Abstract interface for all games |
| **Game Implementations** | Specific game logic and UI (ExplodingLetters, etc.) |
| **AppShell** | Main UI container, combines game + UI chrome |
| **WindowControl** | Fullscreen management via platform channels |
| **ExitProgressIndicator** | Visual feedback for exit sequences |

## Layer Breakdown

### 1. Presentation Layer (`lib/ui/`, `lib/widgets/`)

**Purpose**: User interface and visual components

**Key Files**:
- `app_shell.dart` - Main application container
- `app_theme.dart` - Kid-friendly theme definition
- `game_selection_menu.dart` - Game picker (future)
- `widgets/animated_background.dart` - Gradient backgrounds
- `widgets/big_button.dart` - Large touch-friendly buttons
- `widgets/exit_progress_indicator.dart` - Exit sequence visualization

**Technologies**:
- Flutter Material Design 3
- Custom Painters for complex graphics
- ValueNotifier for efficient rebuilds

### 2. Game Layer (`lib/games/`)

**Purpose**: Game implementations and game interface

**Key Files**:
- `base_game.dart` - Abstract game interface
- `exploding_letters/exploding_letters_game.dart` - Particle explosion game
- `keyboard_visualizer_game.dart` - Keyboard state visualization
- `mouse_visualizer_game.dart` - Mouse trail and click visualization
- `placeholder_game.dart` - Simple example game

**Game Interface**:
```dart
abstract class BaseGame {
  String get id;          // Unique identifier
  String get name;        // Display name
  String get description; // Short description
  Widget buildUI();       // Build game UI
  void onKeyEvent(KeyEvent event);     // Handle keyboard
  void onMouseEvent(InputEvent event); // Handle mouse
  void dispose();         // Cleanup
}
```

### 3. Core Layer (`lib/core/`)

**Purpose**: Business logic, game management, exit handling

**Key Files**:
- `game_manager.dart` - Game registry and lifecycle
- `exit_handler.dart` - Exit sequence logic

**GameManager API**:
```dart
class GameManager {
  void registerGame(BaseGame game);
  void switchGame(String gameId);
  void handleInputEvent(InputEvent event);
  BaseGame? get currentGame;
  Stream<BaseGame?> get currentGameStream;
  int get gameCount;
}
```

**ExitHandler Sequences**:
- Keyboard: `Alt` → `Control` → `→` → `Escape` → `Q` (5 steps, 5s timeout)
- Mouse: Click 4 corners clockwise (10s timeout, <50px from corner)

### 4. Platform Layer (`lib/platform/`)

**Purpose**: Abstraction over platform-specific code

**Key Files**:
- `input_capture.dart` - Input capture platform channel interface
- `input_events.dart` - Event type definitions
- `window_control.dart` - Fullscreen platform channel interface

**Platform Channels**:
- `com.keyboardplayground/input_capture` - MethodChannel for control
- `com.keyboardplayground/input_capture/events` - EventChannel for input stream

**InputCapture API**:
```dart
class InputCapture {
  Future<Map<String, bool>> checkPermissions();
  Future<bool> requestPermissions();
  Future<bool> startCapture();
  Future<bool> stopCapture();
  Stream<InputEvent> get events;
}
```

### 5. Native Layer (Platform Directories)

**Purpose**: OS-level input capture and window control

**Platforms**:
- **macOS** (`macos/`) - Swift, uses `CGEvent` API
- **Linux** (`linux/`) - C++, uses X11 libraries
- **Windows** (`windows/`) - C++, uses Win32 `SetWindowsHookEx`

**Platform-Specific APIs**:
```swift
// macOS: CGEventTap
let eventTap = CGEvent.tapCreate(
  tap: .cgSessionEventTap,
  place: .headInsertEventTap,
  options: .defaultTap,
  eventsOfInterest: eventMask,
  callback: handleInputEvent,
  userInfo: nil
)
```

```cpp
// Linux: X11 XGrabKeyboard
XGrabKeyboard(display, window, True, GrabModeAsync, GrabModeAsync, CurrentTime);
XGrabPointer(display, window, True, PointerMotionMask | ButtonPressMask, ...);
```

```cpp
// Windows: SetWindowsHookEx
HHOOK keyboardHook = SetWindowsHookEx(WH_KEYBOARD_LL, KeyboardProc, NULL, 0);
HHOOK mouseHook = SetWindowsHookEx(WH_MOUSE_LL, MouseProc, NULL, 0);
```

## Data Flow

### Input Event Flow

```
1. OS Input Event (key press, mouse move, etc.)
   ↓
2. Native Code Captures Event
   - macOS: CGEventTapCallBack
   - Linux: XGrabKeyboard event handler
   - Windows: SetWindowsHookEx callback
   ↓
3. Convert to Platform Channel Event
   - Create Map with event data
   - Send via EventChannel.sink
   ↓
4. Dart: InputCapture Receives Event
   - Parse Map → InputEvent object
   - Emit on events stream
   ↓
5. GameManager Receives Event
   - Route to active game
   - Route to ExitHandler (parallel)
   ↓
6a. Active Game Processes Event
   - Update game state
   - Trigger UI rebuild
   ↓
6b. ExitHandler Checks Sequence
   - Track exit progress
   - Emit exitTriggered if complete
   ↓
7. UI Updates
   - Game UI reacts to state changes
   - ExitProgressIndicator shows progress
```

### Exit Flow

```
1. User Performs Exit Sequence
   ↓
2. ExitHandler Detects Completion
   - Emits on exitTriggered stream
   ↓
3. main.dart._handleExit() Called
   ↓
4. Graceful Shutdown Sequence:
   a. Cancel event subscriptions
   b. Stop input capture (native)
   c. Dispose game resources
   d. Dispose exit handler
   e. Exit fullscreen
   f. Close application (SystemNavigator.pop)
```

## Platform Channels

### Method Channel (Command/Control)

**Channel**: `com.keyboardplayground/input_capture`

**Methods** (Dart → Native):
```dart
// Check if permissions are granted
Future<Map<String, bool>> checkPermissions()
  Returns: {'accessibility': true, 'x11_record': true, ...}

// Request permissions (shows system dialog)
Future<bool> requestPermissions()
  Returns: true if request initiated

// Start capturing input
Future<bool> startCapture()
  Returns: true if capture started successfully

// Stop capturing input
Future<bool> stopCapture()
  Returns: true if capture stopped successfully
```

### Event Channel (Streaming)

**Channel**: `com.keyboardplayground/input_capture/events`

**Events** (Native → Dart):

**Keyboard Event**:
```json
{
  "type": "keyboard",
  "key": "a",
  "isDown": true,
  "altPressed": false,
  "ctrlPressed": false,
  "shiftPressed": false,
  "metaPressed": false
}
```

**Mouse Move Event**:
```json
{
  "type": "mouse_move",
  "x": 123.45,
  "y": 678.90,
  "deltaX": 5.2,
  "deltaY": -3.1
}
```

**Mouse Button Event**:
```json
{
  "type": "mouse_button",
  "x": 123.45,
  "y": 678.90,
  "button": "left",
  "isDown": true
}
```

**Mouse Scroll Event**:
```json
{
  "type": "mouse_scroll",
  "deltaX": 0,
  "deltaY": -10.5
}
```

## State Management

### Current Approach: Mixed Strategy

1. **ValueNotifier** - For simple reactive state (game updates)
   ```dart
   final ValueNotifier<int> _updateNotifier = ValueNotifier<int>(0);
   // Trigger rebuild:
   _updateNotifier.value++;
   ```

2. **StreamController** - For event streams (game changes, exit events)
   ```dart
   final StreamController<BaseGame?> _gameController =
     StreamController<BaseGame?>.broadcast();
   ```

3. **Direct State** - For simple component state
   ```dart
   bool _isInitialized = false;
   setState(() { _isInitialized = true; });
   ```

### Future Considerations

For more complex games, consider:
- **Provider** package for dependency injection
- **Riverpod** for more powerful state management
- **BLoC** pattern for complex business logic

## Key Design Decisions

### 1. Why Platform Channels?

**Decision**: Use platform channels for input capture instead of pure Dart.

**Rationale**:
- Flutter doesn't provide system-level input capture
- OS-level APIs required for global input interception
- Platform channels allow Dart ↔ Native communication

**Alternatives Considered**:
- ~~Pure Dart~~ - Not possible, Flutter can't capture system input
- ~~Third-party packages~~ - None exist for this use case

### 2. Why Fullscreen Mode?

**Decision**: App must run in fullscreen mode.

**Rationale**:
- Prevents accidental clicks outside app
- Captures all screen space for visual feedback
- Hides system UI (taskbar, menu bar)
- Required for proper input capture on some platforms

### 3. Why Exit Sequences?

**Decision**: Complex exit sequences instead of simple shortcut.

**Rationale**:
- Prevents toddlers from accidentally closing app
- Allows parents/teachers to exit safely
- Two methods (keyboard + mouse) for accessibility

**Implementation**:
- Keyboard: 5 steps, 5 second timeout
- Mouse: 4 corners, 10 second timeout
- Visual progress feedback

### 4. Why BaseGame Interface?

**Decision**: Abstract base class for all games.

**Rationale**:
- Easy to add new games without modifying core
- Clear contract for game implementations
- Supports hot reload during development
- Allows runtime game switching

### 5. Why Material Design 3?

**Decision**: Use Material 3 theme system.

**Rationale**:
- Modern, consistent design language
- Built-in accessibility features
- Excellent color system
- Well-tested across platforms

## Directory Structure

```
keyboard-playground/
├── lib/                        # Dart source code
│   ├── main.dart              # App entry point
│   ├── core/                  # Business logic
│   │   ├── game_manager.dart
│   │   └── exit_handler.dart
│   ├── games/                 # Game implementations
│   │   ├── base_game.dart
│   │   ├── exploding_letters/
│   │   ├── keyboard_visualizer_game.dart
│   │   ├── mouse_visualizer_game.dart
│   │   └── placeholder_game.dart
│   ├── platform/              # Platform abstraction
│   │   ├── input_capture.dart
│   │   ├── input_events.dart
│   │   └── window_control.dart
│   ├── ui/                    # UI components
│   │   ├── app_shell.dart
│   │   ├── app_theme.dart
│   │   └── game_selection_menu.dart
│   └── widgets/               # Reusable widgets
│       ├── animated_background.dart
│       ├── big_button.dart
│       └── exit_progress_indicator.dart
│
├── macos/                     # macOS native code (Swift)
│   └── Runner/
│       └── InputCapturePlugin.swift
│
├── linux/                     # Linux native code (C++)
│   └── input_capture_plugin.cc
│
├── windows/                   # Windows native code (C++)
│   └── input_capture_plugin.cpp
│
├── test/                      # Tests
│   ├── unit/                  # Unit tests
│   ├── widget/                # Widget tests
│   ├── integration/           # Integration tests
│   └── test_utils/            # Test helpers
│
└── docs/                      # Documentation
    ├── architecture/          # Architecture docs
    ├── prds/                  # Product requirements
    └── user/                  # User-facing docs
```

## Performance Considerations

### Target Performance

- **Frame Rate**: 60 FPS (16ms per frame)
- **Input Latency**: <50ms from physical input to visual feedback
- **Memory**: <200 MB RAM usage
- **CPU**: <20% on modern hardware

### Optimization Strategies

1. **Efficient Rendering**:
   - Use `RepaintBoundary` for static elements
   - Custom painters for complex graphics
   - ValueListenableBuilder to rebuild only changed parts

2. **Event Throttling**:
   - Mouse move events can be throttled if needed
   - Game logic runs at 60 FPS max

3. **Object Pooling**:
   - Limit number of active particles/objects
   - Remove old objects regularly
   - Reuse objects when possible

4. **Platform Channel Efficiency**:
   - Event channel uses broadcast stream
   - Single listener per event type
   - Minimal data in events

## Security Considerations

1. **No Network Access**: App doesn't communicate with external services
2. **No File Access**: App doesn't read/write user files
3. **No Data Collection**: No telemetry or analytics
4. **Sandboxed**: Runs in OS security sandbox
5. **Permission Model**: Uses OS-standard permission requests

## Future Architecture Considerations

### Potential Enhancements

1. **Plugin System**: Hot-reload external games
2. **State Persistence**: Save/load game progress
3. **Multi-Window**: Support multiple monitors
4. **Networking**: Multiplayer games (with parental controls)
5. **Accessibility**: Screen reader support, high contrast mode

## Related Documentation

- [Adding Games Guide](adding-games.md) - How to create new games
- [Platform Requirements](platform-requirements.md) - Platform-specific details
- [TDR-001](TDR-001-technology-stack.md) - Technology selection rationale
- [PLAN.md](../../PLAN.md) - Master project plan
- [AGENTS.md](../../AGENTS.md) - AI agent coordination guide

---

**Questions?** Check the [Contributing Guide](../../CONTRIBUTING.md) or open a GitHub Discussion.
