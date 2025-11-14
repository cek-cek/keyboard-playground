import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyboard_playground/widgets/animated_background.dart';

void main() {
  group('AnimatedBackground', () {
    testWidgets('renders with child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedBackground(
            colors: [Colors.blue, Colors.purple],
            child: Text('Test Child'),
          ),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('renders without child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedBackground(
            colors: [Colors.blue, Colors.purple],
          ),
        ),
      );

      expect(find.byType(AnimatedBackground), findsOneWidget);
    });

    testWidgets('accepts multiple colors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedBackground(
            colors: [
              Colors.red,
              Colors.orange,
              Colors.yellow,
              Colors.green,
            ],
            child: Text('Multi-color'),
          ),
        ),
      );

      expect(find.text('Multi-color'), findsOneWidget);
    });

    testWidgets('animates over time', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedBackground(
            colors: [Colors.blue, Colors.purple],
            duration: Duration(milliseconds: 500),
            child: Text('Animated'),
          ),
        ),
      );

      // Initial state
      await tester.pump();

      // Advance time
      await tester.pump(const Duration(milliseconds: 250));

      // Animation should be running
      expect(find.text('Animated'), findsOneWidget);
    });
  });

  group('PulsingBackground', () {
    testWidgets('renders with child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PulsingBackground(
            colors: [Colors.red, Colors.orange],
            child: Text('Pulsing'),
          ),
        ),
      );

      expect(find.text('Pulsing'), findsOneWidget);
    });

    testWidgets('animates over time', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PulsingBackground(
            colors: [Colors.red, Colors.orange],
            duration: Duration(milliseconds: 500),
            child: Text('Pulse'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Pulse'), findsOneWidget);
    });
  });

  group('StaticGradientBackground', () {
    testWidgets('renders with child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StaticGradientBackground(
            colors: [Colors.blue, Colors.green],
            child: Text('Static'),
          ),
        ),
      );

      expect(find.text('Static'), findsOneWidget);
    });

    testWidgets('renders without child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StaticGradientBackground(
            colors: [Colors.blue, Colors.green],
          ),
        ),
      );

      expect(find.byType(StaticGradientBackground), findsOneWidget);
    });
  });

  group('RadialGradientBackground', () {
    testWidgets('renders with child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RadialGradientBackground(
            colors: [Colors.yellow, Colors.orange, Colors.red],
            child: Text('Radial'),
          ),
        ),
      );

      expect(find.text('Radial'), findsOneWidget);
    });

    testWidgets('renders without child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RadialGradientBackground(
            colors: [Colors.yellow, Colors.orange, Colors.red],
          ),
        ),
      );

      expect(find.byType(RadialGradientBackground), findsOneWidget);
    });
  });
}
