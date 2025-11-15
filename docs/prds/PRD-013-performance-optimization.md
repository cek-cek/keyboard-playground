# PRD-013: Performance Optimization

**Status**: ⚪ Not Started
**Dependencies**: PRD-008 (Integration & Base App), PRD-009, PRD-010, PRD-011 (for comprehensive testing)
**Estimated Effort**: 20 hours (8h performance + 12h test coverage)
**Priority**: P2
**Branch**: `feature/prd-013-performance-optimization`

## Overview

Profile and optimize application performance to ensure smooth 60 FPS during all games, minimize memory usage, reduce startup time, and achieve comprehensive test coverage (target: ~95-100%).

## Goals

**Performance:**
- ✅ Consistent 60 FPS in all games
- ✅ Memory usage <100MB baseline
- ✅ Startup time <3 seconds
- ✅ No memory leaks
- ✅ CPU usage <10% when idle

**Test Coverage:**
- ✅ Overall test coverage ≥95%
- ✅ Critical path coverage 100%
- ✅ All public APIs covered
- ✅ Edge cases and error handling tested
- ✅ Platform-specific code tested (where possible)

## Performance Targets

### Performance Metrics

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| FPS (games active) | 60 | TBD | ⚪ |
| FPS (idle) | 60 | TBD | ⚪ |
| Memory baseline | <100MB | TBD | ⚪ |
| Memory with game | <200MB | TBD | ⚪ |
| Startup time | <3s | TBD | ⚪ |
| CPU idle | <10% | TBD | ⚪ |

### Test Coverage Metrics

| Component | Target | Current | Status |
|-----------|--------|---------|--------|
| Overall Coverage | ≥95% | ~10% | ⚪ |
| Core (GameManager, ExitHandler) | 100% | TBD | ⚪ |
| Platform (InputCapture, WindowControl) | ≥90% | TBD | ⚪ |
| UI Components | ≥95% | TBD | ⚪ |
| Games | ≥95% | TBD | ⚪ |
| Widgets | ≥95% | TBD | ⚪ |
| Critical Path | 100% | TBD | ⚪ |

## Test Coverage Expansion

### Areas Requiring Additional Tests

**Core Components:**
- GameManager: All methods, edge cases, error handling
- ExitHandler: All exit sequences (keyboard, mouse), timeout handling
- Event routing: Input → GameManager → Game flow

**Platform Code:**
- InputCapture: Permission handling, event parsing, error cases
- WindowControl: Fullscreen enter/exit, multi-monitor handling
- Platform-specific native code (mock where necessary)

**UI Components:**
- AppShell: Initialization, game switching, exit handling
- GameSelectionMenu: Keyboard navigation, mouse interaction, selection
- ExitProgressIndicator: Progress updates, visual states

**Games:**
- PlaceholderGame: Event display, state management
- ExplodingLettersGame: Letter creation, explosions, particle lifecycle
- KeyboardVisualizerGame: Key states, mouse buttons, responsive layout
- MouseVisualizerGame: Trail, ripples, time-based animations, centering

**Widgets:**
- BigButton: Interaction, styling
- AnimatedBackground: Animation lifecycle
- GameCard: Selection, hover states
- All custom widgets

**Integration Tests:**
- Full app initialization flow
- Game switching
- Exit sequence (both methods)
- Error handling and recovery

**Edge Cases:**
- Rapid input events
- Multiple simultaneous events
- Permission denial
- Platform API failures
- Memory constraints

### Test Coverage Strategy

1. **Unit Tests:** Pure Dart logic, mocked dependencies
2. **Widget Tests:** UI components with pumped widgets
3. **Integration Tests:** Full app flows
4. **Golden Tests:** Visual regression for key UI states
5. **Performance Tests:** FPS, memory, startup time

## Optimization Areas

### 1. Animation Performance

- Use `RepaintBoundary` for complex animations
- Reduce overdraw
- Optimize particle count
- Use hardware acceleration
- Profile with Flutter DevTools

### 2. Memory Management

- Proper disposal of all resources
- Image caching strategy
- Limit active particle count
- Clean up old trail points
- Check for memory leaks

### 3. Input Event Processing

- Throttle mouse move events if needed
- Efficient event dispatching
- Avoid unnecessary rebuilds

### 4. Platform Channel Optimization

- Batch events if possible
- Minimize serialization overhead
- Profile native code

### 5. Startup Optimization

- Lazy load non-critical components
- Optimize asset loading
- Profile initialization sequence

## Tools & Techniques

### Profiling Tools

```bash
# Flutter DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Performance overlay
flutter run --profile

# Memory profiling
flutter run --profile --trace-systrace
```

### Benchmarking

```dart
// lib/utils/performance_monitor.dart
class PerformanceMonitor {
  static Future<void> benchmarkGame(BaseGame game) async {
    // Measure FPS
    // Measure memory
    // Report results
  }
}

// test/performance/game_performance_test.dart
void main() {
  test('ExplodingLetters maintains 60 FPS', () async {
    // Run game with simulated input
    // Measure performance
    // Assert FPS >= 60
  });
}
```

## Acceptance Criteria

### Performance Targets Met

- [ ] All games maintain 60 FPS with typical input
- [ ] Memory usage stays within limits
- [ ] No memory leaks detected
- [ ] Startup time <3 seconds
- [ ] CPU usage acceptable

### Test Coverage Targets Met

- [ ] Overall coverage ≥95%
- [ ] Core components (GameManager, ExitHandler) at 100%
- [ ] All games at ≥95%
- [ ] All UI components at ≥95%
- [ ] All widgets at ≥95%
- [ ] Platform code at ≥90% (where testable)
- [ ] Critical path at 100%
- [ ] Edge cases covered
- [ ] Integration tests for all major flows
- [ ] Golden tests for key UI states

### Documentation

- [ ] Performance benchmarks documented
- [ ] Optimization techniques documented
- [ ] Known limitations documented
- [ ] Test coverage report generated
- [ ] Missing coverage areas identified and justified

### Tests

- [ ] Performance tests added
- [ ] Benchmarks run in CI (optional)
- [ ] Regression tests for performance
- [ ] Comprehensive unit test suite
- [ ] Widget tests for all components
- [ ] Integration tests for critical flows
- [ ] Golden tests for visual regression

## Implementation Steps

### Performance Optimization (8 hours)

1. Setup profiling tools (1h)
2. Baseline measurements (1h)
3. Profile each game (2h)
4. Optimize hot paths (2h)
5. Memory leak detection & fixes (1h)
6. Re-measure & validate (1h)

### Test Coverage Expansion (12 hours)

1. Audit current test coverage (1h)
2. Write unit tests for core components (3h)
   - GameManager, ExitHandler
   - Event routing
3. Write widget tests for UI components (3h)
   - AppShell, GameSelectionMenu
   - ExitProgressIndicator, GameCard
4. Write game-specific tests (3h)
   - All games (Placeholder, ExplodingLetters, KeyboardVisualizer, MouseVisualizer)
5. Write integration tests (1h)
   - Full app flow, game switching, exit sequences
6. Write golden tests (0.5h)
   - Key UI states
7. Generate coverage report and fill gaps (0.5h)

## Common Optimizations

### Animation

- Use `const` constructors where possible
- Cache computed values
- Use `RepaintBoundary` for isolated animations
- Reduce particle count if needed

### Memory

- Dispose controllers and streams
- Limit collection sizes (trails, particles)
- Use object pools for particles

### Rendering

- Minimize `setState` calls
- Use `ValueNotifier` for localized updates
- Avoid rebuilding entire tree

---

**Best done after PRD-009-011 so games exist to optimize!**
