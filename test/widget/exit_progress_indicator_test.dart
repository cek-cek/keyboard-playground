import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyboard_playground/core/exit_handler.dart';
import 'package:keyboard_playground/widgets/exit_progress_indicator.dart';

void main() {
  group('ExitProgressIndicator', () {
    testWidgets('hides when sequence is idle', (WidgetTester tester) async {
      const progress = ExitProgress(
        currentStep: 0,
        totalSteps: 5,
        remainingTime: Duration(seconds: 5),
        state: ExitSequenceState.idle,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExitProgressIndicator(progress: progress),
          ),
        ),
      );

      // Should render as SizedBox.shrink() when idle
      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.text('Exit Sequence'), findsNothing);
    });

    testWidgets('shows progress indicator when sequence is in progress',
        (WidgetTester tester) async {
      const progress = ExitProgress(
        currentStep: 2,
        totalSteps: 5,
        remainingTime: Duration(seconds: 3),
        state: ExitSequenceState.inProgress,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ExitProgressIndicator(progress: progress),
              ],
            ),
          ),
        ),
      );

      // Should show the indicator
      expect(find.text('Exit Sequence'), findsOneWidget);
      expect(find.text('Step: 2/5'), findsOneWidget);
      expect(find.text('3s'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('displays correct step count', (WidgetTester tester) async {
      const progress = ExitProgress(
        currentStep: 3,
        totalSteps: 5,
        remainingTime: Duration(seconds: 2),
        state: ExitSequenceState.inProgress,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ExitProgressIndicator(progress: progress),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Step: 3/5'), findsOneWidget);
    });

    testWidgets('displays remaining time correctly',
        (WidgetTester tester) async {
      const progress = ExitProgress(
        currentStep: 1,
        totalSteps: 5,
        remainingTime: Duration(seconds: 7),
        state: ExitSequenceState.inProgress,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ExitProgressIndicator(progress: progress),
              ],
            ),
          ),
        ),
      );

      expect(find.text('7s'), findsOneWidget);
    });

    testWidgets('positioned in top-right corner', (WidgetTester tester) async {
      const progress = ExitProgress(
        currentStep: 2,
        totalSteps: 5,
        remainingTime: Duration(seconds: 3),
        state: ExitSequenceState.inProgress,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ExitProgressIndicator(progress: progress),
              ],
            ),
          ),
        ),
      );

      final positioned = tester.widget<Positioned>(
        find.byType(Positioned),
      );

      expect(positioned.top, 16);
      expect(positioned.right, 16);
    });

    testWidgets('has correct opacity animation', (WidgetTester tester) async {
      const progressIdle = ExitProgress(
        currentStep: 0,
        totalSteps: 5,
        remainingTime: Duration(seconds: 5),
        state: ExitSequenceState.idle,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ExitProgressIndicator(progress: progressIdle),
              ],
            ),
          ),
        ),
      );

      // When idle, should be SizedBox.shrink()
      expect(find.byType(AnimatedOpacity), findsNothing);

      // Now show progress
      const progressActive = ExitProgress(
        currentStep: 2,
        totalSteps: 5,
        remainingTime: Duration(seconds: 3),
        state: ExitSequenceState.inProgress,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ExitProgressIndicator(progress: progressActive),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedOpacity), findsOneWidget);
      final animatedOpacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(animatedOpacity.opacity, 1.0);
    });

    testWidgets('progress bar shows correct value',
        (WidgetTester tester) async {
      const progress = ExitProgress(
        currentStep: 3,
        totalSteps: 5,
        remainingTime: Duration(seconds: 2),
        state: ExitSequenceState.inProgress,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ExitProgressIndicator(progress: progress),
              ],
            ),
          ),
        ),
      );

      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );

      // 3 out of 5 = 0.6
      expect(progressBar.value, closeTo(0.6, 0.01));
    });

    testWidgets('handles completed state', (WidgetTester tester) async {
      const progress = ExitProgress(
        currentStep: 5,
        totalSteps: 5,
        remainingTime: Duration.zero,
        state: ExitSequenceState.completed,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ExitProgressIndicator(progress: progress),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Exit Sequence'), findsOneWidget);
      expect(find.text('Step: 5/5'), findsOneWidget);
      expect(find.text('0s'), findsOneWidget);

      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressBar.value, 1.0);
    });
  });

  group('ExitProgressOverlay', () {
    testWidgets('wraps child with progress indicator',
        (WidgetTester tester) async {
      const progress = ExitProgress(
        currentStep: 2,
        totalSteps: 5,
        remainingTime: Duration(seconds: 3),
        state: ExitSequenceState.inProgress,
      );

      const childWidget = ColoredBox(
        color: Colors.blue,
        child: Text('Game Content'),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExitProgressOverlay(
              progress: progress,
              child: childWidget,
            ),
          ),
        ),
      );

      // Should have both the child and the indicator
      expect(find.text('Game Content'), findsOneWidget);
      expect(find.text('Exit Sequence'), findsOneWidget);
      expect(find.byType(ExitProgressIndicator), findsOneWidget);
    });

    testWidgets('child is rendered below indicator',
        (WidgetTester tester) async {
      const progress = ExitProgress(
        currentStep: 1,
        totalSteps: 5,
        remainingTime: Duration(seconds: 4),
        state: ExitSequenceState.inProgress,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExitProgressOverlay(
              progress: progress,
              child: Text('Child'),
            ),
          ),
        ),
      );

      // Verify ExitProgressOverlay contains both child and indicator
      expect(find.byType(ExitProgressOverlay), findsOneWidget);
      expect(find.text('Child'), findsOneWidget);
      expect(find.byType(ExitProgressIndicator), findsOneWidget);
    });
  });
}
