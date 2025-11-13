# PRD-002: Project Setup & Structure

**Status**: ⚪ Not Started
**Dependencies**: PRD-001 (Technology Research)
**Estimated Effort**: 4 hours
**Priority**: P0 - CRITICAL (Must be second)
**Branch**: `feature/prd-002-project-setup`

## Overview

Initialize the Flutter desktop project with proper structure, configuration, and development tooling. This PRD establishes the foundation that all other PRDs will build upon.

## Context

After validating Flutter as our technology choice (PRD-001), we need to:
- Create the Flutter project with desktop support
- Set up proper directory structure
- Configure linting and formatting
- Establish code quality standards
- Initialize git properly (already done, but configure git hooks)
- Set up development environment configuration

## Goals

1. ✅ Create Flutter project with desktop platforms enabled
2. ✅ Establish clear directory structure for games, platform code, and tests
3. ✅ Configure strict linting and formatting rules
4. ✅ Set up pre-commit hooks for code quality
5. ✅ Create initial README and CONTRIBUTING docs
6. ✅ Ensure project builds successfully on at least one platform (macOS preferred)

## Non-Goals

- Implementing any features (that's PRD-004+)
- Setting up CI/CD (that's PRD-003)
- Writing tests for functionality (that's PRD-007+)

## Requirements

### Functional Requirements

**FR-001**: Flutter project created with desktop support
- macOS, Linux, and Windows platforms enabled
- No mobile platforms (iOS, Android) initially

**FR-002**: Directory structure follows Flutter best practices
- Clear separation of concerns
- Game plugins in dedicated directories
- Platform-specific code isolated

**FR-003**: Linting and formatting configured
- Analysis options set to strict
- Dart formatter configured
- No warnings on clean project

**FR-004**: Development tooling configured
- Pre-commit hooks for linting
- Format-on-save configurations documented
- Launch configurations for debugging

**FR-005**: Documentation started
- README with project overview
- CONTRIBUTING with setup instructions
- LICENSE file

### Non-Functional Requirements

**NFR-001**: Clean build
- `flutter run -d macos` (or linux/windows) executes without errors
- Default Flutter app displays

**NFR-002**: Zero lint warnings
- `flutter analyze` returns zero issues
- All code formatted with `dart format`

**NFR-003**: Git hygiene
- .gitignore configured properly
- No IDE-specific files in repo (except documented ones)
- Clean commit history

## Technical Specifications

### Directory Structure

```
keyboard-playground/
├── .github/                      # GitHub specific (PR templates, etc.)
│   └── workflows/                # CI/CD (PRD-003 will populate)
├── .vscode/                      # VS Code settings (optional, recommended)
│   ├── launch.json
│   ├── settings.json
│   └── extensions.json
├── docs/
│   ├── prds/                     # Already exists
│   ├── architecture/             # Already exists (from PRD-001)
│   └── user/                     # User-facing documentation
│       └── README.md
├── lib/
│   ├── main.dart                 # App entry point
│   ├── app.dart                  # Root widget
│   ├── core/                     # Core framework (PRD-004+)
│   │   ├── game_manager.dart
│   │   ├── input_manager.dart
│   │   └── exit_handler.dart
│   ├── games/                    # Game implementations (PRD-009+)
│   │   └── base_game.dart        # Base game interface
│   ├── platform/                 # Platform channel interfaces (PRD-004)
│   │   ├── input_capture.dart
│   │   └── window_control.dart
│   ├── ui/                       # UI components (PRD-006)
│   │   └── app_shell.dart
│   └── widgets/                  # Reusable widgets (PRD-006)
│       └── .gitkeep
├── macos/                        # macOS platform code
│   └── Runner/
│       └── (Flutter generated + our extensions)
├── linux/                        # Linux platform code
│   └── (Flutter generated + our extensions)
├── windows/                      # Windows platform code
│   └── (Flutter generated + our extensions)
├── test/                         # All tests
│   ├── unit/                     # Unit tests
│   ├── widget/                   # Widget tests
│   ├── integration/              # Integration tests
│   └── test_utils/               # Test helpers (PRD-007)
│       └── .gitkeep
├── .gitignore                    # Git ignore rules
├── .gitattributes                # Git attributes (line endings)
├── analysis_options.yaml         # Dart analyzer config
├── pubspec.yaml                  # Dependencies
├── README.md                     # Project README
├── CONTRIBUTING.md               # Contribution guide
├── LICENSE                       # License (MIT recommended)
├── PLAN.md                       # Already exists
├── AGENTS.md                     # Already exists
└── DEPENDENCIES.md               # Already exists
```

### Flutter Project Configuration

#### pubspec.yaml

```yaml
name: keyboard_playground
description: A safe, fun keyboard and mouse playground for kids
publish_to: 'none'  # Not publishing to pub.dev
version: 0.1.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'  # Use latest stable Flutter 3.x SDK

dependencies:
  flutter:
    sdk: flutter

  # State management (choose one):
  # provider: ^6.1.0  # Recommended for simplicity
  # Or riverpod: ^2.4.0  # If you prefer riverpod

  # Utilities
  equatable: ^2.0.5      # For value equality
  collection: ^1.18.0     # Collection utilities

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints: ^3.0.0   # Official Flutter lints
  very_good_analysis: ^5.1.0  # Additional strict lints
  test: ^1.24.0

flutter:
  uses-material-design: true

  # Uncomment when we add assets:
  # assets:
  #   - assets/images/
  #   - assets/sounds/
```

#### analysis_options.yaml

```yaml
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "build/**"
    - "lib/generated_plugin_registrant.dart"

  errors:
    # Treat all lints as errors
    invalid_annotation_target: ignore

  strong-mode:
    implicit-casts: false
    implicit-dynamic: false

linter:
  rules:
    # Additional rules beyond very_good_analysis
    - always_declare_return_types
    - always_put_required_named_parameters_first
    - always_use_package_imports
    - avoid_print
    - avoid_unnecessary_containers
    - avoid_web_libraries_in_flutter
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_const_literals_to_create_immutables
    - prefer_final_fields
    - prefer_final_in_for_each
    - prefer_final_locals
    - sort_constructors_first
    - sort_unnamed_constructors_first
    - unawaited_futures
    - use_key_in_widget_constructors
```

### Initial Code Files

#### lib/main.dart

```dart
import 'package:flutter/material.dart';
import 'package:keyboard_playground/app.dart';

void main() {
  // TODO(PRD-004): Initialize platform channels
  // TODO(PRD-006): Initialize window management
  runApp(const KeyboardPlaygroundApp());
}
```

#### lib/app.dart

```dart
import 'package:flutter/material.dart';

/// Root application widget for Keyboard Playground.
class KeyboardPlaygroundApp extends StatelessWidget {
  /// Creates the root application widget.
  const KeyboardPlaygroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keyboard Playground',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            'Keyboard Playground\nSetup Complete!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
```

#### lib/games/base_game.dart

```dart
import 'package:flutter/widgets.dart';

/// Base interface for all games in Keyboard Playground.
///
/// Each game should extend this class and implement the required methods.
/// Games will be registered with [GameManager] and can be switched at runtime.
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
```

### README.md

```markdown
# Keyboard Playground

A safe, entertaining desktop application for young children to explore keyboard and mouse input without triggering system actions.

## 🎯 Features

- **Full Input Capture**: Captures all keyboard and mouse events
- **Kid-Friendly Games**: Interactive games with visual feedback
- **Safe Environment**: Difficult exit mechanism prevents accidental closure
- **Cross-Platform**: Works on macOS, Linux, and Windows

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.2 or higher
- Platform-specific requirements:
  - **macOS**: Xcode 14+
  - **Linux**: Build essentials, GTK 3
  - **Windows**: Visual Studio 2022

### Installation

\`\`\`bash
# Clone the repository
git clone <repository-url>
cd keyboard-playground

# Get dependencies
flutter pub get

# Run on your platform
flutter run -d macos   # or linux, windows
\`\`\`

## 📖 Documentation

- [Architecture Documentation](docs/architecture/)
- [User Guide](docs/user/)
- [Contributing Guidelines](CONTRIBUTING.md)
- [Development Plan](PLAN.md)

## 🏗️ Project Status

See [DEPENDENCIES.md](DEPENDENCIES.md) for current development status and PRD progress.

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Master Plan](PLAN.md)
- [AI Agent Guide](AGENTS.md)
- [PRD Directory](docs/prds/)
```

### CONTRIBUTING.md

```markdown
# Contributing to Keyboard Playground

## Development Setup

### 1. Install Flutter

Follow the official Flutter installation guide: https://docs.flutter.dev/get-started/install

Verify installation:
\`\`\`bash
flutter doctor
\`\`\`

### 2. Clone and Setup

\`\`\`bash
git clone <repository-url>
cd keyboard-playground
flutter pub get
\`\`\`

### 3. IDE Setup (Recommended)

**VS Code**:
- Install Flutter extension
- Install Dart extension
- Settings are pre-configured in `.vscode/`

**Android Studio / IntelliJ**:
- Install Flutter plugin
- Install Dart plugin

### 4. Verify Setup

\`\`\`bash
flutter analyze  # Should show no issues
flutter test     # Should pass all tests
flutter run -d macos  # Should run the app
\`\`\`

## Development Workflow

### Before You Start

1. Check [DEPENDENCIES.md](DEPENDENCIES.md) for available PRDs
2. Read [AGENTS.md](AGENTS.md) for coordination guidelines
3. Create a feature branch: `git checkout -b feature/prd-XXX-description`

### During Development

1. Write tests first (TDD encouraged)
2. Run `flutter analyze` frequently
3. Format code: `dart format .`
4. Commit often with clear messages

### Before Submitting PR

\`\`\`bash
# Run all checks
flutter analyze
flutter test --coverage
dart format --set-exit-if-changed .

# Commit
git add .
git commit -m "feat(prd-XXX): Description"
git push -u origin feature/prd-XXX-description
\`\`\`

## Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `dart format` (no custom formatting)
- All public APIs must have documentation comments
- Prefer `const` constructors where possible

## Testing

- Unit tests for business logic
- Widget tests for UI components
- Integration tests for end-to-end flows
- Maintain >90% coverage

## Commit Messages

Format: `type(scope): subject`

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `test`: Adding/updating tests
- `refactor`: Code refactoring
- `chore`: Build tasks, dependencies

**Examples**:
- `feat(prd-004): Implement macOS keyboard capture`
- `fix(input): Handle key repeat edge case`
- `docs(readme): Update setup instructions`

## Questions?

- Check [AGENTS.md](AGENTS.md) for detailed guidance
- Review existing PRDs in [docs/prds/](docs/prds/)
- Read architecture docs in [docs/architecture/](docs/architecture/)
```

## Acceptance Criteria

### Project Structure

- [ ] Flutter project created with `flutter create --platforms=macos,linux,windows keyboard_playground`
- [ ] All directories from Technical Specifications created
- [ ] .gitignore properly configured (Flutter default + custom additions)
- [ ] .gitkeep files in empty directories

### Configuration Files

- [ ] pubspec.yaml configured with dependencies
- [ ] analysis_options.yaml configured with strict linting
- [ ] .vscode/settings.json created with Flutter/Dart settings
- [ ] .vscode/launch.json created with debug configurations

### Code Files

- [ ] lib/main.dart created with basic app structure
- [ ] lib/app.dart created with MaterialApp
- [ ] lib/games/base_game.dart created with interface
- [ ] All files properly formatted and lint-free

### Documentation

- [ ] README.md created with project overview
- [ ] CONTRIBUTING.md created with setup guide
- [ ] LICENSE file added (MIT recommended)
- [ ] docs/user/README.md placeholder created

### Build Verification

- [ ] `flutter pub get` runs successfully
- [ ] `flutter analyze` returns zero issues
- [ ] `dart format --set-exit-if-changed .` passes (all files formatted)
- [ ] `flutter run -d <platform>` builds and runs successfully
- [ ] App displays "Keyboard Playground - Setup Complete!" message

### Git Hygiene

- [ ] All files committed with proper messages
- [ ] No untracked files that should be ignored
- [ ] Branch pushed to remote
- [ ] DEPENDENCIES.md updated (PRD-002 marked complete)

## Implementation Steps

### Step 1: Create Flutter Project (30 min)

```bash
# Create Flutter project
flutter create --platforms=macos,linux,windows keyboard_playground

# Or if already in directory:
flutter create --platforms=macos,linux,windows .

# Verify creation
flutter pub get
flutter analyze
```

### Step 2: Setup Directory Structure (20 min)

```bash
# Create directories
mkdir -p lib/core lib/games lib/platform lib/ui lib/widgets
mkdir -p test/unit test/widget test/integration test/test_utils
mkdir -p docs/user .vscode .github

# Create .gitkeep files for empty directories
touch lib/widgets/.gitkeep test/test_utils/.gitkeep
```

### Step 3: Configure Linting & Formatting (20 min)

1. Update pubspec.yaml with dependencies
2. Create analysis_options.yaml
3. Run `flutter pub get`
4. Verify with `flutter analyze`

### Step 4: Create Initial Code Files (45 min)

1. Create lib/main.dart
2. Create lib/app.dart
3. Create lib/games/base_game.dart
4. Format all files: `dart format .`
5. Verify: `flutter analyze`

### Step 5: Create Documentation (30 min)

1. Write README.md
2. Write CONTRIBUTING.md
3. Copy MIT LICENSE (or other)
4. Create docs/user/README.md placeholder

### Step 6: Configure VS Code (15 min)

Create `.vscode/settings.json`:
```json
{
  "dart.flutterSdkPath": "",
  "editor.formatOnSave": true,
  "editor.rulers": [80],
  "[dart]": {
    "editor.defaultFormatter": "Dart-Code.dart-code",
    "editor.formatOnSave": true
  }
}
```

Create `.vscode/launch.json`:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Keyboard Playground (macOS)",
      "request": "launch",
      "type": "dart",
      "deviceId": "macos"
    }
  ]
}
```

### Step 7: Build and Test (30 min)

```bash
# Clean start
flutter clean
flutter pub get

# Analyze
flutter analyze

# Format check
dart format --set-exit-if-changed .

# Run on macOS (or your platform)
flutter run -d macos

# Verify app displays
```

### Step 8: Commit and Push (10 min)

```bash
git add .
git commit -m "feat(prd-002): Complete project setup and structure"
git push -u origin feature/prd-002-project-setup
```

## Testing Requirements

- [ ] `flutter pub get` succeeds
- [ ] `flutter analyze` returns 0 issues
- [ ] `dart format --set-exit-if-changed .` returns 0 changes needed
- [ ] `flutter build macos` (or target platform) succeeds
- [ ] App runs and displays welcome message
- [ ] No exceptions in debug console

## Definition of Done

- [ ] All acceptance criteria met
- [ ] Project builds on at least one platform (macOS preferred)
- [ ] Zero lint warnings
- [ ] All code formatted
- [ ] Documentation complete
- [ ] Branch pushed and ready for PR
- [ ] DEPENDENCIES.md updated
- [ ] PRD-003 can start immediately

## Notes for AI Agents

### Common Issues

**Issue**: `flutter: command not found`
- **Solution**: Ensure Flutter is in PATH. Run `flutter doctor` to diagnose.

**Issue**: Platform not found (e.g., macos)
- **Solution**: Enable platform: `flutter config --enable-macos-desktop`

**Issue**: Lint errors after creation
- **Solution**: This is expected with default Flutter code. Update to match our analysis_options.yaml.

### Time Breakdown

- Flutter project creation: 30 min
- Directory structure: 20 min
- Configuration: 20 min
- Initial code: 45 min
- Documentation: 30 min
- VS Code setup: 15 min
- Build/test: 30 min
- Commit: 10 min
- **Total**: 4 hours

### Quick Validation

```bash
# Should all pass:
flutter pub get && \
flutter analyze && \
dart format --set-exit-if-changed . && \
echo "✅ All checks passed!"
```

## References

- [Flutter Desktop Documentation](https://docs.flutter.dev/desktop)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Very Good Analysis](https://pub.dev/packages/very_good_analysis)

---

**Ready to start?** Ensure PRD-001 is complete, then create your branch and begin setup!
