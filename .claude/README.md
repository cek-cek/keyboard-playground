# Claude Code Web Environment Setup

This directory contains configuration for Claude Code on the web sessions.

## Files

### setup.sh

This script automatically sets up the Flutter development environment when you start a new Claude Code web session. It:

1. **Installs Flutter SDK** (version 3.24.5 stable)
   - Downloads and extracts Flutter to `/opt/flutter`
   - Adds Flutter to PATH
   - Disables analytics
   - Enables Linux desktop support

2. **Installs Linux Build Dependencies**
   - clang, cmake, ninja-build
   - pkg-config
   - GTK 3 development libraries
   - liblzma-dev, libstdc++-12-dev
   - lcov (for code coverage reports)

3. **Configures Flutter**
   - Runs `flutter doctor` to verify installation
   - Downloads required Dart SDK and tools

4. **Installs Project Dependencies**
   - Runs `flutter pub get` to install all packages from pubspec.yaml

## Manual Setup

If you need to run the setup manually:

```bash
cd /home/user/keyboard-playground
./.claude/setup.sh
```

## Development Commands

After setup completes, you can use these commands:

```bash
# Run tests
make test

# Run linter
make analyze

# Format code
make format

# Build Linux app
make build-linux

# Run all CI checks
make ci
```

## Troubleshooting

### Flutter not in PATH

If `flutter` command is not found after setup, add it to your PATH:

```bash
export PATH="/opt/flutter/bin:$PATH"
# or
export PATH="$HOME/flutter/bin:$PATH"
```

### Permission issues

If you encounter permission issues, make sure the setup script is executable:

```bash
chmod +x .claude/setup.sh
```

### Dependency installation fails

If apt-get fails, try updating package lists first:

```bash
sudo apt-get update
```

## Notes

- The setup script is designed for Ubuntu/Debian-based Linux systems
- Flutter version is pinned to 3.24.5 (matches CI/CD configuration)
- The script is idempotent - safe to run multiple times
- Analytics are disabled by default
- Linux desktop support is enabled automatically
