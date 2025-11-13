# Platform Requirements Matrix

**Document Version**: 1.0
**Last Updated**: 2025-01-13
**Related**: TDR-001 Technology Stack Selection

## Overview

This document details the platform-specific requirements for implementing Keyboard Playground on macOS, Linux, and Windows. The primary technical challenge is **system-level keyboard and mouse input capture**, which requires native platform APIs on each operating system.

## Platform Comparison Matrix

| Aspect | macOS | Linux | Windows |
|--------|-------|-------|---------|
| **Native Language** | Swift / Objective-C | C++ | C++ |
| **Keyboard Capture API** | CGEvent / CGEventTap | X11 XGrabKeyboard / libinput | SetWindowsHookEx (WH_KEYBOARD_LL) |
| **Mouse Capture API** | NSEvent / CGEvent | X11 XGrabPointer / libinput | SetWindowsHookEx (WH_MOUSE_LL) |
| **Fullscreen API** | NSWindow (fullscreen mask) | X11 / Wayland fullscreen | SetWindowLongPtr (WS_POPUP) |
| **Permissions Required** | Accessibility + Input Monitoring | User in 'input' group / udev rules | Admin elevation (first run) |
| **Permission Scope** | Per-app, user grants in System Settings | System-wide, one-time setup | Per-app, UAC prompt |
| **Permission Persistence** | Persistent after grant | Persistent after group add | Stored in registry |
| **Build Tools** | Xcode 14.0+, CocoaPods | CMake, Clang/GCC, pkg-config | Visual Studio 2019+, MSVC |
| **Flutter Support** | ✅ Stable since 2021 | ✅ Stable since 2021 | ✅ Stable since Feb 2022 |
| **Implementation Complexity** | Medium | High | Medium |
| **Testing Difficulty** | Medium | High | Low |
| **Distribution Complexity** | High (notarization for public distribution) | Medium (multiple formats) | Medium (signing recommended) |

## macOS Implementation Details

### Native Language & APIs

- **Primary Language**: Swift (recommended) or Objective-C
- **Framework**: Cocoa (AppKit)
- **Minimum Version**: macOS 10.15 (Catalina) for modern permission model

### Input Capture APIs

#### Keyboard Capture
```swift
// Primary API: CGEventTap
let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
guard let eventTap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: CGEventMask(eventMask),
    callback: keyboardCallback,
    userInfo: nil
) else {
    // Handle permission denied
    return
}
```

**Key Points:**
- `CGEventTapCreate()` provides read-write access to event stream
- Requires Accessibility permissions (user must grant explicitly)
- Events are captured **before** system processes them
- Can filter specific key codes or capture all keys

#### Mouse Capture
```swift
// Mouse events via CGEvent system
let mouseMask = (1 << CGEventType.mouseMoved.rawValue) |
                (1 << CGEventType.leftMouseDown.rawValue)
// Similar CGEvent.tapCreate setup
```

### Permissions

#### Required Permissions
1. **Accessibility** (Primary)
   - Path: System Settings → Privacy & Security → Accessibility
   - Required for: CGEventTap keyboard/mouse capture
   - User action: Must manually enable app in list

2. **Input Monitoring** (macOS 11+)
   - Path: System Settings → Privacy & Security → Input Monitoring
   - Required for: Monitoring keystrokes system-wide
   - User action: Must manually enable app in list
   - Note: Can override Accessibility permissions on Big Sur+

#### Permission Request Flow
```swift
// Check if we have accessibility permission
let trusted = AXIsProcessTrusted()
if !trusted {
    // Prompt user to grant permission
    let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true]
    AXIsProcessTrustedWithOptions(options)
}
```

**Important:**
- Permission prompt shows system dialog
- User must manually navigate to System Settings
- App should provide clear instructions
- No way to programmatically grant permissions (security feature)

### Fullscreen Implementation
```swift
let window = NSWindow(...)
window.styleMask = [.borderless, .fullScreen]
window.level = .mainMenu + 1  // Above menu bar
window.collectionBehavior = [.canJoinAllSpaces, .fullScreenPrimary]
window.toggleFullScreen(nil)
```

### Platform-Specific Considerations

**Pros:**
- Well-documented APIs with extensive examples
- Strong security model with clear permission boundaries
- Excellent debugging tools (Xcode Instruments)
- Consistent behavior across macOS versions

**Cons:**
- Strict permission requirements frustrate first-time users
- Cannot capture keystrokes in password fields (security feature)
- Notarization required for distribution (Apple Developer Program: $99/year)
- Code signing complexities

**Known Issues:**
- Some system shortcuts (Cmd+H, Cmd+Q) may still trigger macOS actions
- Mission Control shortcuts can exit fullscreen
- Escape key has special behavior in fullscreen

### Build Requirements

- **Xcode**: 14.0 or later
- **macOS SDK**: 10.15+
- **Swift**: 5.5+
- **CocoaPods**: For dependency management

### Code Signing & Distribution

#### For Development/Local Testing (No Cost)

**You do NOT need:**
- ❌ Apple Developer Program membership ($99/year)
- ❌ Notarization
- ❌ Distribution certificates

**You CAN:**
- ✅ Build and run locally on your Mac without any signing
- ✅ Build and test in GitHub Actions (CI/CD)
- ✅ Use ad-hoc signing (automatic, free)
- ✅ Bypass Gatekeeper warnings with: `xattr -cr KeyboardPlayground.app`
- ✅ Grant permissions (Accessibility, Input Monitoring) like any other app

**Local Development Build:**
```bash
# Flutter automatically uses ad-hoc signing for debug builds
flutter build macos --debug

# Or release build with ad-hoc signing (no certificate needed)
flutter build macos --release

# If Gatekeeper complains, remove quarantine attribute
xattr -cr build/macos/Build/Products/Release/KeyboardPlayground.app

# Then open normally
open build/macos/Build/Products/Release/KeyboardPlayground.app
```

**GitHub Actions CI/CD:**
```yaml
# No signing required for testing
- name: Build macOS app
  run: flutter build macos --release

- name: Run tests
  run: flutter test
```

#### For Public Distribution (Costs Apply)

**Only needed if distributing to other users:**
- Apple Developer Program: $99/year
- Code signing certificate: Developer ID Application
- Notarization: Required for macOS 10.15+ downloads

**Why distribution needs notarization:**
- Apps downloaded from internet trigger Gatekeeper
- Notarization proves app was scanned by Apple for malware
- Without it, users see scary warnings and must bypass security

**For this project:**
- Development/testing: **FREE, no notarization**
- If you later distribute: Add notarization in PRD-014 (Accessibility & Polish)

---

## Linux Implementation Details

### Native Language & APIs

- **Primary Language**: C++
- **Display Server**: X11 (primary) + Wayland (future consideration)
- **Minimum Version**: Ubuntu 20.04, Debian 11, Fedora 34 (or equivalent)

### Input Capture APIs

#### Keyboard Capture (X11)
```cpp
// X11 keyboard grab
Display* display = XOpenDisplay(NULL);
Window root = DefaultRootWindow(display);

// Grab all keyboard input
int result = XGrabKeyboard(
    display,
    root,
    True,                    // Owner events
    GrabModeAsync,
    GrabModeAsync,
    CurrentTime
);

// Or use XRecordExtension for non-intrusive monitoring
```

**Alternative: libinput (Wayland-ready)**
```cpp
// Direct access to /dev/input/eventX
int fd = open("/dev/input/event0", O_RDONLY);
struct input_event ev;
read(fd, &ev, sizeof(struct input_event));
```

**Key Points:**
- X11: Mature, well-documented, works everywhere
- libinput: Lower-level, requires root or group permissions
- XGrabKeyboard is intrusive (blocks other apps)
- XRecord is non-intrusive but more complex

#### Mouse Capture (X11)
```cpp
// X11 mouse grab
XGrabPointer(
    display,
    root,
    True,
    PointerMotionMask | ButtonPressMask | ButtonReleaseMask,
    GrabModeAsync,
    GrabModeAsync,
    None,
    None,
    CurrentTime
);
```

### Permissions

#### Option 1: Add User to 'input' Group (Recommended)
```bash
sudo usermod -a -G input $USER
# User must log out and back in
```

**Pros:**
- Simple, standard approach
- Persistent across reboots
- No root required after setup

**Cons:**
- Requires sudo during installation
- User must log out/in for group change to take effect
- Security concern: grants access to all input devices

#### Option 2: udev Rules
```bash
# /etc/udev/rules.d/99-keyboard-playground.rules
KERNEL=="event*", SUBSYSTEM=="input", MODE="0666", GROUP="input"
```

**Pros:**
- More granular control
- Can restrict to specific devices

**Cons:**
- More complex setup
- Requires sudo
- Can conflict with other rules

#### Option 3: Run as Root (NOT RECOMMENDED)
```bash
sudo ./keyboard-playground
```

**Cons:**
- Major security risk
- Users will be uncomfortable
- Bad practice for desktop apps

### Fullscreen Implementation

#### X11
```cpp
Display* display = XOpenDisplay(NULL);
Window window = /* created window */;

// Set fullscreen hint
Atom wm_state = XInternAtom(display, "_NET_WM_STATE", False);
Atom fullscreen = XInternAtom(display, "_NET_WM_STATE_FULLSCREEN", False);

XChangeProperty(
    display, window, wm_state,
    XA_ATOM, 32, PropModeReplace,
    (unsigned char*)&fullscreen, 1
);

// Grab input
XGrabKeyboard(display, window, True, GrabModeAsync, GrabModeAsync, CurrentTime);
XGrabPointer(display, window, True, PointerMotionMask | ButtonPressMask,
             GrabModeAsync, GrabModeAsync, None, None, CurrentTime);
```

#### Wayland (Future Support)
- No standard protocol for input grab in Wayland yet
- XWayland compatibility layer provides X11 APIs
- Native Wayland support requires compositor-specific protocols

### Platform-Specific Considerations

**Pros:**
- Most flexible platform for low-level input access
- No vendor restrictions or gatekeeping
- Excellent for power users and developers
- Free and open-source ecosystem

**Cons:**
- Highest implementation complexity
- X11 vs Wayland fragmentation
- Distribution-specific quirks (systemd vs others)
- Permission setup is non-trivial for average users
- Testing requires multiple distributions

**Known Issues:**
- Wayland compositors may not support input grab
- Some desktop environments (GNOME, KDE) have different shortcut behaviors
- X11 grab can lock out user if app crashes (must implement failsafes)
- Super/Meta key often captured by window manager

### Build Requirements

- **CMake**: 3.16 or later
- **Compiler**: GCC 9+ or Clang 10+
- **Libraries**:
  - `libx11-dev` (X11 support)
  - `libxext-dev` (X11 extensions)
  - `libxrandr-dev` (Multi-monitor)
  - `libgtk-3-dev` (GTK integration for Flutter)
  - `libudev-dev` (Device enumeration)
- **pkg-config**: For library discovery

---

## Windows Implementation Details

### Native Language & APIs

- **Primary Language**: C++
- **Framework**: Win32 API
- **Minimum Version**: Windows 10 version 1809 (October 2018 Update)

### Input Capture APIs

#### Keyboard Capture
```cpp
// Low-level keyboard hook
HHOOK keyboardHook = SetWindowsHookEx(
    WH_KEYBOARD_LL,
    KeyboardProc,      // Callback function
    hInstance,
    0                  // 0 = global hook
);

LRESULT CALLBACK KeyboardProc(int nCode, WPARAM wParam, LPARAM lParam) {
    if (nCode >= 0) {
        KBDLLHOOKSTRUCT* kb = (KBDLLHOOKSTRUCT*)lParam;

        if (wParam == WM_KEYDOWN || wParam == WM_KEYUP) {
            // Process key event
            // kb->vkCode contains virtual key code
            // kb->scanCode contains hardware scan code
        }
    }
    return CallNextHookEx(NULL, nCode, wParam, lParam);
}
```

**Key Points:**
- `WH_KEYBOARD_LL` captures all keyboard events system-wide
- Hook runs **before** system processes events
- Can suppress events by not calling `CallNextHookEx()`
- Hook must be efficient (slow hooks impact system performance)

#### Mouse Capture
```cpp
// Low-level mouse hook
HHOOK mouseHook = SetWindowsHookEx(
    WH_MOUSE_LL,
    MouseProc,
    hInstance,
    0
);

LRESULT CALLBACK MouseProc(int nCode, WPARAM wParam, LPARAM lParam) {
    if (nCode >= 0) {
        MSLLHOOKSTRUCT* ms = (MSLLHOOKSTRUCT*)lParam;
        // ms->pt contains mouse coordinates
        // wParam indicates event type (WM_MOUSEMOVE, WM_LBUTTONDOWN, etc.)
    }
    return CallNextHookEx(NULL, nCode, wParam, lParam);
}
```

### Permissions

#### Admin Elevation (First Run Only)
```xml
<!-- app.manifest -->
<requestedExecutionLevel level="requireAdministrator" uiAccess="false" />
```

**Flow:**
1. User launches app
2. UAC (User Account Control) prompt appears
3. User clicks "Yes" to grant admin rights
4. App registers hooks (requires admin for low-level hooks)
5. Subsequent runs may not require admin (depends on implementation)

**Alternative: No Admin Approach**
- Use `WH_KEYBOARD` instead of `WH_KEYBOARD_LL` (less powerful)
- Only captures events in app's own thread
- Cannot capture system shortcuts
- **Not suitable for our use case**

#### Permission Persistence
```cpp
// Store permission grant in registry
HKEY hKey;
RegCreateKeyEx(HKEY_CURRENT_USER,
               L"Software\\KeyboardPlayground",
               0, NULL, 0, KEY_WRITE, NULL, &hKey, NULL);
RegSetValueEx(hKey, L"PermissionGranted", 0, REG_DWORD,
              (BYTE*)&granted, sizeof(DWORD));
RegCloseKey(hKey);
```

### Fullscreen Implementation
```cpp
// Create borderless fullscreen window
HWND hwnd = CreateWindowEx(
    WS_EX_TOPMOST | WS_EX_APPWINDOW,
    className,
    L"Keyboard Playground",
    WS_POPUP,          // Borderless
    0, 0,              // Position
    GetSystemMetrics(SM_CXSCREEN),
    GetSystemMetrics(SM_CYSCREEN),
    NULL, NULL, hInstance, NULL
);

// Set window to always on top
SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0,
             SWP_NOMOVE | SWP_NOSIZE);

ShowWindow(hwnd, SW_MAXIMIZE);
```

### Platform-Specific Considerations

**Pros:**
- Well-documented Win32 API with decades of resources
- Consistent behavior across Windows 10/11
- Excellent debugging tools (Visual Studio)
- SetWindowsHookEx is straightforward and powerful
- Best testing experience (can run in VM easily)

**Cons:**
- UAC prompt may confuse users
- Must handle admin elevation gracefully
- Code signing recommended (SmartScreen warnings without)
- Windows Defender may flag low-level hooks as suspicious

**Known Issues:**
- Win+L (lock screen) cannot be captured
- Ctrl+Alt+Del cannot be intercepted (security feature)
- Some antivirus software flags hook-based apps
- Performance: slow hooks can lag entire system

### Build Requirements

- **Visual Studio**: 2019 or later (2022 recommended)
- **Windows SDK**: 10.0.18362 or later
- **MSVC**: v142 or later
- **C++ Desktop Development Workload**: Required in VS installer
- **Ninja**: For Flutter build integration

---

## Cross-Platform Testing Requirements

### Per-Platform Test Environments

| Platform | Minimum Test Environment | Recommended |
|----------|-------------------------|-------------|
| **macOS** | macOS 10.15 (Catalina) | macOS 13 (Ventura) or later |
| **Linux** | Ubuntu 20.04 LTS | Ubuntu 22.04 LTS + Fedora 38 |
| **Windows** | Windows 10 1809 | Windows 11 22H2 |

### CI/CD Matrix

```yaml
# GitHub Actions example
strategy:
  matrix:
    os: [macos-latest, ubuntu-latest, windows-latest]
    flutter-version: ['3.35.5']
```

**Build Times (Estimated):**
- macOS: 15-20 minutes
- Linux: 10-15 minutes
- Windows: 12-18 minutes

### Platform-Specific Tests

Each platform requires:
1. **Unit tests** for native input capture code
2. **Integration tests** with Flutter platform channels
3. **Permission flow tests** (manual verification)
4. **Fullscreen mode tests**
5. **Multi-monitor tests** (if applicable)

---

## Distribution Requirements

**Note**: This section is for **public distribution only**. For local development and testing, see platform-specific "Code Signing & Distribution" sections above.

### macOS Distribution (Public)

**Requirements:**
- Apple Developer Program membership ($99/year)
- Code signing certificate (Developer ID Application)
- App notarization (mandatory for macOS 10.15+ when distributed via download)

**When NOT needed:**
- ✅ Local development builds (use ad-hoc signing)
- ✅ CI/CD testing (no signing required)
- ✅ Running on your own Mac (just use `xattr -cr` if needed)

**Process (if distributing to others):**
```bash
# Sign app
codesign --force --deep --sign "Developer ID Application: Your Name" YourApp.app

# Create DMG
create-dmg --volname "Keyboard Playground" --window-size 600 400 \
           KeyboardPlayground.dmg YourApp.app

# Notarize
xcrun notarytool submit KeyboardPlayground.dmg --keychain-profile "AC_PASSWORD"
xcrun stapler staple KeyboardPlayground.dmg
```

**Distribution Formats:**
- `.dmg` (recommended)
- `.pkg` (for enterprise)

---

### Linux Distribution

**Formats:**
1. **AppImage** (recommended)
   - Single file, runs anywhere
   - No installation required
   - ~50-80 MB

2. **Flatpak**
   - Sandboxed environment
   - Flathub distribution
   - Best isolation

3. **Snap**
   - Ubuntu Software store
   - Automatic updates
   - Permission model similar to mobile

4. **Debian/RPM packages**
   - Native package managers
   - Requires maintaining multiple formats

**Recommended:** Start with AppImage for simplicity

---

### Windows Distribution

**Requirements:**
- Code signing certificate (recommended, ~$100-400/year)
- Without signing: SmartScreen warnings

**Process:**
```bash
# Sign executable
signtool sign /f certificate.pfx /p password /tr http://timestamp.digicert.com KeyboardPlayground.exe
```

**Distribution Formats:**
- `.exe` installer (NSIS or Inno Setup)
- `.msi` (enterprise)
- Microsoft Store (requires certification)

---

## Implementation Complexity Summary

### Effort Estimates

| Platform | Setup | Input Capture | Permissions | Testing | Total |
|----------|-------|--------------|-------------|---------|-------|
| **Windows** | 2h | 6h | 2h | 4h | **14h** |
| **macOS** | 3h | 8h | 4h | 5h | **20h** |
| **Linux** | 4h | 12h | 6h | 8h | **30h** |

**Total Platform-Specific Work**: ~64 hours

**Notes:**
- Windows is simplest due to straightforward SetWindowsHookEx API
- macOS has complexity in permission handling but APIs are clean
- Linux is most complex due to X11/Wayland fragmentation and permission models

---

## Recommended Development Order

Based on complexity and user base:

1. **Windows** (Easiest)
   - Simplest APIs
   - Best testing in VMs
   - Largest user base

2. **macOS** (Medium)
   - Well-documented
   - Clear permission model
   - Can test on real hardware easily

3. **Linux** (Hardest)
   - Most complex permission handling
   - Need to test multiple distros
   - Smallest user base (for desktop apps)

---

## Next Steps

This requirements matrix informs:
- **PRD-002**: Project structure must accommodate platform-specific directories
- **PRD-004**: Input capture implementation follows these specifications
- **PRD-007**: Testing infrastructure must support platform-specific tests

**Related Documents:**
- [TDR-001: Technology Stack Selection](./TDR-001-technology-stack.md)
- [dependencies.md](./dependencies.md)

---

**Last Updated**: 2025-01-13
**Maintained By**: Development Team
**Review Schedule**: Quarterly or when platform APIs change
