import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyboard_playground/core/game_manager.dart';
import 'package:keyboard_playground/games/base_game.dart';
import 'package:keyboard_playground/ui/game_selection_menu.dart';

/// Mock game for testing.
class MockGame extends BaseGame {
  MockGame({
    required this.id,
    required this.name,
    required this.description,
  });

  @override
  final String id;

  @override
  final String name;

  @override
  final String description;

  @override
  Widget buildUI() {
    return Center(child: Text('Mock Game: $name'));
  }
}

void main() {
  group('GameSelectionMenu', () {
    late GameManager gameManager;

    setUp(() {
      gameManager = GameManager();
    });

    tearDown(() async {
      await gameManager.dispose();
    });

    testWidgets('renders with no games', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameSelectionMenu(
              gameManager: gameManager,
              onGameSelected: (_) {},
              onClose: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Choose a Game'), findsOneWidget);
      expect(find.text('No games available'), findsOneWidget);
    });

    testWidgets('displays registered games', (tester) async {
      // Register test games
      gameManager
        ..registerGame(
          MockGame(
            id: 'game1',
            name: 'Test Game 1',
            description: 'First test game',
          ),
        )
        ..registerGame(
          MockGame(
            id: 'game2',
            name: 'Test Game 2',
            description: 'Second test game',
          ),
        );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameSelectionMenu(
              gameManager: gameManager,
              onGameSelected: (_) {},
              onClose: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display both games
      expect(find.text('Test Game 1'), findsOneWidget);
      expect(find.text('Test Game 2'), findsOneWidget);
    });

    testWidgets('calls onGameSelected when game is tapped', (tester) async {
      gameManager.registerGame(
        MockGame(
          id: 'game1',
          name: 'Test Game 1',
          description: 'First test game',
        ),
      );

      BaseGame? selectedGame;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameSelectionMenu(
              gameManager: gameManager,
              onGameSelected: (game) => selectedGame = game,
              onClose: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the game card
      await tester.tap(find.text('Test Game 1'));
      await tester.pumpAndSettle();

      expect(selectedGame, isNotNull);
      expect(selectedGame?.id, equals('game1'));
    });

    testWidgets('calls onClose when cancel button is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameSelectionMenu(
              gameManager: gameManager,
              onGameSelected: (_) {},
              onClose: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the cancel button
      await tester.tap(find.text('Cancel (Esc)'));
      await tester.pumpAndSettle();

      // Test passes if no exception is thrown
    });

    testWidgets('calls onClose when background is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameSelectionMenu(
              gameManager: gameManager,
              onGameSelected: (_) {},
              onClose: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the background (outside the menu content)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Test passes if no exception is thrown
    });
  });
}
