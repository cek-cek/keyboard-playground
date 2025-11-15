# Installation Guide

Welcome to Keyboard Playground! This guide will help you get the application up and running on your computer.

## Table of Contents

- [System Requirements](#system-requirements)
- [Download & Installation](#download--installation)
  - [macOS](#macos)
  - [Linux](#linux)
  - [Windows](#windows)
- [First Run Setup](#first-run-setup)
- [Troubleshooting](#troubleshooting)

## System Requirements

### All Platforms
- **Display**: 1024x768 minimum resolution (1920x1080 recommended)
- **Input**: Keyboard and mouse
- **Disk Space**: ~100 MB

### Platform-Specific Requirements

#### macOS
- **OS Version**: macOS 10.15 (Catalina) or later
- **Permissions**: Accessibility and Input Monitoring permissions
- **Architecture**: Intel (x86_64) or Apple Silicon (arm64)

#### Linux
- **OS**: Ubuntu 20.04+, Debian 11+, Fedora 34+, or equivalent
- **Display Server**: X11 (Wayland not currently supported)
- **Permissions**: User must be in 'input' group or udev rules configured
- **Dependencies**: GTK 3, X11 libraries

#### Windows
- **OS Version**: Windows 10 version 1809 or later
- **Permissions**: Administrator access (first run only)
- **.NET**: Windows 10 SDK

## Download & Installation

### Building from Source

Since this is an open-source project, you'll build it from the source code:

#### Prerequisites

1. **Install Flutter SDK** (version 3.24 or later)
   ```bash
   # Download Flutter
   # Visit: https://docs.flutter.dev/get-started/install

   # Verify installation
   flutter doctor
   ```

2. **Clone the Repository**
   ```bash
   git clone https://github.com/cek-cek/keyboard-playground.git
   cd keyboard-playground
   ```

3. **Get Dependencies**
   ```bash
   flutter pub get
   ```

### macOS

#### Build the Application

```bash
# Build release version
flutter build macos --release

# The app will be at:
# build/macos/Build/Products/Release/KeyboardPlayground.app
```

#### Remove Quarantine Attribute

macOS may prevent the app from running because it's not from the App Store:

```bash
xattr -cr build/macos/Build/Products/Release/KeyboardPlayground.app
```

#### Move to Applications (Optional)

```bash
cp -r build/macos/Build/Products/Release/KeyboardPlayground.app /Applications/
```

### Linux

#### Install Build Dependencies

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y \
  clang \
  cmake \
  ninja-build \
  pkg-config \
  libgtk-3-dev \
  liblzma-dev \
  libstdc++-12-dev
```

**Fedora:**
```bash
sudo dnf install -y \
  clang \
  cmake \
  ninja-build \
  gtk3-devel \
  xz-devel
```

#### Build the Application

```bash
# Enable Linux desktop support
flutter config --enable-linux-desktop

# Build release version
flutter build linux --release

# The app will be at:
# build/linux/x64/release/bundle/keyboard_playground
```

#### Create Desktop Entry (Optional)

Create a desktop launcher:

```bash
cat > ~/.local/share/applications/keyboard-playground.desktop <<EOF
[Desktop Entry]
Name=Keyboard Playground
Comment=Safe keyboard and mouse playground for children
Exec=/path/to/keyboard-playground/build/linux/x64/release/bundle/keyboard_playground
Icon=/path/to/keyboard-playground/assets/icon.png
Terminal=false
Type=Application
Categories=Education;Game;
EOF
```

Replace `/path/to/keyboard-playground` with the actual path.

### Windows

#### Install Build Dependencies

1. **Install Visual Studio 2022** (Community Edition is free)
   - Download from: https://visualstudio.microsoft.com/downloads/
   - During installation, select "Desktop development with C++"

#### Build the Application

```powershell
# Enable Windows desktop support
flutter config --enable-windows-desktop

# Build release version
flutter build windows --release

# The app will be at:
# build\windows\x64\runner\Release\keyboard_playground.exe
```

#### Create Shortcut (Optional)

Right-click on `keyboard_playground.exe` → Send to → Desktop (create shortcut)

## First Run Setup

### macOS: Grant Permissions

On first run, macOS will request special permissions:

1. **Launch the application**
   ```bash
   open /Applications/KeyboardPlayground.app
   # or
   open build/macos/Build/Products/Release/KeyboardPlayground.app
   ```

2. **System Dialog Will Appear**
   - You'll see a dialog about Accessibility permissions
   - Click "Open System Settings"

3. **Grant Accessibility Permission**
   - Navigate to: **System Settings** → **Privacy & Security** → **Accessibility**
   - Find "KeyboardPlayground" in the list
   - Toggle it ON

4. **Grant Input Monitoring Permission (macOS 11+)**
   - Navigate to: **System Settings** → **Privacy & Security** → **Input Monitoring**
   - Find "KeyboardPlayground" in the list
   - Toggle it ON

5. **Restart the Application**
   - Close and reopen KeyboardPlayground
   - The app should now work correctly

**Note**: If you don't grant these permissions, the app cannot capture keyboard and mouse input.

### Linux: Configure Input Permissions

The application needs permission to capture keyboard and mouse input:

#### Option 1: Add User to Input Group (Recommended)

```bash
# Add your user to the input group
sudo usermod -a -G input $USER

# Log out and log back in for changes to take effect
# Or restart your computer
```

#### Option 2: Configure udev Rules (Alternative)

Create a udev rule file:

```bash
sudo nano /etc/udev/rules.d/99-keyboard-playground.rules
```

Add this content:
```
KERNEL=="event*", SUBSYSTEM=="input", MODE="0660", GROUP="input"
```

Reload udev rules:
```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

#### Verify Permissions

```bash
# Check if you're in the input group
groups | grep input

# If you see 'input' in the output, you're ready!
```

### Windows: First Run as Administrator

1. **Right-click** on `keyboard_playground.exe`
2. Select **"Run as administrator"**
3. Click **"Yes"** on the UAC (User Account Control) prompt
4. After the first successful run, you can run normally (non-admin)

## Testing the Installation

After installation and permission setup:

1. **Launch the application**
2. **Wait for initialization** (should take 2-5 seconds)
3. **Test keyboard input**: Press any keys - you should see visual feedback
4. **Test mouse input**: Move the mouse or click - you should see effects
5. **Practice the exit sequence**:
   - Keyboard: Press `Alt`, then `Control`, then `→ (Right Arrow)`, then `Escape`, then `Q` (in order)
   - Or Mouse: Click the four corners clockwise: Top-Left → Top-Right → Bottom-Right → Bottom-Left

## Next Steps

- Read the [User Guide](user-guide.md) to learn about available games
- Check [Troubleshooting](troubleshooting.md) if you encounter issues
- Explore the games and have fun!

## Troubleshooting

If you encounter issues:

1. **Read the [Troubleshooting Guide](troubleshooting.md)** for common problems
2. **Check permissions** are correctly granted
3. **Verify Flutter installation**: `flutter doctor`
4. **Check system requirements** match your platform

## Uninstallation

### macOS
```bash
# Remove the application
rm -rf /Applications/KeyboardPlayground.app

# Revoke permissions (optional)
# Go to System Settings → Privacy & Security
# Remove KeyboardPlayground from Accessibility and Input Monitoring
```

### Linux
```bash
# Remove the application
rm -rf /path/to/keyboard-playground

# Remove desktop entry (if created)
rm ~/.local/share/applications/keyboard-playground.desktop

# Remove from input group (optional)
sudo gpasswd -d $USER input
```

### Windows
```powershell
# Delete the application folder
# No registry changes are made by the app
```

## Support

For additional help:
- **Issues**: https://github.com/cek-cek/keyboard-playground/issues
- **Discussions**: https://github.com/cek-cek/keyboard-playground/discussions
- **Contributing**: See [CONTRIBUTING.md](../../CONTRIBUTING.md)
