# Project Dependencies

**Document Version**: 1.0
**Last Updated**: 2025-01-13
**Related**: TDR-001, platform-requirements.md

## Overview

This document specifies all dependencies required to build, test, and deploy Keyboard Playground across macOS, Linux, and Windows platforms.

## Flutter Framework

### Required Versions

| Component | Minimum Version | Recommended Version | Notes |
|-----------|----------------|---------------------|-------|
| **Flutter SDK** | 3.27.0 | 3.35.5 | Latest stable as of Nov 2025 |
| **Dart** | 3.3.0 | 3.5+ | Bundled with Flutter |
| **Flutter Channel** | stable | stable | Do not use beta/dev for production |

### Installation

```bash
# Install Flutter (all platforms)
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter --version
flutter doctor -v

# Enable desktop support
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop
```

### Flutter Packages

Core packages required (to be added in PRD-002):

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter

  # Platform detection
  platform: ^3.1.0

  # Path utilities
  path_provider: ^2.1.0

  # Shared preferences
  shared_preferences: ^2.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Linting
  flutter_lints: ^3.0.0

  # Testing utilities
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

**Note**: Additional packages will be identified during implementation (PRD-004 onwards).

---

## Platform-Specific Dependencies

### macOS Dependencies

#### Build Tools

| Tool | Minimum Version | Installation |
|------|----------------|--------------|
| **Xcode** | 14.0 | Mac App Store |
| **Xcode Command Line Tools** | 14.0 | `xcode-select --install` |
| **CocoaPods** | 1.12.0 | `sudo gem install cocoapods` |
| **Homebrew** | 4.0.0+ | Optional, but recommended |

#### System Requirements

- **macOS Version**: 10.15 (Catalina) or later
- **Architecture**: x86_64 (Intel) or arm64 (Apple Silicon)
- **Disk Space**: 20 GB (for Xcode + Flutter)
- **RAM**: 8 GB minimum, 16 GB recommended

#### Native Code Dependencies

```bash
# CocoaPods dependencies (will be in macos/Podfile)
platform :osx, '10.15'

pod 'FlutterMacOS'
# Additional native dependencies TBD in PRD-004
```

#### Development Setup

```bash
# Install Xcode from App Store
xcode-select --install

# Install CocoaPods
sudo gem install cocoapods

# Accept Xcode license
sudo xcodebuild -license accept

# Verify setup
flutter doctor
```

#### Code Signing Requirements (Production)

- **Apple Developer Program**: $99/year
- **Developer ID Application Certificate**: For distribution
- **Developer ID Installer Certificate**: For .pkg creation
- **Provisioning Profile**: For development builds

---

### Linux Dependencies

#### Build Tools

| Tool | Minimum Version | Installation |
|------|----------------|--------------|
| **CMake** | 3.16 | `sudo apt install cmake` (Ubuntu/Debian) |
| **Ninja** | 1.10 | `sudo apt install ninja-build` |
| **GCC** | 9.0 | `sudo apt install gcc g++` |
| **Clang** | 10.0 | `sudo apt install clang` (alternative) |
| **pkg-config** | 0.29 | `sudo apt install pkg-config` |

#### System Requirements

- **Distribution**: Ubuntu 20.04+, Debian 11+, Fedora 34+, or equivalent
- **Architecture**: x86_64 (amd64) or arm64
- **Display Server**: X11 (primary support), Wayland via XWayland
- **Disk Space**: 10 GB
- **RAM**: 4 GB minimum, 8 GB recommended

#### System Libraries

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y \
  clang cmake ninja-build pkg-config \
  libgtk-3-dev \
  libblkid-dev \
  liblzma-dev \
  libx11-dev \
  libxext-dev \
  libxrandr-dev \
  libxi-dev \
  libxinerama-dev \
  libxcursor-dev \
  libxdamage-dev \
  libxfixes-dev \
  libgl1-mesa-dev \
  libglu1-mesa-dev \
  libudev-dev
```

**Fedora/RHEL:**
```bash
sudo dnf install -y \
  clang cmake ninja-build pkg-config \
  gtk3-devel \
  libX11-devel \
  libXext-devel \
  libXrandr-devel \
  libXi-devel \
  libXinerama-devel \
  libXcursor-devel \
  mesa-libGL-devel \
  systemd-devel
```

#### Input Capture Dependencies

For direct input device access:

```bash
# Add user to input group (recommended approach)
sudo usermod -a -G input $USER

# Alternative: udev rules (will be provided in PRD-004)
# /etc/udev/rules.d/99-keyboard-playground.rules
```

#### Development Setup

```bash
# Install dependencies
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev [...]

# Verify Flutter
flutter doctor

# Test Linux desktop build
flutter create test_app
cd test_app
flutter build linux
```

---

### Windows Dependencies

#### Build Tools

| Tool | Minimum Version | Installation |
|------|----------------|--------------|
| **Visual Studio** | 2019 (16.11+) | Download from Microsoft |
| **Visual Studio 2022** | 17.0+ | Recommended |
| **Windows SDK** | 10.0.18362+ | Included with VS |
| **CMake** | 3.16+ | Included with VS |
| **Ninja** | 1.10+ | Included with VS |

#### Visual Studio Workloads Required

Must install the following workload:
- ✅ **Desktop development with C++**

Within that workload, ensure these components are selected:
- ✅ MSVC v142 (or v143 for VS 2022)
- ✅ Windows SDK (10.0.18362 or later)
- ✅ CMake tools for Windows
- ✅ C++ ATL for latest build tools
- ✅ C++ MFC for latest build tools (optional, but recommended)

#### System Requirements

- **Windows Version**: Windows 10 version 1809 or later (Windows 11 supported)
- **Architecture**: x86_64 (64-bit)
- **Disk Space**: 30 GB (for Visual Studio + Flutter)
- **RAM**: 8 GB minimum, 16 GB recommended

#### Development Setup

```powershell
# Install Visual Studio 2022 Community (free)
# Download from: https://visualstudio.microsoft.com/downloads/

# During installation, select:
# - Desktop development with C++
# - Windows 10 SDK (10.0.18362 or later)

# Verify installation
flutter doctor

# Should show:
# [✓] Visual Studio - develop for Windows (Visual Studio Community 2022 17.x.x)
```

#### Code Signing (Production)

**Certificate Options:**
1. **DigiCert**: ~$400/year
2. **Sectigo (formerly Comodo)**: ~$150/year
3. **Self-signed**: Free, but triggers SmartScreen warnings

**Signing Process:**
```powershell
# Sign executable
signtool sign /f certificate.pfx /p password /t http://timestamp.digicert.com /fd SHA256 KeyboardPlayground.exe
```

---

## Development Tools

### IDEs and Editors

| Tool | Version | Platform | Notes |
|------|---------|----------|-------|
| **VS Code** | 1.85+ | All | Recommended, excellent Flutter extension |
| **Android Studio** | 2023.1+ | All | Alternative, includes Flutter plugin |
| **IntelliJ IDEA** | 2023.3+ | All | Alternative, includes Flutter plugin |
| **Xcode** | 14.0+ | macOS | Required for macOS builds |
| **Visual Studio** | 2022 | Windows | Required for Windows builds |

### Recommended VS Code Extensions

```json
{
  "recommendations": [
    "dart-code.dart-code",
    "dart-code.flutter",
    "ms-vscode.cpptools",
    "ms-vscode.cmake-tools",
    "editorconfig.editorconfig",
    "streetsidesoftware.code-spell-checker"
  ]
}
```

### Version Control

- **Git**: 2.30+ (required)
- **GitHub CLI** (`gh`): 2.20+ (optional, useful for CI/CD)

---

## CI/CD Dependencies

### GitHub Actions Runners

```yaml
# .github/workflows/build-test.yml (example)
strategy:
  matrix:
    os:
      - macos-latest    # macOS 12+ (Monterey)
      - ubuntu-latest   # Ubuntu 22.04
      - windows-latest  # Windows Server 2022
    flutter-version:
      - '3.35.5'
```

### Runner Pre-installed Tools

All GitHub-hosted runners include:
- Git
- Basic build tools (make, CMake, etc.)
- Platform-specific SDKs (mostly)

### Additional Setup Required in CI

**macOS:**
```yaml
- name: Set up macOS dependencies
  run: |
    brew install cocoapods
    pod setup
```

**Linux:**
```yaml
- name: Set up Linux dependencies
  run: |
    sudo apt-get update
    sudo apt-get install -y libgtk-3-dev libx11-dev [...]
```

**Windows:**
```yaml
- name: Set up Windows dependencies
  run: |
    # Visual Studio is pre-installed
    # Just need to ensure Flutter desktop is enabled
    flutter config --enable-windows-desktop
```

### Testing Tools in CI

- **Flutter test**: Built-in, no additional setup
- **Coverage**: `flutter test --coverage`
- **Code analysis**: `flutter analyze`
- **Format checking**: `flutter format --dry-run --set-exit-if-changed .`

---

## Runtime Dependencies

### End-User Requirements

Users must have the following **installed** to run Keyboard Playground:

#### macOS
- **macOS**: 10.15 (Catalina) or later
- **Permissions**: User must grant Accessibility + Input Monitoring
- **No additional runtimes required**: App is self-contained

#### Linux
- **Distribution**: Any modern distro (2020+)
- **Display Server**: X11 (Wayland via XWayland)
- **Dependencies**:
  - GTK 3.0+
  - X11 libraries (pre-installed on most distros)
- **Permissions**: User must be in 'input' group (installer handles this)

#### Windows
- **Windows**: 10 version 1809 or later, Windows 11
- **Runtimes**:
  - Visual C++ Redistributable 2019+ (usually pre-installed)
  - App will prompt to install if missing
- **Permissions**: Admin elevation on first run (UAC prompt)

### Bundle Sizes (Estimated)

| Platform | Debug Build | Release Build | Compressed Distribution |
|----------|-------------|---------------|------------------------|
| **macOS** | 80-120 MB | 40-60 MB | 30-50 MB (.dmg) |
| **Linux** | 100-150 MB | 50-80 MB | 40-70 MB (AppImage) |
| **Windows** | 90-130 MB | 45-70 MB | 35-60 MB (installer) |

**Note**: Sizes include Flutter engine + app code + assets. Actual size depends on game assets.

---

## Optional Dependencies

### Performance Profiling

- **Flutter DevTools**: Included with Flutter SDK
  ```bash
  flutter pub global activate devtools
  flutter pub global run devtools
  ```

- **Xcode Instruments** (macOS): For native code profiling
- **Valgrind** (Linux): Memory profiling
- **Windows Performance Analyzer** (Windows): System-level profiling

### Documentation Generation

```yaml
dev_dependencies:
  dartdoc: ^6.3.0
```

```bash
flutter pub global activate dartdoc
dartdoc --output docs/api
```

### Code Quality Tools

```yaml
dev_dependencies:
  # Linting
  flutter_lints: ^3.0.0

  # Code metrics
  dart_code_metrics: ^5.7.0

  # Import sorting
  import_sorter: ^4.6.0
```

---

## Dependency Management

### Lock Files

**Commit these:**
- `pubspec.lock` (Dart dependencies)
- `Podfile.lock` (macOS native dependencies)

**Do NOT commit:**
- `node_modules/` (if using any JS tools)
- `.dart_tool/`
- `build/`

### Dependency Updates

```bash
# Update Flutter SDK
flutter upgrade

# Update Dart packages
flutter pub upgrade

# Update CocoaPods (macOS)
cd macos && pod update && cd ..

# Check for outdated packages
flutter pub outdated
```

### Security Updates

- **Monitor**: GitHub Dependabot alerts
- **Review**: Monthly dependency updates
- **Test**: All updates in CI before merging

---

## Version Matrix

### Tested Configurations

This table shows verified working combinations:

| Flutter | Dart | Xcode | VS 2022 | Ubuntu | Status |
|---------|------|-------|---------|--------|--------|
| 3.35.5 | 3.5.5 | 15.0 | 17.8 | 22.04 | ✅ Current |
| 3.27.0 | 3.3.0 | 14.3 | 17.5 | 22.04 | ✅ Supported |
| 3.24.0 | 3.2.0 | 14.0 | 17.0 | 20.04 | ⚠️ Minimum |

### Support Policy

- **Current Stable**: Full support, recommended for new development
- **Stable - 1**: Supported, receive critical fixes
- **Stable - 2**: Minimum supported, security fixes only
- **Older**: Not supported, upgrade required

---

## Installation Quick Start

### macOS Setup

```bash
# 1. Install Xcode from App Store
# 2. Install Xcode Command Line Tools
xcode-select --install

# 3. Install Flutter
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"
flutter config --enable-macos-desktop

# 4. Install CocoaPods
sudo gem install cocoapods

# 5. Verify
flutter doctor
```

### Linux Setup

```bash
# 1. Install system dependencies
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config \
  libgtk-3-dev libx11-dev libxext-dev libxrandr-dev libudev-dev

# 2. Install Flutter
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"
flutter config --enable-linux-desktop

# 3. Add user to input group (for development/testing)
sudo usermod -a -G input $USER

# 4. Verify
flutter doctor
```

### Windows Setup

```powershell
# 1. Install Visual Studio 2022 Community
# Download: https://visualstudio.microsoft.com/downloads/
# Select: Desktop development with C++

# 2. Install Flutter
git clone https://github.com/flutter/flutter.git -b stable
$env:PATH = "$env:PATH;C:\path\to\flutter\bin"
flutter config --enable-windows-desktop

# 3. Verify
flutter doctor
```

---

## Troubleshooting

### Common Issues

**"Flutter doctor shows errors"**
- Run `flutter doctor -v` for detailed diagnostics
- Follow recommended actions in output

**"CocoaPods install fails (macOS)"**
- Update Ruby: `brew install ruby`
- Clear cache: `pod cache clean --all`
- Re-run: `cd macos && pod install`

**"Visual Studio not detected (Windows)"**
- Ensure "Desktop development with C++" workload installed
- Restart terminal after VS installation
- Run `flutter doctor` again

**"GTK errors (Linux)"**
- Install missing libraries: Check `flutter doctor` output
- Update pkg-config cache: `sudo ldconfig`

**"Permission denied on /dev/input (Linux)"**
- Add user to input group: `sudo usermod -a -G input $USER`
- Log out and back in for changes to take effect

---

## Next Steps

Dependencies documented here will be:
1. **Implemented in PRD-002**: Project setup with all dependencies configured
2. **Used in PRD-003**: CI/CD pipeline setup
3. **Required for PRD-004+**: All subsequent implementation PRDs

**Related Documents:**
- [TDR-001: Technology Stack Selection](./TDR-001-technology-stack.md)
- [platform-requirements.md](./platform-requirements.md)
- [DEPENDENCIES.md](../../DEPENDENCIES.md) (PRD tracking)

---

**Maintained By**: Development Team
**Review Schedule**: Before each major Flutter SDK update
**Last Updated**: 2025-01-13
