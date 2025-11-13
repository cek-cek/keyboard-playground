# PRD-005: Exit Mechanism

**Status**: ⚪ Not Started
**Dependencies**: PRD-003 (Build System & CI/CD)
**Estimated Effort**: 4 hours
**Priority**: P0 - CRITICAL
**Branch**: `feature/prd-005-exit-mechanism`

## Overview

Implement a secure exit mechanism that requires a specific, non-trivial input combination to close the application. This prevents accidental exits while allowing intentional termination.

## Context

The app needs to be "hard to exit" so kids don't accidentally close it. However, parents/adults need a reliable way to exit. The mechanism must be:
- Hard enough that random key mashing won't trigger it
- Memorable enough that adults can execute it
- Implemented such that it works even if system shortcuts are captured

## Goals

1. ✅ Multi-step exit sequence that's hard to accidentally trigger
2. ✅ Visual feedback showing progress through sequence
3. ✅ Sequence resets if wrong input or timeout occurs
4. ✅ Alternative mouse-based exit (4-corner click sequence)
5. ✅ Configurable timeout and sequence

## Non-Goals

- Password protection (too complex for this use case)
- User-configurable sequences (hardcoded for now)
- Multiple different exit sequences

## Requirements

### Functional Requirements

**FR-001**: Keyboard Exit Sequence
- Default: Left Alt + Left Ctrl + Right Arrow + Escape + Q (in order)
- Must be pressed in sequence within 5 seconds
- Any wrong key resets sequence
- Timeout resets sequence

**FR-002**: Mouse Exit Sequence (Alternative)
- Click corners in order: Top-Left → Top-Right → Bottom-Right → Bottom-Left
- Must complete within 10 seconds
- Each click must be within 50px of corner
- Wrong corner resets sequence

**FR-003**: Visual Feedback
- Progress indicator shows how many steps completed
- Timer shows remaining time
- Subtle UI to not distract from games

**FR-004**: Sequence Monitoring
- Listens to input events from InputCapture (PRD-004)
- State machine tracks progress
- Emits events when exit triggered

**FR-005**: Graceful Exit
- Stops input capture
- Cleans up resources
- Closes window

### Non-Functional Requirements

**NFR-001**: Security
- Cannot be accidentally triggered (<0.01% false positive rate)
- Reliable trigger when intentional (>99.9% success rate)

**NFR-002**: Responsiveness
- Immediate visual feedback on each step (<16ms)
- Smooth animations for progress indicator

## Technical Specifications

### Exit Handler Architecture

```dart
// lib/core/exit_handler.dart

enum ExitSequenceType {
  keyboard,
  mouse,
}

enum ExitSequenceState {
  idle,
  inProgress,
  completed,
}

class ExitSequence {
  final ExitSequenceType type;
  final List<String> steps;  // For keyboard: key names
  final Duration timeout;

  const ExitSequence({
    required this.type,
    required this.steps,
    this.timeout = const Duration(seconds: 5),
  });

  static const keyboardDefault = ExitSequence(
    type: ExitSequenceType.keyboard,
    steps: ['AltLeft', 'ControlLeft', 'ArrowRight', 'Escape', 'KeyQ'],
    timeout: Duration(seconds: 5),
  );

  static const mouseDefault = ExitSequence(
    type: ExitSequenceType.mouse,
    steps: ['topLeft', 'topRight', 'bottomRight', 'bottomLeft'],
    timeout: Duration(seconds: 10),
  );
}

class ExitProgress {
  final int currentStep;
  final int totalSteps;
  final Duration remainingTime;
  final ExitSequenceState state;

  const ExitProgress({
    required this.currentStep,
    required this.totalSteps,
    required this.remainingTime,
    required this.state,
  });

  double get progress => currentStep / totalSteps;
  bool get isCompleted => state == ExitSequenceState.completed;
}

class ExitHandler {
  final InputCapture _inputCapture;
  final ExitSequence _keyboardSequence;
  final ExitSequence _mouseSequence;

  StreamController<ExitProgress> _progressController =
      StreamController<ExitProgress>.broadcast();
  StreamController<void> _exitTriggeredController =
      StreamController<void>.broadcast();

  int _currentKeyboardStep = 0;
  int _currentMouseStep = 0;
  Timer? _keyboardTimer;
  Timer? _mouseTimer;

  ExitHandler({
    required InputCapture inputCapture,
    ExitSequence? keyboardSequence,
    ExitSequence? mouseSequence,
  })  : _inputCapture = inputCapture,
        _keyboardSequence = keyboardSequence ?? ExitSequence.keyboardDefault,
        _mouseSequence = mouseSequence ?? ExitSequence.mouseDefault {
    _setupListeners();
  }

  /// Stream of exit progress updates
  Stream<ExitProgress> get progressStream => _progressController.stream;

  /// Stream that emits when exit is triggered
  Stream<void> get exitTriggered => _exitTriggeredController.stream;

  void _setupListeners() {
    _inputCapture.events.listen((event) {
      if (event is KeyEvent && event.isDown) {
        _handleKeyEvent(event);
      } else if (event is MouseButtonEvent && event.isDown) {
        _handleMouseEvent(event);
      }
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    final expectedKey = _keyboardSequence.steps[_currentKeyboardStep];

    if (event.key == expectedKey) {
      _currentKeyboardStep++;
      _startKeyboardTimer();
      _emitProgress(ExitSequenceType.keyboard);

      if (_currentKeyboardStep >= _keyboardSequence.steps.length) {
        _triggerExit();
      }
    } else {
      // Wrong key, reset
      _resetKeyboard();
    }
  }

  void _handleMouseEvent(MouseButtonEvent event) {
    if (event.button != MouseButton.left) return;

    final corner = _getCorner(event.x, event.y);
    if (corner == null) {
      _resetMouse();
      return;
    }

    final expectedCorner = _mouseSequence.steps[_currentMouseStep];

    if (corner == expectedCorner) {
      _currentMouseStep++;
      _startMouseTimer();
      _emitProgress(ExitSequenceType.mouse);

      if (_currentMouseStep >= _mouseSequence.steps.length) {
        _triggerExit();
      }
    } else {
      // Wrong corner, reset
      _resetMouse();
    }
  }

  String? _getCorner(double x, double y) {
    const threshold = 50.0;  // pixels from corner
    // TODO: Get screen size from window manager (PRD-006)
    const screenWidth = 1920.0;  // Placeholder
    const screenHeight = 1080.0;  // Placeholder

    if (x < threshold && y < threshold) return 'topLeft';
    if (x > screenWidth - threshold && y < threshold) return 'topRight';
    if (x > screenWidth - threshold && y > screenHeight - threshold) {
      return 'bottomRight';
    }
    if (x < threshold && y > screenHeight - threshold) return 'bottomLeft';

    return null;
  }

  void _startKeyboardTimer() {
    _keyboardTimer?.cancel();
    _keyboardTimer = Timer(_keyboardSequence.timeout, _resetKeyboard);
  }

  void _startMouseTimer() {
    _mouseTimer?.cancel();
    _mouseTimer = Timer(_mouseSequence.timeout, _resetMouse);
  }

  void _resetKeyboard() {
    _currentKeyboardStep = 0;
    _keyboardTimer?.cancel();
    _emitProgress(ExitSequenceType.keyboard);
  }

  void _resetMouse() {
    _currentMouseStep = 0;
    _mouseTimer?.cancel();
    _emitProgress(ExitSequenceType.mouse);
  }

  void _emitProgress(ExitSequenceType type) {
    final sequence = type == ExitSequenceType.keyboard
        ? _keyboardSequence
        : _mouseSequence;
    final currentStep = type == ExitSequenceType.keyboard
        ? _currentKeyboardStep
        : _currentMouseStep;

    final progress = ExitProgress(
      currentStep: currentStep,
      totalSteps: sequence.steps.length,
      remainingTime: sequence.timeout,  // TODO: Track actual remaining time
      state: currentStep > 0
          ? ExitSequenceState.inProgress
          : ExitSequenceState.idle,
    );

    _progressController.add(progress);
  }

  void _triggerExit() {
    _progressController.add(
      ExitProgress(
        currentStep: _keyboardSequence.steps.length,
        totalSteps: _keyboardSequence.steps.length,
        remainingTime: Duration.zero,
        state: ExitSequenceState.completed,
      ),
    );

    _exitTriggeredController.add(null);
  }

  Future<void> dispose() async {
    _keyboardTimer?.cancel();
    _mouseTimer?.cancel();
    await _progressController.close();
    await _exitTriggeredController.close();
  }
}
```

### Visual Feedback Widget

```dart
// lib/widgets/exit_progress_indicator.dart

class ExitProgressIndicator extends StatelessWidget {
  final ExitProgress progress;

  const ExitProgressIndicator({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    if (progress.state == ExitSequenceState.idle) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 16,
      right: 16,
      child: AnimatedOpacity(
        opacity: progress.state == ExitSequenceState.idle ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Exit Sequence',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress.progress,
                backgroundColor: Colors.white30,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.greenAccent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${progress.currentStep}/${progress.totalSteps}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Acceptance Criteria

### Keyboard Exit Sequence

- [ ] Correct sequence (Alt+Ctrl+Right+Esc+Q) triggers exit
- [ ] Wrong key at any point resets sequence
- [ ] Timeout (5 seconds) resets sequence
- [ ] Partial progress persists until timeout or wrong key
- [ ] Works regardless of which game is active

### Mouse Exit Sequence

- [ ] Clicking 4 corners in order triggers exit
- [ ] Corner detection uses 50px threshold
- [ ] Wrong corner resets sequence
- [ ] Timeout (10 seconds) resets sequence

### Visual Feedback

- [ ] Progress indicator appears when sequence starts
- [ ] Progress bar updates on each correct step
- [ ] Indicator shows current step / total steps
- [ ] Indicator disappears on timeout or completion
- [ ] Smooth animations

### Exit Behavior

- [ ] `exitTriggered` stream emits when sequence completes
- [ ] App cleanup happens before exit
- [ ] Window closes gracefully

### Testing

- [ ] Unit tests for state machine logic
- [ ] Unit tests for timeout behavior
- [ ] Widget tests for progress indicator
- [ ] Integration tests for full sequence
- [ ] Manual testing of accidental trigger resistance

## Implementation Steps

### Step 1: Create ExitHandler Class (2 hours)

1. Create `lib/core/exit_handler.dart`
2. Implement state machine for keyboard sequence
3. Implement state machine for mouse sequence
4. Implement timeout logic
5. Unit tests

### Step 2: Create Visual Feedback (1 hour)

1. Create `lib/widgets/exit_progress_indicator.dart`
2. Implement progress bar UI
3. Widget tests

### Step 3: Integration (1 hour)

1. Wire up to InputCapture
2. Integration tests
3. Manual testing

## Testing Requirements

### Unit Tests

```dart
// test/unit/core/exit_handler_test.dart
void main() {
  group('ExitHandler', () {
    test('completes keyboard sequence correctly', () {
      // Test full sequence
    });

    test('resets on wrong key', () {
      // Test reset logic
    });

    test('resets on timeout', () {
      // Test timeout logic
    });

    test('completes mouse sequence correctly', () {
      // Test corner clicks
    });

    test('does not trigger on random input', () {
      // Fuzz test with random input
    });
  });
}
```

### Manual Testing Checklist

- [ ] Complete keyboard sequence successfully
- [ ] Press wrong key mid-sequence, verify reset
- [ ] Wait for timeout mid-sequence, verify reset
- [ ] Complete mouse sequence successfully
- [ ] Click wrong corner, verify reset
- [ ] Try to accidentally trigger (random mashing)
- [ ] Verify false positive rate <0.01%

## Definition of Done

- [ ] All acceptance criteria met
- [ ] Unit tests pass (>90% coverage)
- [ ] Widget tests pass
- [ ] Integration tests pass
- [ ] Manual testing complete
- [ ] Code review passed
- [ ] DEPENDENCIES.md updated

## Notes for AI Agents

### Key Design Decisions

**Why this keyboard sequence?**
- Left Alt + Left Ctrl: Requires two hands or awkward single hand
- Right Arrow: Unusual in combination
- Escape + Q: Clear "exit" intention

**Why these corners?**
- Forms a path that requires intentional mouse movement
- Hard to accidentally complete

### Time Breakdown

- ExitHandler implementation: 2 hours
- Visual feedback: 1 hour
- Integration & testing: 1 hour
- **Total**: 4 hours

### Testing Tip

Create a test mode that uses a shorter sequence (e.g., just "E" + "X" + "I" + "T") for faster testing.

## References

- InputCapture API (PRD-004)
- Window management (PRD-006)

---

**Can start in parallel with PRD-004, 006, 007 after PRD-003!**
