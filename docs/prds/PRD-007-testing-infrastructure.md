# PRD-007: Testing Infrastructure Setup

**Status**: ⚪ Not Started
**Dependencies**: PRD-003 (Build System & CI/CD)
**Estimated Effort**: 6 hours
**Priority**: P0 - CRITICAL
**Branch**: `feature/prd-007-testing-infrastructure`

## Overview

Establish comprehensive testing infrastructure including test utilities, mocks, fixtures, and testing patterns. This enables high-quality testing for all subsequent PRDs.

## Context

Testing is critical for this project. We need:
- High test coverage (>90%)
- Fast, reliable tests
- Easy-to-use test utilities
- Consistent testing patterns
- Platform-specific test support

This PRD sets up the foundation that all other PRDs will use for testing.

## Goals

1. ✅ Test utilities and helpers for common scenarios
2. ✅ Mock implementations for platform channels
3. ✅ Test fixtures for input events
4. ✅ Golden file testing setup for UI
5. ✅ Integration test framework
6. ✅ Performance testing utilities (basic)

## Non-Goals

- Writing tests for features (each PRD does that)
- End-to-end testing with real input (too complex for now)
- Visual regression testing (future enhancement)

## Requirements

### Functional Requirements

**FR-001**: Test Utilities Package
- Common test helpers in `test/test_utils/`
- Reusable across unit, widget, and integration tests
- Well-documented with examples

**FR-002**: Platform Channel Mocks
- Mock implementations for InputCapture
- Mock implementations for WindowControl
- Easy to configure behavior and responses

**FR-003**: Event Fixtures
- Pre-built KeyEvent, MouseEvent objects
- Builders for creating test events
- Sequences of events for common scenarios

**FR-004**: Widget Testing Helpers
- Helper to pump app with dependencies
- Helper to find widgets by test keys
- Helper to simulate input events in widgets

**FR-005**: Integration Test Framework
- Setup for integration tests
- Test harness for full app testing
- Performance measurement utilities

**FR-006**: Golden File Setup
- Configuration for golden file tests
- Update script for regenerating goldens
- CI integration for golden file checks

### Non-Functional Requirements

**NFR-001**: Test Performance
- Unit tests run <5 seconds total
- Widget tests run <30 seconds total
- Integration tests run <2 minutes total

**NFR-002**: Test Reliability
- Zero flaky tests
- Deterministic results
- Proper cleanup after each test

**NFR-003**: Developer Experience
- Clear error messages on failure
- Easy to debug failures
- Minimal boilerplate

## Technical Specifications

### Directory Structure

```
test/
├── unit/                           # Unit tests (pure Dart logic)
│   ├── core/
│   ├── games/
│   └── platform/
├── widget/                         # Widget tests (UI components)
│   ├── ui/
│   └── widgets/
├── integration/                    # Integration tests (end-to-end)
│   └── app_test.dart
├── golden/                         # Golden file outputs
│   └── .gitkeep
├── fixtures/                       # Test data and fixtures
│   ├── events.dart
│   └── games.dart
└── test_utils/                     # Test utilities and helpers
    ├── mocks/
    │   ├── mock_input_capture.dart
    │   ├── mock_window_control.dart
    │   └── mock_game_manager.dart
    ├── builders/
    │   ├── event_builder.dart
    │   └── game_builder.dart
    ├── helpers/
    │   ├── widget_test_helpers.dart
    │   └── integration_test_helpers.dart
    └── matchers/
        └── custom_matchers.dart
```

### Mock Platform Channels

```dart
// test/test_utils/mocks/mock_input_capture.dart

import 'package:keyboard_playground/platform/input_events.dart';

class MockInputCapture {
  final StreamController<InputEvent> _eventController =
      StreamController<InputEvent>.broadcast();

  bool _isCapturing = false;

  Stream<InputEvent> get events => _eventController.stream;

  Future<bool> startCapture() async {
    _isCapturing = true;
    return true;
  }

  Future<bool> stopCapture() async {
    _isCapturing = false;
    return true;
  }

  Future<bool> isCapturing() async {
    return _isCapturing;
  }

  /// Emit a test event
  void emitEvent(InputEvent event) {
    _eventController.add(event);
  }

  /// Emit a sequence of events
  void emitEvents(List<InputEvent> events) {
    for (final event in events) {
      _eventController.add(event);
    }
  }

  Future<void> dispose() async {
    await _eventController.close();
  }
}

// test/test_utils/mocks/mock_window_control.dart

class MockWindowControl {
  bool _isFullscreen = false;
  Size _screenSize = const Size(1920, 1080);

  Future<bool> enterFullscreen() async {
    _isFullscreen = true;
    return true;
  }

  Future<bool> exitFullscreen() async {
    _isFullscreen = false;
    return true;
  }

  bool get isFullscreen => _isFullscreen;

  Future<Size> getScreenSize() async {
    return _screenSize;
  }

  void setScreenSize(Size size) {
    _screenSize = size;
  }
}
```

### Event Builders and Fixtures

```dart
// test/test_utils/builders/event_builder.dart

class EventBuilder {
  /// Creates a key down event
  static KeyEvent keyDown(
    String key, {
    int? keyCode,
    Set<KeyModifier> modifiers = const {},
    DateTime? timestamp,
  }) {
    return KeyEvent(
      keyCode: keyCode ?? key.codeUnitAt(0),
      key: key,
      modifiers: modifiers,
      isDown: true,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Creates a key up event
  static KeyEvent keyUp(
    String key, {
    int? keyCode,
    Set<KeyModifier> modifiers = const {},
    DateTime? timestamp,
  }) {
    return KeyEvent(
      keyCode: keyCode ?? key.codeUnitAt(0),
      key: key,
      modifiers: modifiers,
      isDown: false,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Creates a mouse move event
  static MouseMoveEvent mouseMove(
    double x,
    double y, {
    DateTime? timestamp,
  }) {
    return MouseMoveEvent(
      x: x,
      y: y,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Creates a mouse click event
  static MouseButtonEvent mouseClick(
    double x,
    double y, {
    MouseButton button = MouseButton.left,
    bool isDown = true,
    DateTime? timestamp,
  }) {
    return MouseButtonEvent(
      button: button,
      x: x,
      y: y,
      isDown: isDown,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Creates a mouse scroll event
  static MouseScrollEvent mouseScroll({
    double deltaX = 0,
    double deltaY = 0,
    DateTime? timestamp,
  }) {
    return MouseScrollEvent(
      deltaX: deltaX,
      deltaY: deltaY,
      timestamp: timestamp ?? DateTime.now(),
    );
  }
}

// test/fixtures/events.dart

/// Common event sequences for testing
class EventFixtures {
  /// Typical typing sequence: "HELLO"
  static List<InputEvent> get typingHello {
    return [
      EventBuilder.keyDown('H'),
      EventBuilder.keyUp('H'),
      EventBuilder.keyDown('E'),
      EventBuilder.keyUp('E'),
      EventBuilder.keyDown('L'),
      EventBuilder.keyUp('L'),
      EventBuilder.keyDown('L'),
      EventBuilder.keyUp('L'),
      EventBuilder.keyDown('O'),
      EventBuilder.keyUp('O'),
    ];
  }

  /// Exit sequence (from PRD-005)
  static List<InputEvent> get exitSequence {
    return [
      EventBuilder.keyDown('AltLeft', modifiers: {KeyModifier.alt}),
      EventBuilder.keyUp('AltLeft'),
      EventBuilder.keyDown('ControlLeft', modifiers: {KeyModifier.control}),
      EventBuilder.keyUp('ControlLeft'),
      EventBuilder.keyDown('ArrowRight'),
      EventBuilder.keyUp('ArrowRight'),
      EventBuilder.keyDown('Escape'),
      EventBuilder.keyUp('Escape'),
      EventBuilder.keyDown('KeyQ'),
      EventBuilder.keyUp('KeyQ'),
    ];
  }

  /// Mouse movement in a circle
  static List<InputEvent> circleMouseMovement(
    double centerX,
    double centerY,
    double radius,
    int steps,
  ) {
    return List.generate(steps, (i) {
      final angle = (i / steps) * 2 * pi;
      return EventBuilder.mouseMove(
        centerX + radius * cos(angle),
        centerY + radius * sin(angle),
      );
    });
  }
}
```

### Widget Test Helpers

```dart
// test/test_utils/helpers/widget_test_helpers.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:keyboard_playground/app.dart';

/// Helper for pumping the app with test dependencies
Future<void> pumpApp(
  WidgetTester tester, {
  MockInputCapture? inputCapture,
  MockWindowControl? windowControl,
  GameManager? gameManager,
}) async {
  await tester.pumpWidget(
    KeyboardPlaygroundApp(
      inputCapture: inputCapture ?? MockInputCapture(),
      windowControl: windowControl ?? MockWindowControl(),
      gameManager: gameManager ?? GameManager(),
    ),
  );
}

/// Helper for pumping a widget with theme
Future<void> pumpThemedWidget(
  WidgetTester tester,
  Widget widget,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.kidFriendlyTheme,
      home: Scaffold(body: widget),
    ),
  );
}

/// Helper to find by test key
Finder findByTestKey(String key) {
  return find.byKey(Key(key));
}

/// Helper to simulate keyboard input
void simulateKeyPress(
  WidgetTester tester,
  String key, {
  Set<KeyModifier> modifiers = const {},
}) {
  // Simulate keyboard event
  // Implementation depends on Flutter's test keyboard simulation
}

/// Helper to wait for animations to complete
Future<void> waitForAnimations(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(seconds: 2));
}
```

### Custom Matchers

```dart
// test/test_utils/matchers/custom_matchers.dart

import 'package:flutter_test/flutter_test.dart';

/// Matcher for KeyEvent
Matcher isKeyEvent({
  String? key,
  bool? isDown,
  Set<KeyModifier>? modifiers,
}) {
  return _KeyEventMatcher(key: key, isDown: isDown, modifiers: modifiers);
}

class _KeyEventMatcher extends Matcher {
  final String? key;
  final bool? isDown;
  final Set<KeyModifier>? modifiers;

  _KeyEventMatcher({this.key, this.isDown, this.modifiers});

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! KeyEvent) return false;

    if (key != null && item.key != key) return false;
    if (isDown != null && item.isDown != isDown) return false;
    if (modifiers != null && !setEquals(item.modifiers, modifiers)) {
      return false;
    }

    return true;
  }

  @override
  Description describe(Description description) {
    return description.add('KeyEvent(key: $key, isDown: $isDown)');
  }
}

/// Matcher for checking event stream contains sequence
Matcher emitsEventSequence(List<InputEvent> expectedEvents) {
  return _EventSequenceMatcher(expectedEvents);
}

class _EventSequenceMatcher extends Matcher {
  final List<InputEvent> expectedEvents;

  _EventSequenceMatcher(this.expectedEvents);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! Stream<InputEvent>) return false;

    // Implementation for stream matching
    return true;
  }

  @override
  Description describe(Description description) {
    return description.add('emits sequence of ${expectedEvents.length} events');
  }
}
```

### Integration Test Setup

```dart
// test/integration/app_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:keyboard_playground/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('App launches in fullscreen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify app state
      expect(find.byType(KeyboardPlaygroundApp), findsOneWidget);
    });

    testWidgets('Exit sequence works end-to-end', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Simulate exit sequence
      // Verify app exits
    });
  });
}
```

### Golden File Setup

```dart
// test/widget/golden_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  group('Golden Tests', () {
    testGoldens('GameCard matches golden', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'Default state',
          GameCard(
            game: TestGame(name: 'Test Game'),
            onTap: () {},
          ),
        )
        ..addScenario(
          'Hovered state',
          GameCard(
            game: TestGame(name: 'Test Game'),
            onTap: () {},
            isHovered: true,
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        surfaceSize: const Size(800, 600),
      );

      await screenMatchesGolden(tester, 'game_card');
    });
  });
}
```

### pubspec.yaml Additions

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter

  # Testing utilities
  mocktail: ^1.0.0           # Mocking library
  golden_toolkit: ^0.15.0    # Golden file testing
  test: ^1.24.0

  # Test coverage
  coverage: ^1.7.0

  # Linting (already added in PRD-002)
  flutter_lints: ^3.0.0
  very_good_analysis: ^5.1.0
```

## Acceptance Criteria

### Test Utilities Created

- [ ] `test/test_utils/` directory structure created
- [ ] Mock implementations for all platform channels
- [ ] Event builders for all event types
- [ ] Event fixtures for common scenarios
- [ ] Widget test helpers created
- [ ] Custom matchers created

### Tests Can Be Written Easily

- [ ] Example unit test written using utilities
- [ ] Example widget test written using utilities
- [ ] Example integration test written
- [ ] Example golden test written
- [ ] Documentation for all test utilities

### Test Infrastructure Works

- [ ] All example tests pass
- [ ] Tests run fast (<5s for unit tests)
- [ ] Tests are deterministic (no flakiness)
- [ ] Coverage reports generate correctly

### CI Integration

- [ ] Tests run in CI (already setup in PRD-003, verify working)
- [ ] Coverage reporting works
- [ ] Golden file checks work (fail on mismatch)

### Documentation

- [ ] README in `test/` directory explaining structure
- [ ] Examples for each type of test
- [ ] Guidelines for writing tests
- [ ] Coverage requirements documented

## Implementation Steps

### Step 1: Create Directory Structure (30 min)

```bash
mkdir -p test/unit/{core,games,platform}
mkdir -p test/widget/{ui,widgets}
mkdir -p test/integration
mkdir -p test/golden
mkdir -p test/fixtures
mkdir -p test/test_utils/{mocks,builders,helpers,matchers}
```

### Step 2: Create Mocks (1.5 hours)

1. MockInputCapture
2. MockWindowControl
3. MockGameManager
4. Document usage

### Step 3: Create Builders and Fixtures (1.5 hours)

1. EventBuilder
2. EventFixtures
3. Document usage

### Step 4: Create Test Helpers (1.5 hours)

1. Widget test helpers
2. Integration test helpers
3. Custom matchers
4. Document usage

### Step 5: Create Example Tests (1 hour)

1. Example unit test
2. Example widget test
3. Example integration test
4. Example golden test

### Step 6: Documentation (30 min)

1. Create test/README.md
2. Document testing patterns
3. Update CONTRIBUTING.md

## Testing Requirements

### Meta-Testing

- [ ] Example tests actually pass
- [ ] Test utilities have their own unit tests
- [ ] Mock implementations behave correctly
- [ ] Builders create valid events

### Performance Testing

- [ ] Measure unit test execution time (<5s total)
- [ ] Measure widget test execution time (<30s total)
- [ ] Verify no memory leaks in test utilities

## Definition of Done

- [ ] All acceptance criteria met
- [ ] All example tests pass
- [ ] Test utilities documented
- [ ] README created in test/ directory
- [ ] CONTRIBUTING.md updated with testing guidelines
- [ ] Other PRDs can easily use these utilities
- [ ] Code review passed
- [ ] DEPENDENCIES.md updated

## Notes for AI Agents

### Key Principles

**Testing Philosophy:**
- Tests should be easy to write
- Tests should be fast
- Tests should be reliable
- Tests should document behavior

**Coverage Goals:**
- Business logic: 100%
- UI widgets: >90%
- Platform channels: Mock, test Dart side only
- Integration: Critical paths only

### Time Breakdown

- Directory structure: 30 min
- Mocks: 1.5 hours
- Builders & fixtures: 1.5 hours
- Test helpers: 1.5 hours
- Example tests: 1 hour
- Documentation: 30 min
- **Total**: 6 hours

### Common Patterns

**Unit Test Pattern:**
```dart
void main() {
  group('ClassName', () {
    late ClassName sut;  // System Under Test

    setUp(() {
      sut = ClassName();
    });

    tearDown(() {
      sut.dispose();
    });

    test('does something', () {
      // Arrange
      // Act
      // Assert
    });
  });
}
```

**Widget Test Pattern:**
```dart
void main() {
  testWidgets('Widget does something', (tester) async {
    // Arrange
    await pumpThemedWidget(tester, MyWidget());

    // Act
    await tester.tap(find.byType(Button));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Result'), findsOneWidget);
  });
}
```

## References

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/testing)
- [Golden Toolkit](https://pub.dev/packages/golden_toolkit)

---

**Can start in parallel with PRD-004, 005, 006 after PRD-003!**
