# Keyboard Playground

![CI Status](https://github.com/cek-cek/keyboard-playground/workflows/CI/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.24%2B-blue.svg)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey.svg)](https://github.com/cek-cek/keyboard-playground)

A safe, entertaining desktop application for young children (ages 1-6) to explore keyboard and mouse input without triggering system actions. Watch letters explode, keyboards light up, and mouse trails dance across the screen!

## ✨ Features

- 🎹 **Full Input Capture** - Captures all keyboard and mouse events safely
- 🎮 **Three Interactive Games**:
  - **Exploding Letters** - Each key press creates colorful particle explosions
  - **Keyboard Visualizer** - Watch your keyboard light up as you type
  - **Mouse Visualizer** - See trails and ripples following your mouse
- 👶 **Kid-Friendly Design** - Bright colors, large visuals, immediate feedback
- 🔒 **Safe Environment** - No file access, no network, no system shortcuts
- 🚪 **Smart Exit Mechanism** - Prevents accidental closure by toddlers
- 💻 **Cross-Platform** - Works on macOS, Linux, and Windows

## 🎥 Demo

<!-- TODO: Add screenshots or GIF demo here -->

**Games Available:**

1. **Exploding Letters** - Press keys to see giant letters explode into colorful particles
2. **Keyboard Visualizer** - Real-time keyboard layout with key highlights
3. **Mouse Visualizer** - Mouse trails, click ripples, and button state indicators

## 🚀 Quick Start

### For Users

Want to try Keyboard Playground? See our **[Installation Guide](docs/user/installation.md)** for detailed setup instructions.

**Quick Installation:**

```bash
# 1. Install Flutter SDK (https://docs.flutter.dev/get-started/install)

# 2. Clone and build
git clone https://github.com/cek-cek/keyboard-playground.git
cd keyboard-playground
flutter pub get
flutter build <platform> --release  # platform: macos, linux, or windows

# 3. Run the app (see Installation Guide for platform-specific details)
```

**Important**: You'll need to grant permissions for input capture. See the [Installation Guide](docs/user/installation.md) for platform-specific instructions.

### For Developers

Want to contribute or add games? See **[Contributing Guidelines](CONTRIBUTING.md)**.

**Quick Development Setup:**

```bash
# Clone repository
git clone https://github.com/cek-cek/keyboard-playground.git
cd keyboard-playground

# Setup environment (installs Flutter if needed)
make setup

# Run tests
make test

# Run the app in debug mode
flutter run -d linux  # or macos, windows

# Before committing
make ci  # Runs format check, analyze, and tests
```

## 📖 Documentation

### For Users
- **[Installation Guide](docs/user/installation.md)** - Platform-specific setup instructions
- **[User Guide](docs/user/user-guide.md)** - How to use the app, game descriptions, exit sequences
- **[Troubleshooting](docs/user/troubleshooting.md)** - Common issues and solutions

### For Developers
- **[Architecture Overview](docs/architecture/architecture-overview.md)** - System design and component interactions
- **[Adding Games Guide](docs/architecture/adding-games.md)** - Create your own interactive games
- **[Platform Requirements](docs/architecture/platform-requirements.md)** - Platform-specific technical details
- **[Contributing Guide](CONTRIBUTING.md)** - Development workflow and guidelines

### Project Management
- **[Master Plan](PLAN.md)** - Project vision and roadmap
- **[PRD Directory](docs/prds/)** - Product requirements documents
- **[Dependencies Graph](DEPENDENCIES.md)** - PRD execution order and status
- **[AI Agent Guide](AGENTS.md)** - Coordination guide for AI assistants

## 🏗️ Project Status

**Current Version:** 0.1.0+1 (Foundation Complete)

**Completed PRDs:** PRD-001 through PRD-011
- ✅ Technology stack selected and validated
- ✅ Project structure and build system configured
- ✅ CI/CD pipeline operational
- ✅ Input capture working on all platforms
- ✅ Exit mechanism implemented
- ✅ UI framework complete
- ✅ Three games implemented

**In Progress:** PRD-012 (Documentation System)

**Upcoming:**
- PRD-013: Performance Optimization
- PRD-014: Accessibility Features

See [DEPENDENCIES.md](DEPENDENCIES.md) for detailed status.

## 🎮 How to Exit

Since all input is captured, the app requires a specific sequence to exit:

**Keyboard Sequence** (5 seconds):
1. Alt
2. Control
3. Right Arrow (→)
4. Escape
5. Q

**Mouse Sequence** (10 seconds):
- Click the four corners clockwise: Top-Left → Top-Right → Bottom-Right → Bottom-Left

A progress indicator will guide you through the sequence.

## 🛠️ Technology Stack

- **Framework:** Flutter 3.24+
- **Language:** Dart 3.2+
- **Platforms:** macOS (10.15+), Linux (Ubuntu 20.04+), Windows (10+)
- **Native Code:** Swift (macOS), C++ (Linux/Windows)
- **State Management:** ValueNotifier, StreamController
- **Testing:** flutter_test, mocktail, integration_test

See [TDR-001](docs/architecture/TDR-001-technology-stack.md) for technology selection rationale.

## 🤝 Contributing

We welcome contributions! Whether you want to:
- 🎮 Add a new game
- 🐛 Fix a bug
- 📚 Improve documentation
- ✨ Suggest new features

Please see our [Contributing Guide](CONTRIBUTING.md) for:
- Development setup
- Code conventions
- PR process
- Testing requirements

**Want to add a game?** Start with the [Adding Games Guide](docs/architecture/adding-games.md) - you can create a basic game in under an hour!

## 📊 Development Workflow

```bash
# Setup (one-time)
make setup              # Install Flutter and dependencies

# Development
make test               # Run all tests
make analyze            # Run linter
make format             # Format code
make ci                 # Run all CI checks (required before commit)

# Building
make build-linux        # Build for Linux
make build-macos        # Build for macOS
make build-windows      # Build for Windows

# Cleaning
make clean              # Clean build artifacts
```

All commands work cross-platform via the Makefile.

## 🔒 Privacy & Security

- ✅ **No network access** - App is completely offline
- ✅ **No file access** - Doesn't read or write user files
- ✅ **No data collection** - No telemetry or analytics
- ✅ **Open source** - All code is publicly auditable
- ✅ **Sandboxed** - Runs in OS security sandbox

Input events are processed locally and never leave your computer.

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

You are free to:
- ✅ Use commercially
- ✅ Modify
- ✅ Distribute
- ✅ Use privately

## 🙏 Acknowledgments

- Built with [Flutter](https://flutter.dev) - Google's UI toolkit
- Inspired by the need for safe digital exploration for young children
- Thanks to all contributors and testers

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/cek-cek/keyboard-playground/issues)
- **Discussions:** [GitHub Discussions](https://github.com/cek-cek/keyboard-playground/discussions)
- **Documentation:** [docs/](docs/)

---

**Made with ❤️ for curious little hands exploring the digital world** 👶⌨️🖱️
