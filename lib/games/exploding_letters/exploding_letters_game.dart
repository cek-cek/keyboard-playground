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
import 'package:flutter/scheduler.dart';
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
    _scheduleNextFrame();
  }

  /// Animation duration in milliseconds (3 seconds).
  static const int animationDurationMs = 3000;

  /// Letter visibility threshold (first 20% of animation).
  static const double letterVisibilityThreshold = 0.2;

  /// Letter opacity fade rate multiplier.
  static const int letterFadeRate = 5;

  /// Letter scale growth rate multiplier.
  static const int letterScaleRate = 2;

  final List<LetterEntity> _activeLetters = [];
  final Random _random = Random();
  final ValueNotifier<int> _updateNotifier = ValueNotifier<int>(0);

  bool _isScheduled = false;
  Size _screenSize = const Size(1920, 1080); // Default, updated from layout

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Update screen size from actual layout constraints
          if (constraints.maxWidth.isFinite && constraints.maxHeight.isFinite) {
            _screenSize = Size(constraints.maxWidth, constraints.maxHeight);
          }

          return ValueListenableBuilder<int>(
            valueListenable: _updateNotifier,
            builder: (context, _, __) {
              return CustomPaint(
                painter: ExplodingLettersPainter(
                  letters: _activeLetters,
                ),
                size: Size.infinite,
              );
            },
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

    // Ensure screen size is up to date (if not, fallback to reasonable default)
    if (_screenSize.width < 1 || _screenSize.height < 1) {
      // Fallback to a typical desktop window size
      _screenSize = const Size(1280, 720);
    }

    // Create new letter at random position
    final letter = LetterEntity(
      character: character,
      position: _randomPosition(),
      color: _randomColor(),
      createdAt: DateTime.now(),
    );

    _activeLetters.add(letter);

    // Restart animation loop if needed
    _scheduleNextFrame();

    // Cleanup happens in _updateAnimations via removeWhere
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
    // Use actual screen size from layout
    final width = _screenSize.width;
    final height = _screenSize.height;
    const margin = 100.0;

    return Offset(
      margin + _random.nextDouble() * (width - 2 * margin).clamp(0, width),
      margin + _random.nextDouble() * (height - 2 * margin).clamp(0, height),
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

  /// Schedules the next animation frame.
  void _scheduleNextFrame() {
    if (_disposed || _isScheduled) return;
    _isScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((timeStamp) {
      _isScheduled = false;
      if (!_disposed && _activeLetters.isNotEmpty) {
        _updateAnimations();
        _scheduleNextFrame();
      }
    });
  }

  /// Updates all active animations.
  void _updateAnimations() {
    if (_activeLetters.isEmpty) return;

    // Clean up old letters (single cleanup mechanism)
    final now = DateTime.now();
    _activeLetters.removeWhere((letter) {
      final age = now.difference(letter.createdAt).inMilliseconds;
      return age > animationDurationMs;
    });

    // Notify listeners to repaint
    _updateNotifier.value++;
  }

  bool _disposed = false;

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    _updateNotifier.dispose();
    super.dispose();
  }

  /// Gets the count of active letters (for testing).
  @visibleForTesting
  int get activeLettersCount => _activeLetters.length;

  /// Manually triggers animation cleanup (for testing).
  @visibleForTesting
  void cleanupOldLetters() {
    _updateAnimations();
  }
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

  /// Cached TextPainter for rendering performance.
  TextPainter? _cachedTextPainter;

  /// Gets or creates the cached TextPainter for this letter.
  TextPainter getTextPainter(double scale, double opacity) {
    // Recreate if scale or opacity changed significantly
    final needsRecreate = _cachedTextPainter == null;

    if (needsRecreate) {
      _cachedTextPainter = TextPainter(
        text: TextSpan(
          text: character,
          style: TextStyle(
            fontSize: 72 * scale,
            fontWeight: FontWeight.bold,
            color: color.withValues(alpha: opacity),
            letterSpacing: 2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    } else {
      // Update existing painter's text style
      _cachedTextPainter!.text = TextSpan(
        text: character,
        style: TextStyle(
          fontSize: 72 * scale,
          fontWeight: FontWeight.bold,
          color: color.withValues(alpha: opacity),
          letterSpacing: 2,
        ),
      );
      _cachedTextPainter!.layout();
    }

    return _cachedTextPainter!;
  }

  /// Gets the progress of the animation (0.0 to 1.0).
  double getProgress() {
    final age = DateTime.now().difference(createdAt).inMilliseconds;
    return (age / ExplodingLettersGame.animationDurationMs).clamp(0.0, 1.0);
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
    final progress =
        (age / ExplodingLettersGame.animationDurationMs).clamp(0.0, 1.0);

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

      // Draw the letter (visible for first portion of animation)
      if (progress < ExplodingLettersGame.letterVisibilityThreshold) {
        _drawLetter(canvas, letter, progress);
      }

      // Draw particles (visible throughout animation)
      _drawParticles(canvas, letter);
    }
  }

  /// Draws a letter.
  void _drawLetter(Canvas canvas, LetterEntity letter, double progress) {
    // Calculate letter opacity (fades out quickly)
    final opacity =
        (1.0 - progress * ExplodingLettersGame.letterFadeRate).clamp(0.0, 1.0);

    // Calculate letter scale (grows slightly before disappearing)
    final scale = 1 + progress * ExplodingLettersGame.letterScaleRate;

    // Use cached TextPainter for better performance
    final textPainter = letter.getTextPainter(scale, opacity);

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
        ..color = particle.color.withValues(alpha: opacity)
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
