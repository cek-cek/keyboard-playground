/// Visual indicator showing progress through an exit sequence.
///
/// Displays a subtle progress bar and step counter when the user is actively
/// working through an exit sequence (keyboard or mouse).
library;

import 'package:flutter/material.dart';
import 'package:keyboard_playground/core/exit_handler.dart';

/// Widget that displays exit sequence progress.
///
/// Shows a small overlay in the top-right corner with:
/// - A progress bar indicating how many steps are complete
/// - Text showing current step / total steps
/// - Remaining time until timeout
///
/// The widget automatically hides when the sequence is idle and appears with
/// animation when the sequence starts.
///
/// Example usage:
/// ```dart
/// StreamBuilder<ExitProgress>(
///   stream: exitHandler.progressStream,
///   builder: (context, snapshot) {
///     final progress = snapshot.data ?? ExitProgress(
///       currentStep: 0,
///       totalSteps: 0,
///       remainingTime: Duration.zero,
///       state: ExitSequenceState.idle,
///     );
///     return ExitProgressIndicator(progress: progress);
///   },
/// )
/// ```
class ExitProgressIndicator extends StatelessWidget {
  /// Creates an exit progress indicator.
  const ExitProgressIndicator({
    required this.progress,
    super.key,
  });

  /// Current progress information.
  final ExitProgress progress;

  @override
  Widget build(BuildContext context) {
    // Always return a Positioned widget to maintain Stack layout consistency.
    // When idle, use an invisible/zero-size positioned widget instead of
    // SizedBox.shrink() to work around a rendering issue where the Stack
    // doesn't properly render its first child unless there's a Positioned
    // second child.
    return Positioned(
      top: 16,
      right: 16,
      child: IgnorePointer(
        ignoring: progress.state == ExitSequenceState.idle,
        child: AnimatedOpacity(
          opacity: progress.state == ExitSequenceState.idle ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  'Exit Sequence',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Progress bar
                SizedBox(
                  width: 150,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(progress.progress),
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Step counter and remaining time
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Step: ${progress.currentStep}/${progress.totalSteps}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${progress.remainingTime.inSeconds}s',
                      style: TextStyle(
                        color: _getTimeColor(progress.remainingTime),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Gets the progress bar color based on completion percentage.
  Color _getProgressColor(double progress) {
    if (progress < 0.5) {
      return Colors.blueAccent;
    } else if (progress < 0.8) {
      return Colors.lightBlueAccent;
    } else {
      return Colors.greenAccent;
    }
  }

  /// Gets the time color based on remaining time.
  ///
  /// Returns red when time is running out, yellow when medium, green when
  /// plenty.
  Color _getTimeColor(Duration remaining) {
    final seconds = remaining.inSeconds;
    if (seconds <= 2) {
      return Colors.redAccent;
    } else if (seconds <= 5) {
      return Colors.orangeAccent;
    } else {
      return Colors.greenAccent;
    }
  }
}

/// Widget that overlays the exit progress indicator on top of other content.
///
/// This is a convenience widget that wraps a child with a Stack and adds the
/// exit progress indicator on top.
///
/// Example usage:
/// ```dart
/// ExitProgressOverlay(
///   progress: exitProgress,
///   child: YourGameWidget(),
/// )
/// ```
class ExitProgressOverlay extends StatelessWidget {
  /// Creates an exit progress overlay.
  const ExitProgressOverlay({
    required this.progress,
    required this.child,
    super.key,
  });

  /// Current progress information.
  final ExitProgress progress;

  /// The child widget to overlay the progress indicator on.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        ExitProgressIndicator(progress: progress),
      ],
    );
  }
}
