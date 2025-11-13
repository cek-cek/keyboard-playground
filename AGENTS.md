# AI Agent Coordination Guide

This document provides guidance for AI agents working autonomously on the Keyboard Playground project.

## Quick Start for Agents

### 1. Picking Up Work

```bash
# Check what's available
cat DEPENDENCIES.md

# Check what's in progress
git branch -a | grep "feature/prd-"

# Pick an available PRD
# - Must have all dependencies completed
# - Must not already have a branch (check git branches)
# - Prefer lower numbers (PRD-001 before PRD-002)
```

### 2. Starting Work

```bash
# Create feature branch
git checkout -b feature/prd-XXX-short-description

# Read the PRD thoroughly
cat docs/prds/PRD-XXX-*.md

# Check for any prerequisite files/setup
ls -la

# Start implementation
```

### 3. During Development

- **Run tests frequently**: `flutter test`
- **Run linter**: `flutter analyze`
- **Format code**: `dart format .`
- **Commit often**: Small, atomic commits with clear messages
- **Update tests**: Never decrease coverage
- **Document as you go**: Update relevant docs

### 4. Completing Work

```bash
# Final checks
flutter analyze                    # Must pass with 0 issues
flutter test --coverage           # Must maintain >90% coverage
dart format --set-exit-if-changed .  # Must be formatted

# Commit and push
git add .
git commit -m "feat(prd-XXX): Complete [PRD title]"
git push -u origin feature/prd-XXX-short-description

# Create PR (if environment supports it)
# Title: "PRD-XXX: [Title from PRD]"
# Body: Link to PRD, summary of changes, test results
```

## Project Structure Understanding

### Technology Stack

```
Flutter 3.x (Dart)
├── Platform Channels
│   ├── macOS (Swift + Objective-C)
│   ├── Linux (C++ + X11/Wayland)
│   └── Windows (C++ + Win32 API)
├── Testing
│   ├── Unit tests (Dart)
│   ├── Widget tests (Dart)
│   └── Integration tests (Dart)
└── CI/CD
    └── GitHub Actions
```

### Directory Structure

```
keyboard-playground/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── core/                     # Core framework
│   │   ├── input_manager.dart
│   │   ├── game_manager.dart
│   │   └── exit_handler.dart
│   ├── games/                    # Game implementations
│   │   ├── base_game.dart
│   │   ├── exploding_letters/
│   │   └── input_visualizer/
│   ├── platform/                 # Platform channel interfaces
│   │   ├── input_capture.dart
│   │   └── window_control.dart
│   └── widgets/                  # Reusable UI components
│
├── macos/Runner/
│   └── InputCapture.swift        # macOS native code
│
├── linux/
│   └── input_capture.cpp         # Linux native code
│
├── windows/runner/
│   └── input_capture.cpp         # Windows native code
│
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
│
├── docs/
│   ├── prds/                     # Product requirements
│   ├── architecture/             # Technical design
│   └── user/                     # End-user docs
│
└── .github/workflows/            # CI/CD pipelines
```

## Key Architectural Patterns

### 1. Platform Channel Communication

```dart
// Dart side (lib/platform/input_capture.dart)
class InputCapture {
  static const platform = MethodChannel('com.keyboardplayground/input');

  Future<void> startCapture() async {
    await platform.invokeMethod('startCapture');
  }

  Stream<KeyEvent> get keyEvents {
    // Event channel for native -> Dart events
  }
}
```

```swift
// Swift side (macos/Runner/InputCapture.swift)
@objc class InputCapture: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.keyboardplayground/input",
      binaryMessenger: registrar.messenger
    )
    registrar.addMethodCallDelegate(self, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "startCapture" {
      // Use CGEvent APIs to capture keyboard
    }
  }
}
```

### 2. Game Plugin System

All games implement `BaseGame`:

```dart
abstract class BaseGame {
  String get name;
  String get description;
  Widget buildUI();
  void onKeyEvent(KeyEvent event);
  void onMouseEvent(MouseEvent event);
  void dispose();
}
```

Games are registered in `GameManager`:

```dart
class GameManager {
  final Map<String, BaseGame> _games = {};

  void registerGame(BaseGame game) {
    _games[game.name] = game;
  }

  BaseGame? currentGame;

  void switchGame(String name) {
    currentGame = _games[name];
  }
}
```

### 3. Input Event Flow

```
OS → Native Code → Platform Channel → InputManager → GameManager → Current Game
                                                   ↓
                                               ExitHandler (monitors for exit combo)
```

### 4. Testing Strategy

**Unit Tests** (`test/unit/`)
- Pure Dart logic
- No UI dependencies
- Mock platform channels
- Fast, run on every commit

**Widget Tests** (`test/widget/`)
- UI component testing
- Interaction testing
- No platform channel calls (mocked)
- Run on every commit

**Integration Tests** (`test/integration/`)
- End-to-end scenarios
- Real platform channels (or fakes)
- Slower, run on PR
- May be platform-specific

## Common Tasks

### Adding a New Game

1. Create `lib/games/my_game/` directory
2. Implement `MyGame extends BaseGame`
3. Create `test/unit/games/my_game_test.dart`
4. Register in `lib/core/game_manager.dart`
5. Add to game selection UI
6. Document in user docs

### Adding Platform-Specific Code

1. Define interface in `lib/platform/`
2. Implement in `macos/`, `linux/`, `windows/`
3. Register channel in native main file
4. Create platform-specific tests
5. Add CI job for that platform
6. Document platform requirements

### Debugging Platform Channels

```dart
// Enable verbose logging
import 'package:flutter/services.dart';

void main() {
  debugPrint('Starting app...');
  MethodChannel.setMethodCallHandler((call) {
    debugPrint('Method: ${call.method}, Args: ${call.arguments}');
    return Future.value();
  });
  runApp(MyApp());
}
```

### Running Platform-Specific Tests

```bash
# macOS
flutter test --platform darwin

# Linux
flutter test --platform linux

# Windows
flutter test --platform windows

# All platforms (in CI)
flutter test --platform darwin,linux,windows
```

## Development Workflow

### Daily Development Loop

1. **Pull latest**: `git pull origin main`
2. **Create/checkout branch**: `git checkout -b feature/prd-XXX-name`
3. **Make changes**: Edit code
4. **Run tests**: `flutter test` (frequently!)
5. **Format code**: `dart format .`
6. **Commit**: `git commit -m "type(scope): message"`
7. **Push**: `git push`
8. **Repeat**: Steps 3-7 until PRD complete

### Commit Message Convention

```
type(scope): subject

Types:
- feat: New feature (PRD implementation)
- fix: Bug fix
- docs: Documentation only
- style: Formatting, missing semicolons, etc.
- refactor: Code change that neither fixes bug nor adds feature
- test: Adding or updating tests
- chore: Updating build tasks, package manager, etc.

Scope:
- prd-XXX: When implementing a PRD
- input: Input capture system
- games: Game implementations
- ui: User interface
- platform: Platform-specific code
- ci: CI/CD changes

Examples:
- feat(prd-004): Implement macOS keyboard capture
- fix(input): Handle edge case with key repeat
- docs(prd-009): Add game animation documentation
- test(games): Add unit tests for exploding letters
```

### Code Review Checklist

Before marking PRD as complete:

- [ ] All tests pass: `flutter test`
- [ ] No lint warnings: `flutter analyze`
- [ ] Code formatted: `dart format --set-exit-if-changed .`
- [ ] Coverage maintained: `flutter test --coverage` (check coverage report)
- [ ] Documentation updated (inline comments, README changes, etc.)
- [ ] No debug code left in (no `print()`, `debugPrint()` in production code)
- [ ] Platform-specific code tested on target platform
- [ ] PRD acceptance criteria met (check each item in PRD)
- [ ] No new TODOs added without GitHub issue
- [ ] Dependencies updated in pubspec.yaml if needed

## Parallel Development Guidelines

### Avoiding Merge Conflicts

**High Conflict Risk:**
- `lib/main.dart` (coordinate changes)
- `lib/core/game_manager.dart` (coordinate game registration)
- `pubspec.yaml` (coordinate dependency additions)
- CI configuration files

**Low Conflict Risk:**
- New files in `lib/games/`
- Platform-specific code (different OS = different files)
- Test files (if testing different modules)
- Documentation files

### Coordination Strategy

When multiple agents work in parallel:

1. **Claim your PRD**: Create branch immediately to signal work started
2. **Touch only your files**: Stay within PRD scope
3. **Don't refactor shared code**: Unless that's your PRD's goal
4. **Communicate via commits**: Push frequently so others see progress
5. **Rebase often**: `git pull --rebase origin main` to stay current

### Merge Order Matters

If you depend on another PRD:
```bash
# Wait for upstream PRD to merge
git pull origin main

# Rebase your work
git rebase main

# Resolve any conflicts
# Test again!
flutter test

# Push
git push --force-with-lease
```

## Troubleshooting

### "Platform channel not registered"

**Cause**: Native code not properly linked or registered.

**Solution**:
1. Check `macos/Runner/AppDelegate.swift` (or linux/windows equivalent)
2. Ensure plugin is registered: `InputCapturePlugin.register(with: registrar)`
3. Clean and rebuild: `flutter clean && flutter run`

### "Access denied" on keyboard capture

**Cause**: Missing OS permissions.

**Solution**:
- macOS: System Preferences → Security & Privacy → Accessibility
- Linux: User must be in `input` group
- Windows: Run as administrator (first time only)

### Tests passing locally but failing in CI

**Cause**: Platform-specific behavior or missing dependencies.

**Solution**:
1. Check CI logs for exact error
2. Ensure `flutter pub get` ran in CI
3. Check if test uses platform channels (mock in CI)
4. Verify test doesn't depend on local state

### Build failing on specific platform

**Cause**: Platform-specific compilation issue.

**Solution**:
1. Read error message carefully (often points to missing include/import)
2. Check platform-specific dependencies in `macos/`, `linux/`, or `windows/`
3. Ensure platform code follows platform conventions
4. Test locally on that platform if possible

## Best Practices

### Writing Tests

```dart
// Good: Descriptive, focused, independent
test('InputManager emits KeyEvent when key pressed', () {
  final manager = InputManager();
  final events = <KeyEvent>[];

  manager.keyEvents.listen(events.add);
  manager.handlePlatformEvent({'key': 'A', 'action': 'down'});

  expect(events.length, 1);
  expect(events.first.key, 'A');
  expect(events.first.action, KeyAction.down);
});

// Bad: Vague, tests multiple things, depends on previous test
test('test input', () {
  // ... unclear what's being tested
});
```

### Code Organization

```dart
// Good: Single responsibility, clear naming
class KeyboardVisualizer extends BaseGame {
  final KeyboardLayout layout;
  final Map<String, bool> _keyStates = {};

  @override
  void onKeyEvent(KeyEvent event) {
    _keyStates[event.key] = event.isDown;
    notifyListeners();
  }
}

// Bad: God class, unclear responsibilities
class Manager {
  // ... does everything
}
```

### Documentation

```dart
/// Captures keyboard and mouse input at the OS level.
///
/// This class uses platform channels to intercept input events before
/// they reach other applications. Requires accessibility permissions
/// on macOS and Windows.
///
/// Example:
/// ```dart
/// final capture = InputCapture();
/// await capture.start();
/// capture.events.listen((event) => print(event));
/// ```
class InputCapture {
  // ...
}
```

## Platform-Specific Notes

### macOS

- **Language**: Swift (preferred) or Objective-C
- **APIs**: CGEvent for keyboard, NSEvent for mouse
- **Permissions**: Accessibility (prompt user automatically)
- **Fullscreen**: Use `NSWindow` with `styleMask: .fullScreen`
- **Testing**: Can test in simulator

### Linux

- **Language**: C++
- **APIs**: X11 (XGrabKey) or Wayland (libinput)
- **Permissions**: User in `input` group
- **Fullscreen**: X11 fullscreen override redirect
- **Testing**: Requires real Linux environment (Docker works)

### Windows

- **Language**: C++
- **APIs**: SetWindowsHookEx (WH_KEYBOARD_LL, WH_MOUSE_LL)
- **Permissions**: Administrator for first-time hook registration
- **Fullscreen**: Win32 fullscreen mode
- **Testing**: Requires Windows VM or real machine

## Resources

### Flutter Documentation
- Platform Channels: https://docs.flutter.dev/platform-integration/platform-channels
- Desktop: https://docs.flutter.dev/desktop
- Testing: https://docs.flutter.dev/testing

### Platform APIs
- macOS CGEvent: https://developer.apple.com/documentation/coregraphics/cgevent
- Linux X11: https://www.x.org/releases/current/doc/libX11/libX11/libX11.html
- Windows Hooks: https://learn.microsoft.com/en-us/windows/win32/winmsg/hooks

### Project Docs
- PLAN.md: Overall project plan
- DEPENDENCIES.md: PRD execution order
- docs/architecture/: Technical design documents

## Getting Help

If you're stuck:

1. **Read the PRD again**: Ensure you understand requirements
2. **Check existing code**: Look for similar implementations
3. **Review tests**: Tests often clarify expected behavior
4. **Check docs**: Architecture docs explain design decisions
5. **Search issues**: Someone may have faced this before
6. **Ask in PR comments**: Human reviewers can help

## Success Indicators

You're doing well if:
- ✅ Tests pass consistently
- ✅ Commits are small and focused
- ✅ Code is self-documenting with clear names
- ✅ PRD acceptance criteria are met
- ✅ No regression in existing functionality
- ✅ Documentation updated alongside code
- ✅ CI pipeline stays green

Remember: **Quality over speed**. A well-tested, documented PR that takes longer is better than a rushed PR that breaks things.
