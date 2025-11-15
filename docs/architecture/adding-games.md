# Developer Guide: Adding Games

This guide walks you through creating a new game for Keyboard Playground. By the end, you'll be able to add custom interactive games that respond to keyboard and mouse input.

## Table of Contents

- [Quick Start](#quick-start)
- [Understanding the Game Architecture](#understanding-the-game-architecture)
- [Creating Your First Game](#creating-your-first-game)
- [Handling Input Events](#handling-input-events)
- [Building the UI](#building-the-ui)
- [Testing Your Game](#testing-your-game)
- [Advanced Topics](#advanced-topics)
- [Example: Complete Game](#example-complete-game)

## Quick Start

**Time to create a basic game**: ~30 minutes

**Prerequisites**:
- Flutter SDK installed and configured
- Project cloned and dependencies installed (`flutter pub get`)
- Basic understanding of Flutter/Dart
- Familiarity with Widget-based UI

**Steps**:
1. Create a new file: `lib/games/my_game.dart`
2. Extend `BaseGame` class
3. Implement required methods
4. Register your game in `lib/main.dart`
5. Test and iterate

## Understanding the Game Architecture

### BaseGame Interface

All games must extend the `BaseGame` abstract class:

```dart
abstract class BaseGame {
  // Unique identifier (e.g., 'my_game')
  String get id;

  // Display name (e.g., 'My Awesome Game')
  String get name;

  // Short description for menus
  String get description;

  // Build the game UI (required)
  Widget buildUI();

  // Handle keyboard events (optional)
  void onKeyEvent(KeyEvent event) {}

  // Handle mouse events (optional)
  void onMouseEvent(InputEvent event) {}

  // Clean up resources (optional)
  void dispose() {}
}
```

### Game Lifecycle

1. **Registration**: Game is registered with `GameManager`
2. **Selection**: User selects game (or set as default)
3. **Initialization**: `buildUI()` is called to create the widget tree
4. **Active**: Game receives input events via `onKeyEvent()` and `onMouseEvent()`
5. **Disposal**: `dispose()` is called when switching games or app exits

### Event Flow

```
Keyboard/Mouse Input
  ↓
Platform Channel (Native Code)
  ↓
InputCapture (Dart)
  ↓
GameManager
  ↓
Active Game (onKeyEvent / onMouseEvent)
  ↓
Update Game State
  ↓
UI Rebuilds (via setState, ValueNotifier, etc.)
```

## Creating Your First Game

Let's create a simple game that shows circles where you click.

### Step 1: Create the Game File

Create `lib/games/circle_clicker_game.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:keyboard_playground/games/base_game.dart';
import 'package:keyboard_playground/platform/input_events.dart' as events;

class CircleClickerGame extends BaseGame {
  CircleClickerGame();

  // List of click positions
  final List<Offset> _clickPositions = [];

  // Notifier to trigger UI rebuilds
  final ValueNotifier<int> _updateNotifier = ValueNotifier<int>(0);

  @override
  String get id => 'circle_clicker';

  @override
  String get name => 'Circle Clicker';

  @override
  String get description => 'Click to create colorful circles!';

  @override
  Widget buildUI() {
    return Container(
      color: Colors.black,
      child: ValueListenableBuilder<int>(
        valueListenable: _updateNotifier,
        builder: (context, _, __) {
          return CustomPaint(
            painter: CirclePainter(_clickPositions),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  @override
  void onMouseEvent(events.InputEvent event) {
    // Only respond to mouse button events
    if (event is events.MouseButtonEvent && event.isDown) {
      // Add click position
      _clickPositions.add(Offset(event.x, event.y));

      // Limit to last 50 clicks
      if (_clickPositions.length > 50) {
        _clickPositions.removeAt(0);
      }

      // Trigger UI update
      _updateNotifier.value++;
    }
  }

  @override
  void dispose() {
    _updateNotifier.dispose();
    super.dispose();
  }
}

// Custom painter to draw circles
class CirclePainter extends CustomPainter {
  CirclePainter(this.positions);

  final List<Offset> positions;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    for (final position in positions) {
      canvas.drawCircle(position, 30, paint);
    }
  }

  @override
  bool shouldRepaint(CirclePainter oldDelegate) => true;
}
```

### Step 2: Register the Game

Edit `lib/main.dart` (around line 130):

```dart
// Step 6: Register games
debugPrint('Step 6: Registering games...');
_gameManager
  ..registerGame(PlaceholderGame())
  ..registerGame(ExplodingLettersGame())
  ..registerGame(KeyboardVisualizerGame())
  ..registerGame(MouseVisualizerGame())
  ..registerGame(CircleClickerGame())  // Add this line
  ..switchGame('circle_clicker');     // Or keep existing default
```

### Step 3: Run and Test

```bash
flutter run -d linux  # or macos, windows
```

Click around the screen - you should see blue circles appear!

## Handling Input Events

### Keyboard Events

The `KeyEvent` class provides information about key presses:

```dart
@override
void onKeyEvent(events.KeyEvent event) {
  // Event properties:
  print('Key: ${event.key}');           // e.g., 'a', 'Enter', 'Shift'
  print('Is down: ${event.isDown}');    // true = press, false = release
  print('Alt: ${event.altPressed}');    // Alt/Option modifier
  print('Ctrl: ${event.ctrlPressed}');  // Control modifier
  print('Shift: ${event.shiftPressed}'); // Shift modifier
  print('Meta: ${event.metaPressed}');  // Meta/Command/Windows modifier

  // Example: Respond only to key down events
  if (event.isDown) {
    // Do something
  }

  // Example: Filter modifier keys
  if (!_isModifierKey(event.key)) {
    // Handle regular keys only
  }
}

bool _isModifierKey(String key) {
  return key == 'Alt' ||
         key == 'Control' ||
         key == 'Shift' ||
         key == 'Meta' ||
         key == 'CapsLock';
}
```

### Mouse Events

Mouse events come in three types:

#### 1. Mouse Move Events

```dart
@override
void onMouseEvent(events.InputEvent event) {
  if (event is events.MouseMoveEvent) {
    final x = event.x;      // Screen X coordinate
    final y = event.y;      // Screen Y coordinate
    final dx = event.deltaX; // Movement delta X
    final dy = event.deltaY; // Movement delta Y

    // Update cursor position, trails, etc.
  }
}
```

#### 2. Mouse Button Events

```dart
@override
void onMouseEvent(events.InputEvent event) {
  if (event is events.MouseButtonEvent) {
    final x = event.x;
    final y = event.y;
    final isDown = event.isDown;  // true = press, false = release
    final button = event.button;  // MouseButton.left / right / middle

    // Example: Handle left click only
    if (button == events.MouseButton.left && isDown) {
      _handleLeftClick(Offset(x, y));
    }
  }
}
```

#### 3. Mouse Scroll Events

```dart
@override
void onMouseEvent(events.InputEvent event) {
  if (event is events.MouseScrollEvent) {
    final dx = event.deltaX;  // Horizontal scroll
    final dy = event.deltaY;  // Vertical scroll

    // Handle scroll wheel
  }
}
```

## Building the UI

### Option 1: Container with Custom Paint (Best for Graphics)

Use for particle systems, custom drawing, animations:

```dart
@override
Widget buildUI() {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
      ),
    ),
    child: CustomPaint(
      painter: MyCustomPainter(),
      size: Size.infinite,
    ),
  );
}
```

### Option 2: Stack with Positioned Widgets (Best for UI Elements)

Use for buttons, text, images, structured layouts:

```dart
@override
Widget buildUI() {
  return Container(
    color: Colors.black,
    child: Stack(
      children: [
        // Background
        const Positioned.fill(
          child: ColoredBox(color: Colors.blue),
        ),

        // Centered text
        const Center(
          child: Text(
            'Press any key!',
            style: TextStyle(fontSize: 48, color: Colors.white),
          ),
        ),

        // Dynamic elements
        ..._buildDynamicElements(),
      ],
    ),
  );
}
```

### Option 3: ValueListenableBuilder for Efficient Updates

Use to rebuild only parts of the UI that change:

```dart
final ValueNotifier<int> _scoreNotifier = ValueNotifier<int>(0);

@override
Widget buildUI() {
  return Container(
    child: ValueListenableBuilder<int>(
      valueListenable: _scoreNotifier,
      builder: (context, score, child) {
        return Text('Score: $score');
      },
    ),
  );
}

// Later, to update:
_scoreNotifier.value++;
```

### Responsive Design

Use `LayoutBuilder` to adapt to different screen sizes:

```dart
@override
Widget buildUI() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final screenWidth = constraints.maxWidth;
      final screenHeight = constraints.maxHeight;

      // Adjust UI based on screen size
      final fontSize = screenWidth < 1000 ? 24.0 : 48.0;

      return Text(
        'Hello!',
        style: TextStyle(fontSize: fontSize),
      );
    },
  );
}
```

## Testing Your Game

### Unit Tests

Create `test/unit/games/my_game_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:keyboard_playground/games/circle_clicker_game.dart';
import 'package:keyboard_playground/platform/input_events.dart' as events;

void main() {
  group('CircleClickerGame', () {
    late CircleClickerGame game;

    setUp(() {
      game = CircleClickerGame();
    });

    tearDown(() {
      game.dispose();
    });

    test('has correct metadata', () {
      expect(game.id, 'circle_clicker');
      expect(game.name, 'Circle Clicker');
      expect(game.description, isNotEmpty);
    });

    test('adds circle on mouse click', () {
      // Simulate mouse click
      final clickEvent = events.MouseButtonEvent(
        x: 100,
        y: 200,
        isDown: true,
        button: events.MouseButton.left,
      );

      game.onMouseEvent(clickEvent);

      // Verify circle was added (you'll need to expose this for testing)
      // expect(game.circles.length, 1);
    });
  });
}
```

### Widget Tests

Create `test/widget/games/my_game_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyboard_playground/games/circle_clicker_game.dart';

void main() {
  testWidgets('CircleClickerGame renders UI', (tester) async {
    final game = CircleClickerGame();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: game.buildUI(),
        ),
      ),
    );

    // Verify UI elements are present
    expect(find.byType(CustomPaint), findsOneWidget);

    game.dispose();
  });
}
```

### Manual Testing

```bash
# Run in debug mode for hot reload
flutter run -d linux --verbose

# Watch for errors in console
# Test all input types:
# - Keyboard: letters, numbers, modifiers, special keys
# - Mouse: movement, clicks, scroll
# - Exit sequence still works
```

## Advanced Topics

### Animation with Ticker

For smooth 60 FPS animations:

```dart
import 'dart:async';

class MyGame extends BaseGame {
  Timer? _animationTimer;

  void _startAnimation() {
    _animationTimer = Timer.periodic(
      const Duration(milliseconds: 16), // ~60 FPS
      (timer) {
        _updateAnimation();
      },
    );
  }

  void _updateAnimation() {
    // Update positions, velocities, etc.
    _notifier.value++;  // Trigger rebuild
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }
}
```

### Particle Systems

See `exploding_letters_game.dart` for a complete example:

```dart
class Particle {
  Offset position;
  Offset velocity;
  Color color;
  double opacity;
  double size;

  void update(double deltaTime) {
    position += velocity * deltaTime;
    velocity += Offset(0, 9.8 * deltaTime); // Gravity
    opacity -= deltaTime * 0.5;  // Fade out
  }

  bool get isAlive => opacity > 0;
}
```

### State Management

For complex games, consider using Provider or other state management:

```dart
class GameState extends ChangeNotifier {
  int _score = 0;

  int get score => _score;

  void increaseScore() {
    _score++;
    notifyListeners();
  }
}

// In buildUI():
return ChangeNotifierProvider(
  create: (_) => GameState(),
  child: Consumer<GameState>(
    builder: (context, state, child) {
      return Text('Score: ${state.score}');
    },
  ),
);
```

## Example: Complete Game

Here's a complete "Rainbow Keys" game that shows colorful circles for each key press:

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:keyboard_playground/games/base_game.dart';
import 'package:keyboard_playground/platform/input_events.dart' as events;

class RainbowKeysGame extends BaseGame {
  final List<_KeyCircle> _circles = [];
  final ValueNotifier<int> _updateNotifier = ValueNotifier<int>(0);
  final Random _random = Random();

  @override
  String get id => 'rainbow_keys';

  @override
  String get name => 'Rainbow Keys';

  @override
  String get description => 'Each key creates a rainbow circle!';

  @override
  Widget buildUI() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF000428), Color(0xFF004e92)],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ValueListenableBuilder<int>(
            valueListenable: _updateNotifier,
            builder: (context, _, __) {
              return CustomPaint(
                painter: _RainbowPainter(_circles),
                size: Size(constraints.maxWidth, constraints.maxHeight),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void onKeyEvent(events.KeyEvent event) {
    if (!event.isDown) return;
    if (_isModifierKey(event.key)) return;

    // Random position
    final x = _random.nextDouble() * 1920;
    final y = _random.nextDouble() * 1080;

    // Random color
    final color = Color.fromARGB(
      255,
      _random.nextInt(256),
      _random.nextInt(256),
      _random.nextInt(256),
    );

    _circles.add(_KeyCircle(
      position: Offset(x, y),
      color: color,
      letter: event.key,
      createdAt: DateTime.now(),
    ));

    // Limit circles
    if (_circles.length > 30) {
      _circles.removeAt(0);
    }

    _updateNotifier.value++;
  }

  bool _isModifierKey(String key) {
    return ['Alt', 'Control', 'Shift', 'Meta', 'CapsLock'].contains(key);
  }

  @override
  void dispose() {
    _updateNotifier.dispose();
  }
}

class _KeyCircle {
  final Offset position;
  final Color color;
  final String letter;
  final DateTime createdAt;

  _KeyCircle({
    required this.position,
    required this.color,
    required this.letter,
    required this.createdAt,
  });

  double get age => DateTime.now().difference(createdAt).inMilliseconds / 1000.0;
  double get opacity => (1.0 - age / 3.0).clamp(0.0, 1.0);
  double get size => 40 + (age * 20);
}

class _RainbowPainter extends CustomPainter {
  final List<_KeyCircle> circles;

  _RainbowPainter(this.circles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final circle in circles) {
      if (circle.opacity <= 0) continue;

      // Draw circle
      final paint = Paint()
        ..color = circle.color.withOpacity(circle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(circle.position, circle.size, paint);

      // Draw letter
      final textPainter = TextPainter(
        text: TextSpan(
          text: circle.letter.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(circle.opacity),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        circle.position - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_RainbowPainter oldDelegate) => true;
}
```

## Best Practices

1. **Performance**:
   - Limit number of active objects (particles, circles, etc.)
   - Use `RepaintBoundary` for static elements
   - Avoid rebuilding entire tree - use `ValueListenableBuilder`

2. **Memory Management**:
   - Always dispose controllers, notifiers, timers in `dispose()`
   - Limit history/state to reasonable sizes
   - Remove old objects regularly

3. **User Experience**:
   - Provide immediate visual feedback
   - Use bright, high-contrast colors for kids
   - Keep UI simple and uncluttered
   - Test on different screen sizes

4. **Code Quality**:
   - Follow the project's linting rules (`flutter analyze`)
   - Write tests for game logic
   - Document public APIs
   - Use meaningful variable names

## Checklist Before PR

- [ ] Game extends `BaseGame`
- [ ] All required methods implemented
- [ ] Game registered in `main.dart`
- [ ] Unit tests written and passing
- [ ] Widget tests written and passing
- [ ] Tested manually on at least one platform
- [ ] No lint errors (`flutter analyze`)
- [ ] Code formatted (`dart format .`)
- [ ] Documentation added
- [ ] Exit sequence still works with your game active

## Next Steps

- Study existing games: `exploding_letters_game.dart`, `keyboard_visualizer_game.dart`
- Read [Architecture Overview](architecture-overview.md)
- Check the [Contributing Guide](../../CONTRIBUTING.md)
- Share your game ideas in GitHub Discussions!

Happy game development! 🎮
