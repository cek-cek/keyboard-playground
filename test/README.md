# Testing Guide for Keyboard Playground

This directory contains all tests and testing utilities for the Keyboard Playground project.

## Directory Structure

```
test/
├── unit/                           # Unit tests (pure Dart logic)
│   ├── core/                       # Core functionality tests
│   ├── games/                      # Game logic tests
│   ├── platform/                   # Platform layer tests
│   └── test_utils/                 # Tests for test utilities
├── widget/                         # Widget tests (UI components)
│   ├── ui/                         # App-level UI tests
│   └── widgets/                    # Individual widget tests
├── integration/                    # Integration tests (end-to-end)
│   └── app_test.dart               # Full app integration tests
├── golden/                         # Golden file outputs
│   └── .gitkeep
├── fixtures/                       # Test data and fixtures
│   └── events.dart                 # Pre-built event sequences
└── test_utils/                     # Test utilities and helpers
    ├── mocks/                      # Mock implementations
    │   ├── mock_input_capture.dart
    │   ├── mock_window_control.dart
    │   └── mock_game_manager.dart
    ├── builders/                   # Event builders
    │   └── event_builder.dart
    ├── helpers/                    # Test helpers
    │   ├── widget_test_helpers.dart
    │   └── integration_test_helpers.dart
    └── matchers/                   # Custom matchers
        └── custom_matchers.dart
```

## Running Tests

### All Tests

```bash
make test
```

### Specific Test File

```bash
flutter test test/unit/core/exit_handler_test.dart
```

### With Coverage

```bash
make coverage
```

### Integration Tests

```bash
flutter test integration_test/
```

## Test Utilities

### Mock Implementations

#### MockInputCapture

Mock implementation of `InputCapture` for simulating input events.

```dart
import 'package:keyboard_playground/test/test_utils/mocks/mock_input_capture.dart';
import 'package:keyboard_playground/test/test_utils/builders/event_builder.dart';

final mockInput = MockInputCapture();

// Emit a key event
mockInput.emitEvent(EventBuilder.keyDown('a'));

// Emit multiple events
mockInput.emitEvents([
  EventBuilder.keyDown('h'),
  EventBuilder.keyUp('h'),
  EventBuilder.keyDown('i'),
  EventBuilder.keyUp('i'),
]);
```

#### MockWindowControl

Mock implementation for window management operations.

```dart
import 'package:keyboard_playground/test/test_utils/mocks/mock_window_control.dart';

final mockWindow = MockWindowControl();

// Configure screen size
mockWindow.screenSize = const Size(1920, 1080);

// Test fullscreen
await mockWindow.enterFullscreen();
expect(mockWindow.isFullscreen, true);
```

#### MockGameManager

Mock implementation for game management.

```dart
import 'package:keyboard_playground/test/test_utils/mocks/mock_game_manager.dart';

final mockManager = MockGameManager();
mockManager.registerGame(testGame);
mockManager.switchGame(testGame.id);
```

### Event Builders

Create test events easily with `EventBuilder`.

```dart
import 'package:keyboard_playground/test/test_utils/builders/event_builder.dart';

// Create key events
final keyDown = EventBuilder.keyDown('a');
final keyUp = EventBuilder.keyUp('a');
final keyPress = EventBuilder.keyPress('a'); // Returns [down, up]

// Create key events with modifiers
final shiftA = EventBuilder.keyDown(
  'A',
  modifiers: {KeyModifier.shift},
);

// Create mouse events
final mouseMove = EventBuilder.mouseMove(100, 200);
final mouseClick = EventBuilder.mouseClick(100, 200);
final mouseDown = EventBuilder.mouseDown(100, 200);
final mouseUp = EventBuilder.mouseUp(100, 200);
final scroll = EventBuilder.mouseScroll(deltaY: -120);
```

### Event Fixtures

Pre-built event sequences for common scenarios.

```dart
import 'package:keyboard_playground/test/fixtures/events.dart';

// Use pre-built sequences
mockInput.emitEvents(EventFixtures.typingHello);
mockInput.emitEvents(EventFixtures.exitSequence);
mockInput.emitEvents(EventFixtures.cornerClicks());

// Generate custom sequences
final circleMovement = EventFixtures.circleMouseMovement(
  960, 540, // center
  200,      // radius
  20,       // steps
);

final rapidTyping = EventFixtures.rapidTyping('hello world');
```

### Widget Test Helpers

Helpers for widget testing.

```dart
import 'package:keyboard_playground/test/test_utils/helpers/widget_test_helpers.dart';

testWidgets('MyWidget displays correctly', (tester) async {
  // Pump widget with app theme
  await pumpThemedWidget(tester, MyWidget());

  // Find by test key
  expect(findByTestKey('my_button'), findsOneWidget);

  // Tap and settle
  await tapAndSettle(tester, findByTestKey('my_button'));

  // Wait for animations
  await waitForAnimations(tester);

  // Pump for specific duration
  await pumpForDuration(tester, Duration(seconds: 2));
});
```

### Custom Matchers

Test input events with custom matchers.

```dart
import 'package:keyboard_playground/test/test_utils/matchers/custom_matchers.dart';

// Match key events
expect(event, isKeyEvent(key: 'a', isDown: true));
expect(event, isKeyEvent(modifiers: {KeyModifier.shift}));

// Match mouse events
expect(event, isMouseButtonEvent(button: MouseButton.left));
expect(event, isMouseButtonEvent(x: 100, y: 200, isDown: true));
expect(event, isMouseMoveEvent(x: 100, y: 200));
expect(event, isMouseScrollEvent(deltaY: -120));

// Match event streams
expect(
  eventStream,
  emitsInOrder([
    isKeyEvent(key: 'a'),
    isKeyEvent(key: 'b'),
  ]),
);
```

### Integration Test Helpers

Helpers for integration tests.

```dart
import 'package:keyboard_playground/test/test_utils/helpers/integration_test_helpers.dart';

// Wait for a condition
await IntegrationTestHelpers.waitFor(
  () => myValue == expectedValue,
  timeout: Duration(seconds: 5),
);

// Wait for widget to appear
await IntegrationTestHelpers.waitForWidget(
  tester,
  find.byType(MyWidget),
);

// Measure execution time
final duration = await IntegrationTestHelpers.measureTime(() async {
  await someExpensiveOperation();
});

// Measure frame rate
final fps = await IntegrationTestHelpers.measureFrameRate(
  tester,
  Duration(seconds: 5),
);
```

## Writing Tests

### Unit Test Pattern

Use the Arrange-Act-Assert pattern:

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
      // Arrange: Set up test data
      final input = 'test';

      // Act: Execute the functionality
      final result = sut.doSomething(input);

      // Assert: Verify the result
      expect(result, 'expected');
    });
  });
}
```

### Widget Test Pattern

```dart
void main() {
  testWidgets('Widget does something', (tester) async {
    // Arrange: Build the widget
    await pumpThemedWidget(tester, MyWidget());

    // Act: Interact with the widget
    await tester.tap(find.byType(Button));
    await tester.pumpAndSettle();

    // Assert: Verify the result
    expect(find.text('Result'), findsOneWidget);
  });
}
```

### Integration Test Pattern

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Feature Integration Tests', () {
    testWidgets('Feature works end-to-end', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Interact with the app
      await IntegrationTestHelpers.waitForWidget(
        tester,
        find.byType(HomeScreen),
      );

      // Verify behavior
      expect(find.text('Welcome'), findsOneWidget);
    });
  });
}
```

## Coverage Goals

- **Business logic**: 100% coverage
- **UI widgets**: >90% coverage
- **Platform channels**: Mock and test Dart side only
- **Integration tests**: Critical paths only

## Testing Principles

1. **Tests should be easy to write** - Use provided utilities and helpers
2. **Tests should be fast** - Unit tests <5s, Widget tests <30s
3. **Tests should be reliable** - No flaky tests, deterministic results
4. **Tests should document behavior** - Clear test names and assertions

## CI/CD Integration

All tests run automatically in CI:

```yaml
# .github/workflows/ci.yml
- name: Run tests
  run: flutter test --coverage
```

Tests must pass before code can be merged.

## Pre-Push Hook

A git pre-push hook runs `make ci` (format, analyze, test) before every push.
This ensures code quality and prevents broken code from being pushed.

To bypass (not recommended):
```bash
git push --no-verify
```

## Golden File Testing

Golden file tests are not yet implemented but the infrastructure is in place.

To generate golden files:
```bash
flutter test --update-goldens
```

## Performance Testing

Basic performance testing utilities are available:

```dart
// Measure execution time
final duration = await IntegrationTestHelpers.measureTime(() async {
  await expensiveOperation();
});
expect(duration.inMilliseconds, lessThan(100));

// Measure frame rate
final fps = await IntegrationTestHelpers.measureFrameRate(
  tester,
  Duration(seconds: 2),
);
expect(fps, greaterThan(30)); // Minimum 30 FPS
```

## Troubleshooting

### Tests Not Found

Make sure you're in the project root:
```bash
cd /path/to/keyboard-playground
flutter test
```

### Import Errors

Run `flutter pub get` to install dependencies:
```bash
flutter pub get
```

### Flaky Tests

- Ensure proper use of `await tester.pumpAndSettle()`
- Use `waitFor` for async conditions
- Avoid hardcoded delays
- Use fixtures instead of `DateTime.now()` for timestamps

### Coverage Not Generated

Install lcov:
```bash
sudo apt-get install lcov  # Linux
brew install lcov          # macOS
```

## Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/testing)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Test Coverage](https://docs.flutter.dev/testing/code-coverage)

## Contributing

When adding new tests:

1. Place tests in the appropriate directory (unit/widget/integration)
2. Follow the established patterns
3. Use the provided utilities and helpers
4. Ensure tests are fast and reliable
5. Add documentation for complex test scenarios
6. Maintain >90% code coverage

## Questions?

Check the test utilities source code for more examples and documentation.
