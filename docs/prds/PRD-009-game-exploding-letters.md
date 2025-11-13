# PRD-009: Game 1 - Exploding Letters

**Status**: ⚪ Not Started  
**Dependencies**: PRD-008 (Integration & Base App)  
**Estimated Effort**: 12 hours  
**Priority**: P1  
**Branch**: `feature/prd-009-game-exploding-letters`

## Overview

Implement the first game: animated letters/shapes that appear and explode when the corresponding key is pressed. This provides immediate, satisfying visual feedback for keyboard input.

## Goals

- ✅ Letters appear at random positions when keys pressed
- ✅ Explosion animation with particle effects
- ✅ Colorful, kid-friendly visuals
- ✅ Smooth 60 FPS performance
- ✅ Sound effects (optional)

## Technical Approach

### Game Architecture

```dart
// lib/games/exploding_letters/exploding_letters_game.dart

class ExplodingLettersGame extends BaseGame {
  final List<LetterEntity> _activeLetters = [];
  final Random _random = Random();
  
  @override
  String get id => 'exploding_letters';
  
  @override
  String get name => 'Exploding Letters';
  
  @override
  String get description => 'Letters explode with each key press!';
  
  @override
  void onKeyEvent(KeyEvent event) {
    if (!event.isDown) return;
    
    // Create new letter at random position
    final letter = LetterEntity(
      character: event.key,
      position: _randomPosition(),
      color: _randomColor(),
    );
    
    _activeLetters.add(letter);
    letter.startExplosion();
    
    // Remove after animation
    Future.delayed(Duration(seconds: 2), () {
      _activeLetters.remove(letter);
    });
  }
}

class LetterEntity {
  final String character;
  final Offset position;
  final Color color;
  final List<Particle> particles = [];
  
  void startExplosion() {
    // Create 20-30 particles
    for (int i = 0; i < 25; i++) {
      particles.add(Particle(
        position: position,
        velocity: _randomVelocity(),
        color: color,
      ));
    }
  }
}
```

### Animation System

- Use Flutter's `CustomPainter` for rendering
- `AnimationController` for explosion timing
- Particle physics with velocity/gravity
- Fade out over 1-2 seconds

### Performance Requirements

- Maintain 60 FPS with 50+ concurrent animations
- Efficient particle cleanup
- No memory leaks

## Acceptance Criteria

- [ ] Pressing any key creates letter at random position
- [ ] Letter explodes into 20-30 particles
- [ ] Smooth animation (60 FPS)
- [ ] Particles fade out naturally
- [ ] Multiple simultaneous explosions work
- [ ] No performance degradation over time
- [ ] Tests cover game logic
- [ ] Registered in GameManager

## Implementation Steps

1. Create basic game structure (2h)
2. Implement letter rendering (2h)
3. Implement particle system (3h)
4. Implement explosion animation (3h)
5. Performance optimization (1h)
6. Testing (1h)

## References

- BaseGame interface (PRD-002)
- GameManager (PRD-008)
- Flutter animations: https://docs.flutter.dev/ui/animations

---

**Can start after PRD-008 completes!**
