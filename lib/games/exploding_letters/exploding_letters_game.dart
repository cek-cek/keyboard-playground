/// Exploding Letters game - letters explode with particle effects on
/// key press.
///
/// This game creates colorful, animated letters that appear at random
/// positions when keys are pressed. Each letter explodes into particles
/// with physics-based animation, providing immediate visual feedback for
/// keyboard input.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:keyboard_playground/games/base_game.dart';
import 'package:keyboard_playground/platform/input_events.dart' as events;

/// Main game class for the Exploding Letters game.
///
/// Creates animated letters that explode into particles when keys are pressed.
/// Maintains 60 FPS performance with multiple simultaneous explosions.
class ExplodingLettersGame extends BaseGame {
  /// Creates a new exploding letters game.
  ExplodingLettersGame() {
    // Start the animation ticker
    _ticker = Ticker(_updateAnimations)..start();
  }

  final List<LetterEntity> _activeLetters = [];
  final Random _random = Random();
  final ValueNotifier<int> _updateNotifier = ValueNotifier<int>(0);

  late final Ticker _ticker;

  @override
  String get id => 'exploding_letters';

  @override
  String get name => 'Exploding Letters';

  @override
  String get description => 'Letters explode with each key press!';

  @override
  Widget buildUI() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A2E), // Dark blue-purple
            Color(0xFF16213E), // Darker blue
          ],
        ),
      ),
      child: ValueListenableBuilder<int>(
        valueListenable: _updateNotifier,
        builder: (context, _, __) {
          return CustomPaint(
            painter: ExplodingLettersPainter(
              letters: _activeLetters,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  @override
  void onKeyEvent(events.KeyEvent event) {
    // Only respond to key down events
    if (!event.isDown) return;

    // Filter out modifier keys
    if (_isModifierKey(event.key)) return;

    // Get the character to display
    final character = _getDisplayCharacter(event.key);

    // Create new letter at random position
    final letter = LetterEntity(
      character: character,
      position: _randomPosition(),
      color: _randomColor(),
      createdAt: DateTime.now(),
    );

    _activeLetters.add(letter);

    // Remove after animation completes (3 seconds)
    Future<void>.delayed(const Duration(seconds: 3), () {
      _activeLetters.remove(letter);
    });
  }

  /// Checks if a key is a modifier key.
  bool _isModifierKey(String key) {
    const modifiers = {
      'Shift',
      'Control',
      'Alt',
      'Meta',
      'Command',
      'Option',
      'Win',
      'Super',
      'Hyper',
    };
    return modifiers.contains(key);
  }

  /// Gets the display character for a key.
  String _getDisplayCharacter(String key) {
    // For single characters, return as-is
    if (key.length == 1) {
      return key.toUpperCase();
    }

    // For special keys, return a symbol or shortened name
    const specialKeys = {
      'Space': '␣',
      'Enter': '↵',
      'Return': '↵',
      'Tab': '⇥',
      'Backspace': '⌫',
      'Delete': '⌦',
      'Escape': 'ESC',
      'ArrowUp': '↑',
      'ArrowDown': '↓',
      'ArrowLeft': '←',
      'ArrowRight': '→',
    };

    return specialKeys[key] ?? key.substring(0, min(3, key.length));
  }

  /// Generates a random position for a letter.
  Offset _randomPosition() {
    // We'll use a reasonable screen size assumption
    // The actual screen size will be provided by the painter
    const width = 1920.0;
    const height = 1080.0;
    const margin = 100.0;

    return Offset(
      margin + _random.nextDouble() * (width - 2 * margin),
      margin + _random.nextDouble() * (height - 2 * margin),
    );
  }

  /// Generates a random vibrant color.
  Color _randomColor() {
    final colors = [
      const Color(0xFFFF6B6B), // Red
      const Color(0xFF4ECDC4), // Teal
      const Color(0xFFFFE66D), // Yellow
      const Color(0xFF95E1D3), // Mint
      const Color(0xFFF38181), // Pink
      const Color(0xFFAA96DA), // Purple
      const Color(0xFFFCBAD3), // Light pink
      const Color(0xFFA8E6CF), // Light green
      const Color(0xFFFFD3B6), // Peach
      const Color(0xFFFFAAA5), // Coral
    ];

    return colors[_random.nextInt(colors.length)];
  }

  /// Updates all active animations.
  void _updateAnimations(Duration elapsed) {
    if (_activeLetters.isEmpty) return;

    // Notify listeners to repaint
    _updateNotifier.value++;

    // Clean up old letters
    _activeLetters.removeWhere((letter) {
      final age = DateTime.now().difference(letter.createdAt).inMilliseconds;
      return age > 3000; // 3 seconds
    });
  }

  bool _disposed = false;

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    _ticker.dispose();
    _updateNotifier.dispose();
    super.dispose();
  }

  /// Gets the count of active letters (for testing).
  @visibleForTesting
  int get activeLettersCount => _activeLetters.length;
}

/// Represents a single letter entity with its explosion animation.
class LetterEntity {
  /// Creates a new letter entity.
  LetterEntity({
    required this.character,
    required this.position,
    required this.color,
    required this.createdAt,
  }) {
    // Generate particles for explosion
    final random = Random();
    for (var i = 0; i < 25; i++) {
      // Random angle and speed
      final angle = random.nextDouble() * 2 * pi;
      final speed = 100 + random.nextDouble() * 200; // pixels per second

      particles.add(
        Particle(
          position: position,
          velocity: Offset(
            cos(angle) * speed,
            sin(angle) * speed,
          ),
          color: color,
          size: 3 + random.nextDouble() * 4,
          createdAt: createdAt,
        ),
      );
    }
  }

  /// The character to display.
  final String character;

  /// Initial position of the letter.
  final Offset position;

  /// Color of the letter and its particles.
  final Color color;

  /// When this letter was created.
  final DateTime createdAt;

  /// Particles for the explosion effect.
  final List<Particle> particles = [];

  /// Gets the progress of the animation (0.0 to 1.0).
  double getProgress() {
    final age = DateTime.now().difference(createdAt).inMilliseconds;
    return (age / 3000.0).clamp(0.0, 1.0);
  }
}

/// Represents a single particle in an explosion.
class Particle {
  /// Creates a new particle.
  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.createdAt,
  });

  /// Initial position of the particle.
  final Offset position;

  /// Velocity vector (pixels per second).
  final Offset velocity;

  /// Color of the particle.
  final Color color;

  /// Size of the particle.
  final double size;

  /// When this particle was created.
  final DateTime createdAt;

  /// Gravity constant (pixels per second squared).
  static const double gravity = 300;

  /// Gets the current position of the particle based on elapsed time.
  Offset getCurrentPosition() {
    final elapsed = DateTime.now().difference(createdAt).inMilliseconds / 1000;

    // Apply physics: position = initial + velocity * time +
    // 0.5 * gravity * time^2
    return Offset(
      position.dx + velocity.dx * elapsed,
      position.dy + velocity.dy * elapsed + 0.5 * gravity * elapsed * elapsed,
    );
  }

  /// Gets the opacity of the particle based on age (fades out).
  double getOpacity() {
    final age = DateTime.now().difference(createdAt).inMilliseconds;
    final progress = (age / 3000.0).clamp(0.0, 1.0);

    // Fade out over time
    return (1.0 - progress).clamp(0.0, 1.0);
  }
}

/// Custom painter for rendering exploding letters and particles.
class ExplodingLettersPainter extends CustomPainter {
  /// Creates a new painter.
  const ExplodingLettersPainter({
    required this.letters,
  });

  /// Letters to render.
  final List<LetterEntity> letters;

  @override
  void paint(Canvas canvas, Size size) {
    for (final letter in letters) {
      final progress = letter.getProgress();

      // Draw the letter (visible for first 20% of animation)
      if (progress < 0.2) {
        _drawLetter(canvas, letter, progress);
      }

      // Draw particles (visible throughout animation)
      _drawParticles(canvas, letter);
    }
  }

  /// Draws a letter.
  void _drawLetter(Canvas canvas, LetterEntity letter, double progress) {
    // Calculate letter opacity (fades out quickly)
    final opacity = (1.0 - progress * 5).clamp(0.0, 1.0);

    // Calculate letter scale (grows slightly before disappearing)
    final scale = 1 + progress * 2;

    final textPainter = TextPainter(
      text: TextSpan(
        text: letter.character,
        style: TextStyle(
          fontSize: 72 * scale,
          fontWeight: FontWeight.bold,
          color: letter.color.withOpacity(opacity),
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Draw letter centered at position
    textPainter.paint(
      canvas,
      letter.position -
          Offset(
            textPainter.width / 2,
            textPainter.height / 2,
          ),
    );
  }

  /// Draws all particles for a letter.
  void _drawParticles(Canvas canvas, LetterEntity letter) {
    for (final particle in letter.particles) {
      final position = particle.getCurrentPosition();
      final opacity = particle.getOpacity();

      if (opacity <= 0) continue;

      final paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(position, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(ExplodingLettersPainter oldDelegate) {
    // Always repaint to show animation updates
    return true;
  }
}

/// Simple ticker implementation for animation updates.
class Ticker {
  /// Creates a new ticker.
  Ticker(this.onTick);

  /// Callback for each tick.
  final void Function(Duration elapsed) onTick;

  bool _active = false;
  late DateTime _startTime;

  /// Starts the ticker.
  void start() {
    if (_active) return;

    _active = true;
    _startTime = DateTime.now();
    _tick();
  }

  /// Stops the ticker.
  void stop() {
    _active = false;
  }

  /// Disposes of the ticker.
  void dispose() {
    stop();
  }

  void _tick() {
    if (!_active) return;

    final elapsed = DateTime.now().difference(_startTime);
    onTick(elapsed);

    // Schedule next tick
    Future<void>.delayed(const Duration(milliseconds: 16), _tick);
  }
}
