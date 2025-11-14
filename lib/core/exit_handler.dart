/// Exit mechanism that requires a specific input sequence to close the app.
///
/// This prevents accidental exits while allowing intentional termination
/// through either a keyboard sequence (Alt+Ctrl+Right+Esc+Q) or mouse
/// sequence (clicking 4 corners in order).
library;

import 'dart:async';

import 'package:keyboard_playground/platform/input_capture.dart';
import 'package:keyboard_playground/platform/input_events.dart';

/// Type of exit sequence being tracked.
enum ExitSequenceType {
  /// Keyboard-based exit sequence.
  keyboard,

  /// Mouse-based exit sequence.
  mouse,
}

/// Current state of an exit sequence.
enum ExitSequenceState {
  /// No sequence in progress.
  idle,

  /// Sequence in progress, waiting for next step.
  inProgress,

  /// Sequence completed, exit should be triggered.
  completed,
}

/// Defines a specific exit sequence (keyboard or mouse).
class ExitSequence {
  /// Creates an exit sequence.
  const ExitSequence({
    required this.type,
    required this.steps,
    this.timeout = const Duration(seconds: 5),
  });

  /// Type of this sequence (keyboard or mouse).
  final ExitSequenceType type;

  /// Steps required to complete the sequence.
  ///
  /// For keyboard: key names (e.g., "Alt", "Control", "ArrowRight").
  /// For mouse: corner names (e.g., "topLeft", "topRight").
  final List<String> steps;

  /// Timeout duration for completing the sequence.
  final Duration timeout;

  /// Default keyboard exit sequence: Alt + Ctrl + Right Arrow + Escape + Q.
  ///
  /// This sequence requires pressing 5 specific keys in order within 5 seconds.
  /// Any wrong key or timeout resets the sequence.
  static const keyboardDefault = ExitSequence(
    type: ExitSequenceType.keyboard,
    steps: ['Alt', 'Control', 'ArrowRight', 'Escape', 'q'],
  );

  /// Default mouse exit sequence: click 4 corners clockwise starting from TL.
  ///
  /// This sequence requires clicking the four corners of the screen in order
  /// within 10 seconds. Each click must be within 50px of the corner.
  static const mouseDefault = ExitSequence(
    type: ExitSequenceType.mouse,
    steps: ['topLeft', 'topRight', 'bottomRight', 'bottomLeft'],
    timeout: Duration(seconds: 10),
  );
}

/// Progress information for an exit sequence.
class ExitProgress {
  /// Creates exit progress information.
  const ExitProgress({
    required this.currentStep,
    required this.totalSteps,
    required this.remainingTime,
    required this.state,
  });

  /// Current step in the sequence (0-based).
  final int currentStep;

  /// Total number of steps in the sequence.
  final int totalSteps;

  /// Remaining time before timeout.
  final Duration remainingTime;

  /// Current state of the sequence.
  final ExitSequenceState state;

  /// Progress as a fraction (0.0 to 1.0).
  double get progress => totalSteps > 0 ? currentStep / totalSteps : 0.0;

  /// Whether the sequence has been completed.
  bool get isCompleted => state == ExitSequenceState.completed;

  @override
  String toString() {
    return 'ExitProgress(step: $currentStep/$totalSteps, '
        'remaining: ${remainingTime.inSeconds}s, state: $state)';
  }
}

/// Handles exit sequences for the application.
///
/// Monitors input events and tracks progress through keyboard and mouse exit
/// sequences. Emits progress updates and triggers exit when a sequence is
/// completed.
///
/// Example usage:
/// ```dart
/// final exitHandler = ExitHandler(inputCapture: inputCapture);
///
/// // Listen to progress updates
/// exitHandler.progressStream.listen((progress) {
///   print('Exit progress: ${progress.progress * 100}%');
/// });
///
/// // Listen for exit trigger
/// exitHandler.exitTriggered.listen((_) {
///   print('Exit sequence completed!');
///   // Perform cleanup and exit
/// });
/// ```
class ExitHandler {
  /// Creates an exit handler.
  ExitHandler({
    required InputCapture inputCapture,
    ExitSequence? keyboardSequence,
    ExitSequence? mouseSequence,
    this.screenWidth = 1920.0,
    this.screenHeight = 1080.0,
    this.cornerThreshold = 50.0,
  })  : _inputCapture = inputCapture,
        _keyboardSequence = keyboardSequence ?? ExitSequence.keyboardDefault,
        _mouseSequence = mouseSequence ?? ExitSequence.mouseDefault {
    _setupListeners();
  }

  final InputCapture _inputCapture;
  final ExitSequence _keyboardSequence;
  final ExitSequence _mouseSequence;

  /// Screen width in pixels (TODO: get from window manager - PRD-006).
  final double screenWidth;

  /// Screen height in pixels (TODO: get from window manager - PRD-006).
  final double screenHeight;

  /// Distance threshold from corner in pixels.
  final double cornerThreshold;

  final StreamController<ExitProgress> _progressController =
      StreamController<ExitProgress>.broadcast();
  final StreamController<void> _exitTriggeredController =
      StreamController<void>.broadcast();

  int _currentKeyboardStep = 0;
  int _currentMouseStep = 0;
  Timer? _keyboardTimer;
  Timer? _mouseTimer;
  DateTime? _keyboardSequenceStartTime;
  DateTime? _mouseSequenceStartTime;

  StreamSubscription<InputEvent>? _inputSubscription;

  /// Stream of exit progress updates.
  ///
  /// Emits progress information whenever the sequence advances, resets, or
  /// completes. Can be used to display visual feedback to the user.
  Stream<ExitProgress> get progressStream => _progressController.stream;

  /// Stream that emits when an exit sequence is successfully completed.
  ///
  /// Listen to this stream to perform cleanup and exit the application.
  Stream<void> get exitTriggered => _exitTriggeredController.stream;

  /// Current keyboard sequence step (0-based).
  int get currentKeyboardStep => _currentKeyboardStep;

  /// Current mouse sequence step (0-based).
  int get currentMouseStep => _currentMouseStep;

  void _setupListeners() {
    _inputSubscription = _inputCapture.events.listen((event) {
      if (event is KeyEvent && event.isDown) {
        _handleKeyEvent(event);
      } else if (event is MouseButtonEvent && event.isDown) {
        _handleMouseEvent(event);
      }
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    // Get the expected key for the current step
    if (_currentKeyboardStep >= _keyboardSequence.steps.length) {
      return;
    }

    final expectedKey = _keyboardSequence.steps[_currentKeyboardStep];

    if (event.key == expectedKey) {
      // Correct key pressed
      _currentKeyboardStep++;

      // Start or reset the timer
      if (_currentKeyboardStep == 1) {
        _keyboardSequenceStartTime = DateTime.now();
      }
      _startKeyboardTimer();
      _emitKeyboardProgress();

      // Check if sequence is complete
      if (_currentKeyboardStep >= _keyboardSequence.steps.length) {
        _triggerExit();
      }
    } else {
      // Wrong key pressed, reset sequence
      if (_currentKeyboardStep > 0) {
        _resetKeyboard();
      }
    }
  }

  void _handleMouseEvent(MouseButtonEvent event) {
    // Only handle left clicks
    if (event.button != MouseButton.left) return;

    // Get the expected corner for the current step
    if (_currentMouseStep >= _mouseSequence.steps.length) {
      return;
    }

    final corner = _getCorner(event.x, event.y);
    if (corner == null) {
      // Click was not near any corner
      if (_currentMouseStep > 0) {
        _resetMouse();
      }
      return;
    }

    final expectedCorner = _mouseSequence.steps[_currentMouseStep];

    if (corner == expectedCorner) {
      // Correct corner clicked
      _currentMouseStep++;

      // Start or reset the timer
      if (_currentMouseStep == 1) {
        _mouseSequenceStartTime = DateTime.now();
      }
      _startMouseTimer();
      _emitMouseProgress();

      // Check if sequence is complete
      if (_currentMouseStep >= _mouseSequence.steps.length) {
        _triggerExit();
      }
    } else {
      // Wrong corner clicked, reset sequence
      if (_currentMouseStep > 0) {
        _resetMouse();
      }
    }
  }

  /// Determines which corner (if any) the given coordinates are near.
  ///
  /// Returns the corner name ('topLeft', 'topRight', 'bottomRight',
  /// 'bottomLeft') or null if not near any corner.
  String? _getCorner(double x, double y) {
    final threshold = cornerThreshold;

    // Check each corner
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
    _keyboardSequenceStartTime = null;
    _emitKeyboardProgress();
  }

  void _resetMouse() {
    _currentMouseStep = 0;
    _mouseTimer?.cancel();
    _mouseSequenceStartTime = null;
    _emitMouseProgress();
  }

  void _emitKeyboardProgress() {
    final remainingTime = _calculateRemainingTime(
      _keyboardSequenceStartTime,
      _keyboardSequence.timeout,
    );

    final progress = ExitProgress(
      currentStep: _currentKeyboardStep,
      totalSteps: _keyboardSequence.steps.length,
      remainingTime: remainingTime,
      state: _currentKeyboardStep > 0
          ? ExitSequenceState.inProgress
          : ExitSequenceState.idle,
    );

    _progressController.add(progress);
  }

  void _emitMouseProgress() {
    final remainingTime = _calculateRemainingTime(
      _mouseSequenceStartTime,
      _mouseSequence.timeout,
    );

    final progress = ExitProgress(
      currentStep: _currentMouseStep,
      totalSteps: _mouseSequence.steps.length,
      remainingTime: remainingTime,
      state: _currentMouseStep > 0
          ? ExitSequenceState.inProgress
          : ExitSequenceState.idle,
    );

    _progressController.add(progress);
  }

  Duration _calculateRemainingTime(
    DateTime? startTime,
    Duration timeout,
  ) {
    if (startTime == null) {
      return timeout;
    }

    final elapsed = DateTime.now().difference(startTime);
    final remaining = timeout - elapsed;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  void _triggerExit() {
    // Emit completed state
    _progressController.add(
      ExitProgress(
        currentStep: _keyboardSequence.steps.length,
        totalSteps: _keyboardSequence.steps.length,
        remainingTime: Duration.zero,
        state: ExitSequenceState.completed,
      ),
    );

    // Trigger exit
    _exitTriggeredController.add(null);

    // Reset both sequences
    _resetKeyboard();
    _resetMouse();
  }

  /// Disposes of resources used by this handler.
  ///
  /// Cancels timers, closes streams, and cleans up listeners.
  Future<void> dispose() async {
    _keyboardTimer?.cancel();
    _mouseTimer?.cancel();
    await _inputSubscription?.cancel();
    await _progressController.close();
    await _exitTriggeredController.close();
  }
}
