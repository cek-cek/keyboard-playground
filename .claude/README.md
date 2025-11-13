# Claude Code Web Environment Setup

This directory contains configuration for Claude Code on the web sessions.

## Files

### hooks/SessionStart

This hook automatically runs at the start of every Claude Code session to ensure the Flutter environment is ready. It:

1. **Checks for Flutter** - Detects if Flutter is already available
2. **Runs setup.sh** - Automatically runs setup if Flutter is not found
3. **Configures PATH** - Ensures Flutter is in PATH for the current session
4. **Displays status** - Shows environment info and quick command reference

**This hook makes the environment setup completely automatic - no manual intervention needed!**

### setup.sh

This script sets up the Flutter development environment. It:

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

## Automated Workflow

### First Session (Cold Start)
1. Claude Code starts a new session
2. SessionStart hook runs automatically
3. Hook detects Flutter is not installed
4. Hook runs setup.sh automatically
5. Flutter SDK is downloaded and configured (~1-2 minutes)
6. Environment is ready - you can immediately run `make test`

### Subsequent Sessions
1. Claude Code starts a new session
2. SessionStart hook runs automatically
3. Hook detects Flutter is already installed
4. Hook ensures Flutter is in PATH
5. Environment is ready immediately - you can run `make test` right away

**Result**: From any cold start, just say "run tests" and everything works automatically!
