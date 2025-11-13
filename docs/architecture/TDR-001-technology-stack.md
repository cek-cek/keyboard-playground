# TDR-001: Technology Stack Selection

**Date**: 2025-01-13
**Status**: Accepted
**Deciders**: Claude AI Agent (Session: 011CV5ttkGoV4zSoqAggbqRG)
**Review Date**: 2025-01-13

## Context

We are building Keyboard Playground, a cross-platform desktop application for children that:
- Captures all keyboard and mouse input, including system-level shortcuts
- Runs fullscreen on macOS, Linux, and Windows
- Provides animated, interactive games that respond to input
- Is extensible for adding new games
- Requires excellent testing and CI/CD support

The core technical challenge is **system-level input capture** while maintaining cross-platform compatibility and providing smooth animations. We need a technology stack that balances native platform access, development velocity, and maintainability.

## Decision

**We will use Flutter for desktop application development**, with platform-specific native code for input capture via platform channels.

### Technology Stack

- **Framework**: Flutter 3.35+ (latest stable as of November 2025)
- **Language**: Dart (Flutter/app logic) + Platform-specific native code (input capture)
- **Platform Code**:
  - macOS: Swift/Objective-C
  - Windows: C++
  - Linux: C++
- **Build System**: Flutter's built-in build system with platform-specific toolchains
- **Testing**: Flutter test framework + platform-specific unit tests
- **CI/CD**: GitHub Actions with matrix builds

## Rationale

### Flutter's Strengths for This Project

1. **Production-Ready Desktop Support (2025)**
   - Flutter desktop is stable and production-ready since Flutter 2.0 (2021)
   - Windows support declared production-ready in February 2022
   - Active development with improved GPU acceleration and multi-window support in 2025
   - Flutter 3.35+ is robust across all three major OS platforms

2. **Excellent Animation Performance**
   - Custom rendering engine (Skia/Impeller) provides smooth 60fps+ animations
   - Perfect for game-like, child-friendly interactive experiences
   - Direct GPU access for performant graphics

3. **Cross-Platform UI Consistency**
   - Single codebase for UI across macOS, Linux, Windows
   - Consistent behavior and appearance
   - Reduces maintenance burden compared to native UI on each platform

4. **Platform Channel Architecture**
   - Well-documented system for calling native platform code
   - MethodChannel APIs available for all desktop platforms
   - Bidirectional communication between Dart and native code
   - Type-safe alternatives available (Pigeon)

5. **Mature Testing & CI/CD**
   - Comprehensive testing framework built-in
   - GitHub Actions has excellent Flutter support
   - Can run tests on all platforms in CI (flutter test -d windows/macos/linux)
   - Multiple 2025 resources and tutorials available

6. **Developer Velocity**
   - Hot reload for rapid development
   - Rich widget library
   - Strong IDE support (VS Code, Android Studio)
   - Extensive package ecosystem (pub.dev)

### Pros

✅ **Single UI codebase** across all three platforms
✅ **Excellent animation performance** with custom rendering engine
✅ **Production-ready** with stable desktop support since 2021
✅ **Platform channels** provide bridge to native input capture APIs
✅ **Mature testing infrastructure** with CI/CD support
✅ **Hot reload** accelerates development
✅ **Comprehensive documentation** and active community
✅ **Smaller memory footprint** compared to Electron
✅ **Fast startup times** (sub-second)
✅ **Built-in widget system** suitable for games

### Cons

⚠️ **Requires platform-specific code** for keyboard/mouse capture (not a Flutter limitation, fundamental requirement)
⚠️ **Three native codebases** to maintain for input capture (Swift/ObjC, C++, C++)
⚠️ **Learning curve** for Dart (though similar to TypeScript/Java)
⚠️ **App size** larger than Tauri (but much smaller than Electron)
⚠️ **Requires OpenGL/Vulkan/Metal** support (not an issue for modern desktops)
⚠️ **Platform permissions** must be requested and managed per OS

### Alternatives Considered

#### 1. Electron

**Why not chosen:**
- **Heavy memory usage**: Typical idle memory 200-500 MB vs Flutter 50-100 MB
- **Large bundle size**: Often >100 MB vs Flutter 20-50 MB
- **Slow startup times**: 1-2 seconds vs Flutter <0.5 seconds
- **Performance concerns**: Less suitable for animation-heavy games
- **Benefits**: Mature keyboard handling, large ecosystem, web tech familiarity

**Verdict**: Performance and resource usage concerns outweigh ecosystem benefits for this game-focused application.

#### 2. Tauri

**Why not chosen:**
- **Known fullscreen issues on Linux**: Critical blocker for our fullscreen requirement
- **Smaller ecosystem**: Fewer resources and examples (2025: 35% YoY growth but still smaller)
- **Newer technology**: Version 2.0 released late 2024, less battle-tested
- **Web-based rendering**: May have animation performance limitations
- **Benefits**: Smallest bundle size (<10 MB), excellent security model, Rust backend

**Verdict**: Linux fullscreen issues and animation performance concerns are blockers. Tauri is excellent for lightweight apps but not optimal for fullscreen games.

#### 3. Qt

**Why not chosen:**
- **C++ complexity**: Steeper learning curve, slower development
- **Licensing concerns**: Commercial licensing for proprietary apps
- **Verbose code**: More boilerplate than Flutter
- **Benefits**: Excellent native input capture, mature desktop framework, powerful

**Verdict**: Development velocity and licensing concerns outweigh native advantages. Flutter + platform channels achieve similar capabilities.

#### 4. Native Apps (Swift, C#, C++)

**Why not chosen:**
- **Three separate codebases**: Would need to maintain Swift (macOS), C# (Windows), C++ (Linux)
- **No code sharing**: Business logic would need reimplementation per platform
- **Slower development**: 3x the work for feature parity
- **Benefits**: Best native performance, no abstraction layers

**Verdict**: Maintenance burden and development time too high. Flutter provides 95% of native performance with 10% of the code.

## Consequences

### Technical Implications

1. **Platform-Specific Development Required**
   - Must implement keyboard/mouse capture in Swift/ObjC (macOS), C++ (Windows), C++ (Linux)
   - Each platform requires understanding of native APIs: CGEvent (macOS), SetWindowsHookEx (Windows), X11/libinput (Linux)
   - Platform code will be ~15-20% of total codebase

2. **Permission Management**
   - macOS: Requires Accessibility permissions (user prompt on first run)
   - Windows: Requires admin elevation for low-level hooks (first run)
   - Linux: Requires user in 'input' group or udev rules configuration

3. **Testing Complexity**
   - Platform-specific tests required for native input capture code
   - Integration tests must run on actual macOS, Windows, Linux environments
   - CI/CD must use matrix builds (macos-latest, windows-latest, ubuntu-latest)

4. **Build Complexity**
   - Must configure three platform build systems: Xcode (macOS), Visual Studio (Windows), CMake (Linux)
   - Platform-specific dependencies and toolchains required
   - Cannot cross-compile: must build on native platforms

5. **Deployment Considerations**
   - macOS: Must notarize app, code signing required
   - Windows: Code signing recommended, Microsoft SmartScreen issues without
   - Linux: Multiple distribution formats (AppImage, Flatpak, Snap)

### Mitigation Strategies

**Risk: Platform-specific code complexity**
- **Mitigation**: Abstract input capture behind a common Dart interface
- **Mitigation**: Use platform channels with clear, typed contracts (consider Pigeon)
- **Mitigation**: Comprehensive platform-specific unit tests

**Risk: Permission issues block user experience**
- **Mitigation**: Clear onboarding flow explaining permissions
- **Mitigation**: Graceful degradation if permissions denied
- **Mitigation**: Platform-specific permission request helpers

**Risk: Performance issues with input capture**
- **Mitigation**: Event throttling and debouncing in native code
- **Mitigation**: Asynchronous event processing
- **Mitigation**: Performance profiling on each platform

**Risk: CI/CD complexity with three platforms**
- **Mitigation**: Use GitHub Actions matrix builds
- **Mitigation**: Cache Flutter SDK and platform dependencies
- **Mitigation**: Parallel testing where possible

### Fallback Options

If Flutter proves inadequate during development:

1. **Performance issues**: Profile and optimize, consider moving more logic to native code
2. **Platform limitations**: Worst case, can fall back to Electron (well-understood, proven)
3. **Input capture blockers**: Can implement keyboard-only initially, defer mouse capture

## Implementation Path

### Phase 1: Foundation (PRD-002, PRD-003)
- Set up Flutter project structure
- Configure platform-specific directories
- Establish build and CI/CD pipeline

### Phase 2: Platform Channels (PRD-004)
- Implement input capture platform channels
- Native code for keyboard/mouse on each platform
- Permission handling per platform

### Phase 3: Core Application (PRD-005-008)
- Build Flutter UI and game framework
- Integrate platform channels
- Implement exit mechanisms and base app

### Phase 4: Games & Polish (PRD-009-014)
- Develop games using established foundation
- Performance optimization
- Documentation and accessibility

## Success Criteria

This decision will be considered successful if:

✅ System-level keyboard/mouse capture works reliably on all platforms
✅ Applications achieve 60fps animation performance
✅ App startup time <1 second on modern hardware
✅ Memory usage <200 MB during gameplay
✅ CI/CD pipeline successfully builds and tests on all platforms
✅ Development velocity remains high (hot reload, single UI codebase)
✅ Permission flows are user-friendly and well-documented

## References

### Research Sources

1. **Flutter Desktop Status**
   - [Flutter Desktop Production Readiness](https://www.theregister.com/2022/02/04/flutter_windows_production_release/)
   - [Flutter Desktop 2025 Best Practices](https://www.miquido.com/blog/flutter-app-best-practices/)
   - [Flutter Latest Version 3.35 Info](https://www.technaureus.com/blog-detail/flutter-latest-version-explained)

2. **Platform-Specific Input Capture**
   - [macOS CGEvent Accessibility Permissions](https://gaitatzis.medium.com/capture-key-bindings-in-swift-3050b0ccbf42)
   - [Windows SetWindowsHookEx Low-Level Hooks](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowshookexa)
   - [Linux X11/libinput Permission Management](https://unix.stackexchange.com/questions/242222/read-from-dev-input-devices-without-root-privileges)

3. **Flutter Platform Channels**
   - [Official Platform Channels Documentation](https://docs.flutter.dev/platform-integration/platform-channels)
   - [Flutter Desktop Keyboard Shortcuts](https://medium.com/@pmutisya/easy-keyboard-shortcuts-in-flutter-desktop-apps-498862b56b17)

4. **Testing & CI/CD**
   - [Flutter CI/CD with GitHub Actions 2025](https://medium.com/@akashvyasce/automate-your-flutter-builds-with-ci-cd-using-github-actions-55a7790c3f74)
   - [Flutter Testing on GitHub Actions](https://pradappandiyan.medium.com/how-to-run-flutter-tests-on-github-actions-a2be3e4f8d39)

5. **Alternative Comparisons**
   - [Tauri vs Electron vs Flutter 2025](https://medium.com/@maxel333/comparing-desktop-application-development-frameworks-electron-flutter-tauri-react-native-and-fd2712765377)
   - [Flutter vs Tauri by Ex-Tauri Developer](https://app.daily.dev/posts/flutter-vs-tauri-by-ex-developer-of-tauri-hrdrbmm2f)

### Version Information

- **Flutter**: 3.35.5 (current stable as of November 2025)
- **Dart**: Bundled with Flutter (currently 3.5+)
- **Platform SDKs**:
  - macOS: Xcode 14.0+
  - Windows: Visual Studio 2019+ with C++ tools
  - Linux: CMake, Clang, GTK+ development libraries

## Review and Updates

This TDR should be reviewed if:
- Flutter desktop support experiences breaking changes
- Performance targets cannot be met with current stack
- Major platform API changes affect input capture
- Alternative technologies mature significantly (e.g., Tauri fixes Linux issues)

**Next Review Date**: 2025-07-13 (6 months)

---

**Status**: This decision is **ACCEPTED** and forms the foundation for PRD-002 (Project Setup).
