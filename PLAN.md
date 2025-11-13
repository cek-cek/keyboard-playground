# Keyboard Playground - Master Plan

## Executive Summary

A multiplatform desktop application that creates a safe, entertaining sandbox environment for young children to explore keyboard and mouse input without accidentally triggering system actions. The application captures all input, provides visual feedback through interactive games, and requires specific exit combinations to close.

## Technology Decision

### Selected: **Flutter for Desktop**

#### Rationale
After thorough research comparing Flutter, Tauri, and Electron (January 2025):

**Why Flutter:**
1. ✅ **Excellent animation support** - Perfect for kid-friendly visual feedback and games
2. ✅ **Single codebase** - Dart for all platforms (macOS, Linux, Windows)
3. ✅ **Stable desktop support** - Flutter 3.x+ has production-ready desktop
4. ✅ **Rich widget ecosystem** - Ideal for building multiple games with consistent UI
5. ✅ **Strong testing story** - Built-in widget testing, unit testing, integration testing
6. ✅ **CI/CD friendly** - Easy GitHub Actions integration
7. ✅ **Fast development** - Hot reload, declarative UI, single language

**Trade-offs Considered:**
- **Tauri**: Lighter but has known fullscreen keyboard issues on Linux (as of Feb 2025), requires more JavaScript/Rust split
- **Electron**: Mature keyboard handling but heavy (~100MB+ bundles, high memory), overkill for this use case
- **Flutter**: Requires platform channels for deep keyboard capture, but this is true for all frameworks

#### Architecture: Flutter + Platform Channels

```
┌─────────────────────────────────────────────┐
│           Flutter Application               │
│  (Dart - UI, Games, Business Logic)         │
├─────────────────────────────────────────────┤
│         Platform Channels (Bridge)          │
├──────────┬──────────────┬───────────────────┤
│  macOS   │    Linux     │     Windows       │
│ (Swift)  │   (C++)      │     (C++)         │
│          │              │                   │
│ CGEvent  │ X11/Wayland  │ SetWindowsHookEx  │
│  APIs    │   libinput   │    Low-level      │
└──────────┴──────────────┴───────────────────┘
```

**Platform-Specific Code Required For:**
- Global keyboard/mouse capture (including system shortcuts)
- Accessibility permissions handling
- Fullscreen enforcement
- Exit combination detection at OS level

## Project Phases

### Phase 1: Foundation & Infrastructure (Weeks 1-2)
Build the extensible base with all core functionality, tooling, and documentation.

**Goals:**
- ✅ Fully working keyboard/mouse capture on all platforms
- ✅ Compilable without errors (linting, formatting)
- ✅ Trunk-based development compatible
- ✅ GitHub Actions CI/CD for all platforms (default: macOS)
- ✅ ~100% test coverage for business logic
- ✅ Complete documentation (user + developer + AI agents)

### Phase 2: First Game - Exploding Letters (Week 3)
Animated visual feedback when keys are pressed - letters appear and explode with particle effects.

### Phase 3: Second Game - Input Visualizer (Week 4)
Real-time visualization of keyboard and mouse state, showing which keys/buttons are currently pressed.

### Phase 4: Additional Games (Weeks 5+)
Expandable game library based on initial learnings.

## Execution Strategy

### Parallel Development Structure

The PRDs are designed for **maximum parallelization**:

```
Sequential Foundation:
  PRD-001 (Research) → PRD-002 (Setup) → PRD-003 (Build/CI)
                                              ↓
  ┌────────────────────────────────────────────────────────┐
  │              Parallel Group 1                          │
  ├──────────────┬──────────────┬─────────────┬───────────┤
  │  PRD-004     │  PRD-005     │  PRD-006    │  PRD-007  │
  │  Input       │  Exit        │  UI         │  Testing  │
  │  Capture     │  Mechanism   │  Framework  │  Setup    │
  └──────────────┴──────────────┴─────────────┴───────────┘
                        ↓
            PRD-008 (Integration & Base App)
                        ↓
  ┌────────────────────────────────────────────────────────┐
  │              Parallel Group 2 (Games)                  │
  ├──────────────┬──────────────┬─────────────────────────┤
  │  PRD-009     │  PRD-010     │  PRD-011                │
  │  Game 1      │  Game 2      │  Game 2                 │
  │  Exploding   │  Keyboard    │  Mouse                  │
  │  Letters     │  Visualizer  │  Visualizer             │
  └──────────────┴──────────────┴─────────────────────────┘
                        ↓
  ┌────────────────────────────────────────────────────────┐
  │         Parallel Group 3 (Polish)                      │
  ├──────────────┬──────────────┬─────────────────────────┤
  │  PRD-012     │  PRD-013     │  PRD-014                │
  │  Docs        │  Performance │  Accessibility          │
  └──────────────┴──────────────┴─────────────────────────┘
```

### Autonomous Agent Execution

Each PRD is designed to be **completely autonomous**:

1. ✅ **Self-contained** - All requirements, acceptance criteria, and technical specs included
2. ✅ **Clear dependencies** - Explicitly states what must be completed first
3. ✅ **Actionable** - Agent can start work immediately without clarification
4. ✅ **Testable** - Clear definition of done with verifiable tests
5. ✅ **No ambiguity** - All architectural decisions pre-made with rationale

### Branch Strategy: Trunk-Based Development

- **Main branch**: `main` - always deployable
- **Feature branches**: `feature/prd-XXX-short-name`
- **PR requirements**: All tests pass, lint clean, reviewed
- **Merge strategy**: Squash and merge to keep history clean

## File Structure

```
keyboard-playground/
├── PLAN.md                          # This file
├── AGENTS.md                        # AI agent coordination guide
├── DEPENDENCIES.md                  # PRD dependency graph
├── docs/
│   ├── prds/
│   │   ├── PRD-001-technology-research.md
│   │   ├── PRD-002-project-setup.md
│   │   ├── PRD-003-build-ci-cd.md
│   │   ├── PRD-004-input-capture.md
│   │   ├── PRD-005-exit-mechanism.md
│   │   ├── PRD-006-ui-framework.md
│   │   ├── PRD-007-testing-infrastructure.md
│   │   ├── PRD-008-integration-base-app.md
│   │   ├── PRD-009-game-exploding-letters.md
│   │   ├── PRD-010-game-keyboard-visualizer.md
│   │   ├── PRD-011-game-mouse-visualizer.md
│   │   ├── PRD-012-documentation-system.md
│   │   ├── PRD-013-performance-optimization.md
│   │   └── PRD-014-accessibility-features.md
│   ├── architecture/
│   │   ├── platform-channels.md
│   │   ├── game-plugin-system.md
│   │   └── testing-strategy.md
│   └── user/
│       ├── installation.md
│       └── troubleshooting.md
├── lib/                             # Flutter Dart code
├── macos/                           # macOS platform code
├── linux/                           # Linux platform code
├── windows/                         # Windows platform code
├── test/                            # All tests
└── .github/
    └── workflows/                   # CI/CD pipelines
```

## Success Metrics

### Phase 1 (Foundation)
- [ ] 100% of keyboard/mouse events captured on all 3 platforms
- [ ] Exit mechanism requires correct 5-input sequence
- [ ] Build succeeds on macOS, Linux, Windows in CI
- [ ] Test coverage >95% for Dart code
- [ ] All lints pass with zero warnings
- [ ] Documentation complete for all modules

### Phase 2 (First Game)
- [ ] Letters appear at random positions on keypress
- [ ] Explosion animation completes in <1s
- [ ] 60 FPS maintained with 50+ concurrent animations
- [ ] Test coverage >90% for game logic

### Phase 3 (Second Game)
- [ ] Keyboard layout matches physical keyboard
- [ ] Key press/release latency <16ms
- [ ] Mouse position updates at 60+ FPS
- [ ] Visual feedback for all 104+ keys

### Phase 4 (Additional Games)
- TBD based on Phase 2-3 learnings

## Risk Mitigation

### Risk 1: Platform-specific keyboard capture complexity
- **Mitigation**: PRD-004 is sequential dependency - all other work blocks on this
- **Fallback**: If full capture impossible, implement best-effort + documented limitations

### Risk 2: Performance with multiple animations
- **Mitigation**: PRD-013 dedicated to optimization, benchmark requirements in PRD-009
- **Fallback**: Limit concurrent animations with queuing system

### Risk 3: Accessibility permissions user friction
- **Mitigation**: Clear onboarding flow with screenshots, troubleshooting guide
- **Fallback**: Graceful degradation - app works with limited capture

### Risk 4: Platform differences in behavior
- **Mitigation**: Platform-specific tests, test matrix in CI
- **Fallback**: Document platform-specific limitations

## Next Steps

1. **Immediate**: Review this plan for completeness
2. **Create PRDs**: Generate all 14 PRD files with full specifications
3. **Create AGENTS.md**: Write coordination guide for autonomous agents
4. **Create DEPENDENCIES.md**: Explicit dependency graph
5. **First execution**: Agent picks up PRD-001 and begins work

## Notes

- **Kid-friendly focus**: All UI decisions prioritize high contrast, large targets, immediate feedback
- **Safety first**: No network access, no file system access beyond app directory
- **Extensibility**: Plugin system allows adding games without modifying core
- **Professional quality**: This is a portfolio piece - production-ready code quality
