COMPREHENSIVE ANALYSIS OF KEYBOARD-PLAYGROUND FLUTTER PROJECT
==============================================================

PROJECT OVERVIEW
================
Name: Keyboard Playground
Description: A safe, entertaining desktop application for young children to explore keyboard and mouse input without triggering system actions
Version: 0.1.0+1
Technology: Flutter 3.24+ (Dart)
Target Platforms: macOS, Linux, Windows
License: MIT

1. PROJECT STRUCTURE
====================

Root Level Organization:
├── AGENTS.md (AI coordination guide)
├── CONTRIBUTING.md (developer guidelines)
├── DEPENDENCIES.md (PRD execution graph)
├── PLAN.md (master project plan)
├── Makefile (development commands)
├── analysis_options.yaml (linting rules)
├── pubspec.yaml (dependencies)
├── .github/workflows/ (CI/CD pipelines)
├── .vscode/ (editor configuration)
├── .claude/ (Claude Code session setup)
├── docs/ (documentation)
└── lib/, test/, linux/, macos/, windows/ (source)

Dart Source Code Structure (lib/):
├── main.dart (app entry point, initialization)
├── app.dart (deprecated root widget - main.dart is active)
├── core/
│   ├── game_manager.dart (manages game lifecycle and switching)
│   └── exit_handler.dart (handles exit sequence logic)
├── games/
│   ├── base_game.dart (abstract base class for all games)
│   └── placeholder_game.dart (example implementation)
├── platform/
│   ├── input_capture.dart (platform channel interface)
│   ├── input_events.dart (event type definitions)
│   └── window_control.dart (fullscreen control)
├── ui/
│   ├── app_theme.dart (kid-friendly theme definition)
│   ├── app_shell.dart (main UI container)
│   └── game_selection_menu.dart (game picker UI)
└── widgets/
    ├── animated_background.dart (gradient background)
    ├── big_button.dart (large touchable button)
    └── exit_progress_indicator.dart (exit sequence progress)

Test Structure (test/):
├── unit/ (pure Dart tests)
│   ├── core/
│   ├── platform/
│   └── test_utils/
├── widget/ (Flutter widget tests)
│   ├── ui/
│   └── widgets/
├── integration/ (end-to-end tests)
├── test_utils/ (testing infrastructure)
│   ├── builders/
│   ├── helpers/
│   ├── matchers/
│   └── mocks/
├── golden/ (golden file tests)
└── fixtures/ (test data)

Statistics:
- Total Dart code: ~3,227 lines
- Main classes: ~38
- Test files: 13

2. TECHNOLOGY STACK
===================

Framework & Language:
- Flutter: 3.24.x (stable)
- Dart: 3.2.0+ (bundled with Flutter)
- SDK Target: Dart >=3.2.0 <4.0.0

Core Dependencies:
- collection: ^1.18.0 (utility functions)
- equatable: ^2.0.5 (value equality)
- provider: ^6.1.0 (state management)

Dev Dependencies:
- flutter_test (unit and widget testing)
- flutter_lints: ^3.0.0 (official lints)
- very_good_analysis: ^5.1.0 (strict additional lints)
- mocktail: ^1.0.0 (mocking for tests)
- test: ^1.24.0 (testing framework)
- coverage: ^1.7.0 (code coverage)
- golden_toolkit: ^0.15.0 (golden file testing)
- integration_test (end-to-end testing)

Platform-Specific Code:
- macOS: Swift/Objective-C (input capture via CGEvent)
- Linux: C++ (input capture via X11/libinput)
- Windows: C++ (input capture via SetWindowsHookEx)

Build System:
- Flutter's built-in build system (platform-specific toolchains)
- Linux: CMake, Clang/GCC, GTK 3
- macOS: Xcode 14+, Swift 5.5+
- Windows: Visual Studio 2019+, MSVC

3. CODE CONVENTIONS
===================

Linting & Analysis (analysis_options.yaml):
- Base: very_good_analysis package (strict rules)
- Material 3: Modern Material design (useMaterial3: true)
- String imports: always_use_package_imports
- Type safety:
  * implicit-casts: false
  * implicit-dynamic: false
- Code quality rules:
  * avoid_print (no print() in production code)
  * always_declare_return_types
  * prefer_const_constructors
  * prefer_const_declarations
  * prefer_const_literals_to_create_immutables
  * prefer_final_fields
  * prefer_final_locals
  * use_key_in_widget_constructors
  * unawaited_futures (prevent promise leaks)
  * sort_constructors_first
  * sort_unnamed_constructors_first

Excluded from Analysis:
- **/*.g.dart (generated code)
- **/*.freezed.dart (generated code)
- build/** (build artifacts)
- lib/generated_plugin_registrant.dart
- test/** (test files from strict checking)

Formatting & Style:
- Tool: dart format (default, no custom rules)
- Enforced via Makefile and CI/CD
- Line length: 80 characters (ruler in .vscode/settings.json)
- File organization: library declarations, imports, classes

Documentation:
- All public APIs must have /// documentation comments
- Example code in comments for complex classes
- Clear explanation of parameters and return values

4. DEVELOPMENT WORKFLOW
======================

Available Make Commands:
- make setup: Initialize Flutter environment
- make analyze: Run static analysis (flutter analyze --fatal-infos)
- make format: Format code (dart format .)
- make format-check: Check formatting without changing
- make test: Run all tests (flutter test --reporter expanded)
- make coverage: Run tests with coverage report
- make build-linux: Build Linux app (debug)
- make build-macos: Build macOS app (debug)
- make build-windows: Build Windows app (debug)
- make ci: Run all CI checks (format-check + analyze + test)
- make clean: Clean build artifacts and coverage

Git Workflow (Trunk-Based Development):
- Main branch: main (always deployable)
- Feature branches: feature/prd-XXX-short-name
- PR requirements:
  * All tests pass
  * Code lint clean
  * Code formatted
  * Reviewed before merge
- Commit message format: type(scope): subject
  Examples:
  - feat(prd-004): Implement macOS keyboard capture
  - fix(input): Handle key repeat edge case
  - test(games): Add unit tests for exploding letters
  - docs(readme): Update setup instructions

CI/CD Pipeline (.github/workflows/ci.yml):
1. Lint & Format (Ubuntu, ~10 min)
   - dart format --set-exit-if-changed .
   - flutter analyze --fatal-infos
2. Unit & Widget Tests (Ubuntu, ~15 min)
   - flutter test --coverage --reporter expanded
   - Coverage threshold: 10% (initial), will increase over time
3. Build macOS (macOS runner, ~30 min)
   - Only on main or with 'build-macos' label
4. Build Linux (Ubuntu, ~30 min)
   - Always runs
5. Build Windows (Windows runner, ~30 min)
   - Only on main or with 'build-windows' label

Testing Strategy:
- Unit tests: Pure Dart logic (test/unit/)
- Widget tests: UI components, mocked platform channels (test/widget/)
- Integration tests: End-to-end flows (test/integration/)
- Golden tests: Visual regression (test/golden/)
- Coverage goal: >90% (starting at 10% for initial development)

Code Review Checklist Before PR:
- [ ] All tests pass: flutter test
- [ ] No lint issues: flutter analyze
- [ ] Code formatted: dart format --set-exit-if-changed .
- [ ] Coverage maintained or improved
- [ ] Documentation updated
- [ ] No debug code (print, debugPrint)
- [ ] Platform-specific code tested
- [ ] PRD acceptance criteria met
- [ ] No new TODOs without GitHub issues
- [ ] Dependencies updated in pubspec.yaml if needed

PRD-Based Development:
- Project uses 14 PRDs (Product Requirements Documents)
- Each PRD is autonomous and self-contained
- PRDs have explicit dependencies (see DEPENDENCIES.md)
- Parallel development structure:
  * Sequential foundation (PRD-001 → PRD-002 → PRD-003)
  * Parallel groups 1-3 (PRD-004-007, PRD-009-011, PRD-012-014)
- Current status: PRD-001-008 complete, PRD-009+ pending

5. ARCHITECTURE & DESIGN PATTERNS
==================================

High-Level Architecture:
```
Flutter Application (Dart)
    ↓
Platform Channels (MethodChannel + EventChannel)
    ↓ ↓ ↓
Native Code (Swift/C++)
    ↓ ↓ ↓
OS-Level Input Capture (CGEvent/X11/SetWindowsHookEx)
```

Key Architectural Patterns:

1. Platform Channel Communication:
   - MethodChannel: Command/control (start/stop capture, request permissions)
   - EventChannel: Event streaming (keyboard/mouse events)
   - Platform channel names: 'com.keyboardplayground/input_capture'
   - Event parsing: Map → typed InputEvent objects
   - Error handling: PlatformException caught, safe defaults

2. Game Plugin System:
   - BaseGame abstract class defines interface
   - Games implement: onKeyEvent(), onMouseEvent(), buildUI(), dispose()
   - GameManager: registers, switches, and lifecycle management
   - Games are loosely coupled to core system
   - Easy to add new games without modifying core

3. Input Event Flow:
   ```
   OS → Native Code → Platform Channel → InputCapture
                                           ↓
                                      GameManager
                                           ↓
                                    Current Game
                                           ↓ (parallel)
                                      ExitHandler
   ```

4. Exit Mechanism:
   - Two exit sequences: keyboard and mouse
   - Keyboard: Alt + Ctrl + ArrowRight + Escape + Q (5 steps, 5s timeout)
   - Mouse: Click 4 corners clockwise (10s timeout)
   - Prevents accidental exits, provides progress feedback
   - Custom progress indicator widget for visual feedback

5. State Management:
   - Provider package for state management
   - StreamController for input events (broadcast stream)
   - GameManager manages game state with stream notifications
   - ExitHandler uses streams for exit event signaling

6. Widget Architecture:
   - Material Design 3 (Flutter modern design system)
   - Custom theme (AppTheme) for kid-friendly appearance
   - Reusable widgets: BigButton, AnimatedBackground, ExitProgressIndicator
   - AppShell: Main UI container organizing game + UI
   - GameSelectionMenu: Game picker interface

Theme Design (Kid-Friendly):
- Color scheme: Bright, high-contrast colors
  * Primary: Bright Blue (#2196F3)
  * Secondary: Bright Green (#4CAF50)
  * Accent colors: Pink, Purple, Orange, Cyan, Yellow
- Typography: Large, readable fonts
  * Display: 36-72px (largest)
  * Heading: 24-32px
  * Body: 16-20px (minimum)
  * No fonts below 14px
- Button styling:
  * Minimum size: 56-60px (finger-friendly)
  * Rounded corners: 12-16px radius
  * Elevated buttons with shadow (elevation: 4-8)
- Animation: Smooth transitions, child-friendly pace

6. KEY CONFIGURATION FILES
==========================

Makefile (/home/user/keyboard-playground/Makefile):
- Platform-agnostic Flutter command wrapper
- Automatic Flutter PATH detection
- Supports Linux, macOS, Windows
- Provides consistent commands across platforms

VS Code Settings (.vscode/):
- extensions.json: Recommends Dart-Code.dart-code and Dart-Code.flutter
- launch.json: Platform-specific launch configurations
  * Keyboard Playground (Linux): deviceId "linux"
  * Keyboard Playground (macOS): deviceId "macos"
  * Keyboard Playground (Windows): deviceId "windows"
- settings.json:
  * formatOnSave: true (auto-format on save)
  * rulers: [80] (show 80-char line)
  * Dart formatter: Dart-Code.dart-code

Claude Code Session Setup (.claude/):
- hooks/SessionStart: Auto-runs at session start
  * Detects Flutter availability
  * Runs setup.sh if Flutter not found
  * Displays environment status
- setup.sh: Flutter environment setup script
  * Downloads Flutter 3.24.5 to /opt/flutter
  * Installs Linux build dependencies
  * Runs flutter pub get
  * Idempotent (safe to run multiple times)
- env.sh: Environment sourcing script
  * Adds Flutter to PATH
  * Verifies Flutter availability
- TESTING.md: Testing guide for Claude Code sessions
- README.md: Claude Code environment documentation

GitHub Actions Workflows (.github/workflows/):
- ci.yml: Main continuous integration pipeline
  * Triggered on: push (main, claude/**), pull request
  * Concurrency: Cancels in-progress runs for same ref
  * Jobs:
    - analyze (lint & format check)
    - test (unit & widget tests with coverage)
    - build-macos (macOS platform)
    - build-linux (Linux platform)
    - build-windows (Windows platform)
  * Coverage upload to Codecov (optional)
  * Artifact retention: 7 days
- pr-checks.yml: PR-specific checks (if configured)

Documentation Files:
- PLAN.md: Master project plan (vision, phases, risk mitigation)
- AGENTS.md: AI agent coordination guide (15KB, comprehensive)
- DEPENDENCIES.md: PRD dependency graph and execution order
- CONTRIBUTING.md: Developer setup and guidelines
- docs/architecture/TDR-001-technology-stack.md: Technology decision record
- docs/architecture/platform-requirements.md: Platform-specific requirements
- docs/prds/: 14 product requirements documents (PRD-001 through PRD-014)

7. CODE PATTERNS & EXAMPLES
============================

Common Patterns:

1. Platform Channel Communication:
```dart
// Calling native method
Future<bool> startCapture() async {
  try {
    final result = await _methodChannel.invokeMethod<bool>('startCapture');
    return result ?? false;
  } on PlatformException {
    return false;
  }
}

// Listening to events
_inputCapture.events.listen((event) {
  _gameManager.handleInputEvent(event);
});
```

2. Game Implementation:
```dart
class MyGame extends BaseGame {
  @override
  String get id => 'my_game';
  
  @override
  String get name => 'My Game';
  
  @override
  Widget buildUI() => Container(...);
  
  @override
  void onKeyEvent(KeyEvent event) { ... }
  
  @override
  void dispose() { ... }
}

// Register in main.dart
_gameManager.registerGame(MyGame());
_gameManager.switchGame('my_game');
```

3. Widget Testing Pattern:
```dart
testWidgets('widget test description', (tester) async {
  await tester.pumpWidget(MyWidget());
  expect(find.byType(Text), findsOneWidget);
  // Verify behavior
});
```

4. Exit Handler Sequence:
```dart
final exitHandler = ExitHandler(inputCapture: _inputCapture);
exitHandler.exitTriggered.listen((_) {
  // Handle exit (stop input, exit fullscreen, quit app)
});
```

File Naming Conventions:
- Dart files: snake_case.dart
- Classes: PascalCase
- Functions/variables: camelCase
- Constants: camelCase or CONSTANT_CASE (for compile-time)
- Test files: name_test.dart (same as implementation)

Import Organization:
1. package:flutter imports
2. package:keyboard_playground imports
3. Relative imports (rare, use package imports)
4. Example: import 'package:keyboard_playground/core/game_manager.dart'

8. DEVELOPMENT ENVIRONMENT SETUP
=================================

Automated Setup (Claude Code Sessions):
- SessionStart hook auto-detects Flutter
- If not found, runs setup.sh
- Installs Flutter 3.24.5 to /opt/flutter
- Installs Linux build dependencies
- Makes environment ready for immediate work

Manual Setup:
1. Install Flutter SDK (3.24+ stable)
2. Run: flutter pub get
3. Run: flutter analyze
4. Run: flutter test
5. Run: flutter run -d linux (or macos/windows)

Environment Variables:
- PATH must include Flutter/bin directory
- .claude/env.sh provides sourcing for manual setup

Quick Start Commands (after setup):
```bash
make ci          # Full CI check (format, analyze, test)
make test        # Run tests
make analyze     # Lint check
make format      # Format code
```

9. IMPORTANT PROJECT NOTES
===========================

Project Status:
- Foundation PRDs complete (PRD-001 through PRD-008)
- Base app working with placeholder game
- Input capture, exit mechanism, UI framework in place
- Next: Game implementations (PRD-009-011), polish (PRD-012-014)

Key Design Decisions:
1. Flutter chosen over Tauri/Electron for:
   - Excellent animation support
   - Single codebase across platforms
   - Hot reload development velocity
   - Built-in testing framework

2. Platform channels for input capture (not built into Flutter):
   - Each platform requires native code
   - macOS: CGEvent (requires Accessibility permissions)
   - Linux: X11/libinput (requires input group or udev)
   - Windows: SetWindowsHookEx (may require admin)

3. Kid-friendly focus:
   - High contrast colors for visibility
   - Large touch targets (56px minimum)
   - No network/filesystem access
   - Exit sequence prevents accidental closure

Parallel Development Strategy:
- PRDs designed for maximum parallelization
- Each PRD is autonomous and self-contained
- Can work on multiple PRDs simultaneously
- Explicit dependency tracking in DEPENDENCIES.md

Testing Requirements:
- Minimum coverage: 10% (initial), goal >90%
- All public methods tested
- Platform-specific tests per OS
- Integration tests for critical flows
- Golden tests for UI components

Branch Strategy:
- Main branch: Always deployable
- Feature branches: feature/prd-XXX-name
- Merge: Squash and merge (clean history)
- PR review before merge to main

Special Considerations:
1. CLI tools must be invoked via Makefile for PATH handling
2. VS Code recommends specific extensions (Dart-Code extensions)
3. Pre-push hooks will enforce CI checks (via .claude/hooks)
4. Platform builds must succeed in CI for PRs
5. Coverage reports track progress over time

10. FOR NEW AI ASSISTANTS
==========================

Before Starting Work:
1. Read AGENTS.md for complete coordination guide
2. Check DEPENDENCIES.md for PRD availability
3. Create feature/prd-XXX-name branch
4. Read target PRD thoroughly
5. Review existing code patterns in lib/

During Development:
1. Run make test frequently
2. Run make analyze before commits
3. Format code: dart format .
4. Keep commits small and atomic
5. Update tests alongside code

Before PR Completion:
1. Run make ci (all checks)
2. Verify tests pass
3. Check coverage maintained
4. Update relevant documentation
5. Clean up any debug code

Testing in Claude Code:
1. SessionStart hook auto-configures environment
2. Use make commands (handles PATH automatically)
3. If Flutter not found: make setup
4. Tests run without manual PATH setup

Common Issues & Solutions:
- Flutter not found → run make setup
- Test failures → flutter pub get && flutter test
- Format issues → dart format .
- Lint errors → Read flutter analyze output, fix issues
- Coverage drops → Write tests for new code
- Build fails → flutter clean && flutter build linux

Remember:
- Quality over speed
- Small, focused commits
- Comprehensive testing
- Clear documentation
- Respectful of existing patterns
