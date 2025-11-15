import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyboard_playground/core/exit_handler.dart';
import 'package:keyboard_playground/core/game_manager.dart';
import 'package:keyboard_playground/platform/input_capture.dart';
import 'package:keyboard_playground/ui/app_shell.dart';

void main() {
  group('AppShell', () {
    late InputCapture inputCapture;
    late ExitHandler exitHandler;
    late GameManager gameManager;

    setUp(() {
      inputCapture = InputCapture();
      exitHandler = ExitHandler(inputCapture: inputCapture);
      gameManager = GameManager();
    });

    tearDown(() async {
      await exitHandler.dispose();
      await gameManager.dispose();
    });

    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            gameManager: gameManager,
            exitHandler: exitHandler,
          ),
        ),
      );

      expect(find.byType(AppShell), findsOneWidget);
    });

    testWidgets('displays no game screen when no game selected',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            gameManager: gameManager,
            exitHandler: exitHandler,
          ),
        ),
      );

      // Wait for widget to build
      await tester.pumpAndSettle();

      // Should show "No game selected" message
      expect(find.text('No game selected'), findsOneWidget);
      expect(find.text('Keyboard Playground'), findsOneWidget);
    });

    testWidgets('displays choose a game button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            gameManager: gameManager,
            exitHandler: exitHandler,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have a button to choose a game
      expect(find.text('Choose a Game'), findsOneWidget);
    });

    testWidgets('exit progress indicator is hidden when idle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            gameManager: gameManager,
            exitHandler: exitHandler,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Exit progress indicator should not be visible when idle
      // It uses SizedBox.shrink() when state is idle
      expect(find.text('Exit Sequence'), findsNothing);
    });
  });
}
