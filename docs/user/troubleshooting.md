# Troubleshooting Guide

This guide helps you resolve common issues with Keyboard Playground.

## Table of Contents

- [Common Issues (All Platforms)](#common-issues-all-platforms)
- [macOS Specific Issues](#macos-specific-issues)
- [Linux Specific Issues](#linux-specific-issues)
- [Windows Specific Issues](#windows-specific-issues)
- [Performance Issues](#performance-issues)
- [Getting Help](#getting-help)

## Common Issues (All Platforms)

### App Won't Start

**Symptoms**: App crashes immediately, shows error screen, or doesn't launch

**Solutions**:

1. **Check Flutter installation**:
   ```bash
   flutter doctor
   ```
   Ensure all required components are installed.

2. **Verify dependencies**:
   ```bash
   cd keyboard-playground
   flutter pub get
   ```

3. **Rebuild the app**:
   ```bash
   flutter clean
   flutter build <platform> --release
   ```

4. **Check system requirements**:
   - Minimum screen resolution: 1024x768
   - Sufficient disk space (~100 MB)
   - Operating system meets minimum version

### Initialization Hangs / Stuck on Loading Screen

**Symptoms**: "Initializing..." screen doesn't progress

**Causes**:
- Permissions not granted
- Platform channel communication failure
- Native code not responding

**Solutions**:

1. **Wait 10-15 seconds** - some systems are slower
2. **Check permissions** (see platform-specific sections below)
3. **Restart the app**
4. **Check logs**:
   ```bash
   # Run in debug mode to see logs
   flutter run -d <platform> --verbose
   ```

### Exit Sequence Not Working

**Symptoms**: Can't exit the app using keyboard or mouse sequence

**Solutions**:

1. **Ensure you're following the exact sequence**:
   - **Keyboard**: Alt, Control, Right Arrow, Escape, Q (in order, within 5 seconds)
   - **Mouse**: Top-Left, Top-Right, Bottom-Right, Bottom-Left corners (within 10 seconds, <50px from corner)

2. **Watch the progress indicator** - it shows if your input is recognized

3. **Try the other method** - if keyboard doesn't work, try mouse (or vice versa)

4. **Force quit** if completely stuck:
   - **macOS**: Cmd+Option+Esc → Select KeyboardPlayground → Force Quit
   - **Linux**: Ctrl+Alt+F2 (switch to TTY), login, run `pkill keyboard_playground`, then Ctrl+Alt+F7 to return
   - **Windows**: Ctrl+Alt+Delete → Task Manager → End Task

### No Visual Feedback from Input

**Symptoms**: Keys pressed or mouse moved, but nothing happens on screen

**Causes**:
- Input capture not started
- Permissions not granted
- Game not responding to events

**Solutions**:

1. **Check permissions** (platform-specific, see below)
2. **Verify the app is in fullscreen mode**
3. **Restart the app** to reinitialize input capture
4. **Check if input capture is running**:
   - Look for "Input capture started" in debug logs
   - Run with `flutter run -d <platform> --verbose`

## macOS Specific Issues

### "Keyboard Playground is not allowed to monitor your computer"

**Cause**: Accessibility permissions not granted

**Solution**:

1. Open **System Settings** (or System Preferences)
2. Go to **Privacy & Security** → **Accessibility**
3. Find **KeyboardPlayground** in the list
4. **Toggle it ON** (click the checkbox)
5. **Restart the app**

**If KeyboardPlayground doesn't appear in the list**:
- Launch the app first (it will request permissions)
- Close and reopen System Settings
- Try clicking the **+** button and manually adding the app

### "Permission Denied" Error on Launch

**Cause**: Input Monitoring permissions not granted (macOS 11+)

**Solution**:

1. Open **System Settings**
2. Go to **Privacy & Security** → **Input Monitoring**
3. Find **KeyboardPlayground** in the list
4. **Toggle it ON**
5. **Restart the app**

### "App is Damaged" or "Cannot Be Opened"

**Cause**: Gatekeeper quarantine attribute on unsigned app

**Solution**:

```bash
# Remove quarantine attribute
xattr -cr /Applications/KeyboardPlayground.app

# Or if running from build directory
xattr -cr build/macos/Build/Products/Release/KeyboardPlayground.app
```

Then try launching again.

### Some System Shortcuts Still Work (Mission Control, Spotlight)

**Symptom**: Certain Mac shortcuts aren't captured

**Explanation**: Some system shortcuts have higher priority than app-level capture. This is a macOS security feature.

**Workarounds**:
- Disable Mission Control shortcuts: System Settings → Keyboard → Keyboard Shortcuts → Mission Control
- Disable Spotlight: System Settings → Keyboard → Keyboard Shortcuts → Spotlight
- Or avoid triggering these shortcuts while app is running

### Fullscreen Exits Unexpectedly

**Cause**: System shortcuts (F11, Mission Control gestures) trigger fullscreen exit

**Solution**:
- Disable conflicting shortcuts (see above)
- App will attempt to re-enter fullscreen
- Use mouse exit sequence if keyboard exit isn't working

## Linux Specific Issues

### "Permission Denied" or Input Not Captured

**Cause**: User not in `input` group or udev rules not configured

**Solution**:

#### Option 1: Add User to Input Group (Recommended)

```bash
# Add your user to the input group
sudo usermod -a -G input $USER

# Verify
groups | grep input

# Log out and log back in (or reboot)
```

#### Option 2: Configure udev Rules

```bash
# Create udev rule
sudo nano /etc/udev/rules.d/99-keyboard-playground.rules
```

Add:
```
KERNEL=="event*", SUBSYSTEM=="input", MODE="0660", GROUP="input"
```

Reload:
```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### Missing Shared Libraries

**Symptom**: Error about missing `.so` files (libgtk-3, libX11, etc.)

**Solution**:

**Ubuntu/Debian**:
```bash
sudo apt-get install -y \
  libgtk-3-0 \
  libx11-6 \
  libgdk-pixbuf2.0-0 \
  libglib2.0-0 \
  libc6
```

**Fedora**:
```bash
sudo dnf install -y \
  gtk3 \
  libX11 \
  gdk-pixbuf2 \
  glib2
```

### Fullscreen Doesn't Work / Window Manager Issues

**Symptom**: App doesn't go fullscreen or shows window decorations

**Causes**:
- Compositor interference
- Window manager doesn't support fullscreen
- Wayland compatibility issues

**Solutions**:

1. **Disable compositor** (if using one):
   ```bash
   # For KDE/KWin
   Alt+Shift+F12

   # For Xfce
   Settings → Window Manager Tweaks → Compositor → Disable
   ```

2. **Switch to X11** (if using Wayland):
   - Log out
   - At login screen, select "GNOME on Xorg" or similar
   - Log back in
   - Run the app

3. **Try a different desktop environment** (last resort):
   - GNOME, KDE Plasma, and Xfce generally work well
   - Wayland support is experimental

### Blank Screen / No Graphics

**Symptom**: App launches but shows black or blank screen

**Solutions**:

1. **Update graphics drivers**
2. **Try software rendering**:
   ```bash
   LIBGL_ALWAYS_SOFTWARE=1 ./keyboard_playground
   ```
3. **Check OpenGL support**:
   ```bash
   glxinfo | grep "OpenGL version"
   ```
   Should be OpenGL 2.0 or higher

## Windows Specific Issues

### "This App Has Been Blocked by Your Administrator"

**Cause**: UAC (User Account Control) or antivirus blocking

**Solution**:

1. **Run as administrator** (right-click → Run as administrator)
2. **Add exception in antivirus** (if using one)
3. **Check UAC settings**:
   - Control Panel → User Accounts → Change User Account Control settings
   - Lower to "Notify me only when apps try to make changes"

### Missing DLL Files

**Symptom**: Error about missing `VCRUNTIME140.dll`, `MSVCP140.dll`, etc.

**Solution**:

Install **Visual C++ Redistributable**:
- Download from: https://aka.ms/vs/17/release/vc_redist.x64.exe
- Run the installer
- Restart your computer
- Try launching the app again

### Input Not Captured / Hook Failed

**Symptom**: App launches but input isn't captured

**Causes**:
- Insufficient permissions
- Another app already has a global hook
- Antivirus blocking hook installation

**Solutions**:

1. **Run as administrator** (first time only)
2. **Close other apps** that might use global hooks (keyboard remappers, macros, etc.)
3. **Add exception in antivirus**:
   - Windows Defender: Settings → Virus & threat protection → Manage settings → Add exclusion
   - Add the `keyboard_playground.exe` executable

### Fullscreen Covers Taskbar

**Symptom**: Taskbar still visible in fullscreen

**Explanation**: This is normal Windows behavior for borderless fullscreen.

**Solutions**:
- If you need to access taskbar, use the exit sequence
- Or disable "Auto-hide taskbar" in Windows settings (not recommended)

## Performance Issues

### Low Frame Rate / Stuttering

**Symptoms**: Animations are choppy, mouse trail lags, particles stutter

**Solutions**:

1. **Close other applications** (especially browsers, video players)
2. **Check system resources**:
   - Task Manager (Windows) / Activity Monitor (macOS) / System Monitor (Linux)
   - Ensure CPU < 80%, RAM < 90%
3. **Update graphics drivers**
4. **Lower screen resolution** (if using 4K display)

### High CPU Usage

**Symptom**: CPU at 100% while app is running

**Causes**:
- Too many simultaneous animations
- Inefficient rendering

**Solutions**:
- Use **Keyboard Visualizer** game (lowest CPU usage)
- Avoid **Exploding Letters** game if CPU is limited (most intensive)
- Close background applications

### Memory Leak / Increasing RAM Usage

**Symptom**: App uses more and more memory over time

**Temporary Solution**:
- Exit and restart the app periodically

**Report**:
- This may be a bug - please report at: https://github.com/cek-cek/keyboard-playground/issues
- Include: platform, OS version, which game, how long running

## Debugging Tips

### Enable Debug Logging

Run the app in debug mode to see detailed logs:

```bash
flutter run -d <platform> --verbose
```

Look for:
- "Input capture started" (confirms input system working)
- "Permission granted" (confirms permissions OK)
- Any error messages or stack traces

### Check Platform Channel Communication

Debug logs will show platform channel calls:
- `startCapture` → should return `true`
- `checkPermissions` → should show granted permissions
- Event stream → should show incoming key/mouse events

### Test in Isolation

To determine if issue is platform-specific:
1. Test on a different computer (same OS)
2. Test on a different OS (if available)
3. Compare behavior across platforms

## Getting Help

If you've tried all the above and still have issues:

### Before Requesting Help

Gather this information:
- **Platform**: macOS / Linux / Windows
- **OS Version**: (e.g., macOS 14.1, Ubuntu 22.04, Windows 11)
- **Flutter Version**: Run `flutter --version`
- **App Version**: Check commit hash or release tag
- **Error Messages**: Copy full error text
- **Steps to Reproduce**: What did you do before the issue occurred?
- **Debug Logs**: Run with `--verbose` and copy relevant output

### Where to Get Help

1. **Check existing issues**: https://github.com/cek-cek/keyboard-playground/issues
2. **Search discussions**: https://github.com/cek-cek/keyboard-playground/discussions
3. **Open a new issue**: https://github.com/cek-cek/keyboard-playground/issues/new
   - Use the bug report template
   - Include all information from "Before Requesting Help" above

### Emergency: Can't Exit the App

If you're completely stuck:

- **macOS**:
  - Press Cmd+Option+Esc (if not captured)
  - Select KeyboardPlayground
  - Click Force Quit

- **Linux**:
  - Press Ctrl+Alt+F2 (switch to TTY)
  - Log in
  - Run: `pkill -9 keyboard_playground`
  - Press Ctrl+Alt+F7 (return to GUI)

- **Windows**:
  - Press Ctrl+Alt+Delete
  - Select Task Manager
  - Find KeyboardPlayground
  - Click End Task

---

**Still having trouble?** We're here to help! Open an issue on GitHub and we'll assist you.
