# User Guide

Welcome to Keyboard Playground! This guide will help you understand how to use the application and make the most of its features.

## Table of Contents

- [What is Keyboard Playground?](#what-is-keyboard-playground)
- [Getting Started](#getting-started)
- [How to Exit](#how-to-exit)
- [Available Games](#available-games)
- [Switching Games](#switching-games)
- [Frequently Asked Questions](#frequently-asked-questions)

## What is Keyboard Playground?

Keyboard Playground is a safe, entertaining desktop application designed for young children to explore keyboard and mouse input. When running, it:

- **Captures all keyboard and mouse input** - nothing reaches the system
- **Displays colorful, interactive visual feedback** - kids see immediate results
- **Prevents accidental closure** - requires a specific sequence to exit
- **Provides a safe learning environment** - no files, network, or system access

**Perfect for:**
- Toddlers and young children exploring the keyboard
- Teaching kids about computers in a safe environment
- Keeping kids entertained while parents work nearby

## Getting Started

### First Launch

1. **Launch the application** (see [Installation Guide](installation.md) for platform-specific instructions)
2. **Grant permissions** when prompted (required for input capture)
3. **Wait for initialization** (2-5 seconds)
4. **The game will start automatically** in fullscreen mode

### What You'll See

When the app launches, you'll see:
- **Fullscreen mode** - the entire screen is taken over
- **The active game** - one of the visual games (default: Keyboard Visualizer)
- **Colorful backgrounds** - kid-friendly gradients
- **Interactive elements** - respond to keyboard and mouse input

### Important Safety Note

Once running, **all keyboard and mouse input is captured**. This means:
- ✅ Kids can press any key safely
- ✅ No system shortcuts work (Alt+Tab, Cmd+Q, etc.)
- ✅ Mouse clicks won't trigger anything outside the app
- ⚠️ You must know the exit sequence to close the app (see below)

## How to Exit

The application has **two exit methods** to prevent accidental closure by children:

### Method 1: Keyboard Sequence

Press these keys **in order**, one after another (within 5 seconds):

1. **Alt** (or Option on macOS)
2. **Control** (or Ctrl)
3. **Right Arrow** (→)
4. **Escape** (Esc)
5. **Q**

**Visual Progress**: You'll see a progress indicator showing which step you're on.

**Tips:**
- Each key press must be **in order**
- Press wrong key = sequence resets
- Wait too long (>5 seconds) = sequence resets
- Only works on key **down** events (pressing, not releasing)

### Method 2: Mouse Sequence

Click the **four corners** of the screen in clockwise order (within 10 seconds):

1. **Top-Left** corner
2. **Top-Right** corner
3. **Bottom-Right** corner
4. **Bottom-Left** corner

**Visual Progress**: You'll see which corners you've clicked.

**Tips:**
- Must click within **50 pixels** of each corner
- Must complete within **10 seconds**
- Wrong corner = sequence resets
- Timeout = sequence resets

### Exit Progress Indicator

While performing an exit sequence, you'll see:
- **Progress bar** - shows completion percentage
- **Current step** - displays which step you're on
- **Time remaining** - countdown to timeout
- **Instructions** - reminds you of the sequence

## Available Games

Keyboard Playground includes **three interactive games**:

### 1. Keyboard Visualizer

**Description**: Watch your keyboard light up as you type!

**What it does:**
- Displays a visual representation of a full keyboard
- Keys light up when you press them
- Different colors for different key types:
  - **Letters** (A-Z): Blue glow
  - **Numbers** (0-9): Green glow
  - **Modifiers** (Shift, Ctrl, Alt): Purple glow
  - **Special keys** (Enter, Space, etc.): Orange glow

**Perfect for:**
- Learning keyboard layout
- Teaching letter recognition
- Exploring modifier keys
- Understanding keyboard structure

**How to play:**
- Just press any key on the keyboard
- Watch it light up on screen
- Try pressing multiple keys at once
- Explore all the keys!

### 2. Exploding Letters

**Description**: Letters explode with colorful particles when you press keys!

**What it does:**
- Each key press creates a giant letter at a random position
- Letters explode into colorful particles
- Particle physics simulation (gravity, velocity, fade)
- Multiple simultaneous explosions supported

**Perfect for:**
- Letter recognition
- Cause-and-effect learning
- Visual entertainment
- Keeping toddlers engaged

**How to play:**
- Press any letter or number key
- Watch the character appear and explode
- Press keys rapidly for multiple explosions
- Enjoy the colorful particle effects!

**Visual effects:**
- Letters appear at random positions
- Letters grow and fade
- Particles shoot out in all directions
- Each letter has a random bright color
- Animations last about 3 seconds

### 3. Mouse Visualizer

**Description**: See your mouse movements and clicks with colorful trails and ripples!

**What it does:**
- Large, colorful cursor follows your mouse
- Fading trail shows recent positions (30 positions, 1 second)
- Click ripples expand from click location
- Button state indicators show which buttons are pressed

**Perfect for:**
- Learning mouse control
- Improving motor skills
- Understanding mouse buttons
- Visual feedback for movement

**How to play:**
- Move the mouse around the screen
- Watch the trail follow your cursor
- Click to create ripple effects:
  - **Left click**: Blue ripples
  - **Right click**: Green ripples
  - **Middle click**: Purple ripples
- Try moving fast and slow to see different trail effects

**Visual effects:**
- Large cursor at mouse position
- Smooth trail fading behind cursor
- Expanding ripples on clicks (different colors)
- Button indicators in screen corners: **[L]** **[R]** **[M]**

## Switching Games

Currently, the app starts with the **Keyboard Visualizer** game by default.

**Note**: Game switching UI is planned for a future version. For now, you can change the default game by:
1. Exiting the application
2. Modifying the code in `lib/main.dart` (line ~137):
   ```dart
   ..switchGame('keyboard_visualizer');  // Change this ID
   ```
   Options: `'keyboard_visualizer'`, `'exploding_letters'`, `'mouse_visualizer'`
3. Rebuilding the app: `flutter build <platform> --release`

## Frequently Asked Questions

### General Questions

**Q: Can my child accidentally close the app?**
A: No. The exit sequence is specifically designed to be difficult for young children to trigger accidentally.

**Q: Will my child be able to access files or the internet?**
A: No. The app captures all input and runs in fullscreen mode. There's no file access, network access, or system access.

**Q: Can system shortcuts (Alt+Tab, Cmd+Q) work while the app is running?**
A: Most shortcuts are blocked, but some platform-specific shortcuts (like Mission Control on macOS) may still work. The app does its best to capture all input.

**Q: What ages is this appropriate for?**
A: Designed for toddlers and young children (ages 1-6) who are exploring keyboards and mice. Older children may find it less engaging.

### Technical Questions

**Q: Why does the app need special permissions?**
A: To capture **all** keyboard and mouse input (including system shortcuts), the app needs Accessibility permissions on macOS, input group membership on Linux, or administrator access on Windows.

**Q: Is my input data sent anywhere?**
A: No. All input is processed locally. No network access, no data collection, no telemetry.

**Q: Can I run this in windowed mode?**
A: No. The app must run in fullscreen to properly capture all input and prevent accidental system interactions.

**Q: Does this work on laptops?**
A: Yes! It works on laptops, desktops, and any computer running macOS, Linux, or Windows.

**Q: Can I use an external keyboard or mouse?**
A: Yes. The app captures input from all connected input devices.

### Troubleshooting

**Q: The app won't start / shows a permissions error**
A: See the [Installation Guide](installation.md) for platform-specific permission setup, or check the [Troubleshooting Guide](troubleshooting.md).

**Q: Input isn't being captured**
A: Verify permissions are granted correctly. On macOS, check both Accessibility and Input Monitoring. On Linux, verify you're in the `input` group.

**Q: Fullscreen isn't working**
A: Some desktop environments (especially on Linux) may prevent fullscreen. Try disabling compositor or using a different desktop environment.

**Q: Performance is slow / laggy**
A: Ensure your system meets the minimum requirements (see [Installation Guide](installation.md)). Close other resource-intensive applications.

**Q: I can't exit the app!**
A: Follow the [exit sequences](#how-to-exit) exactly. If stuck, you may need to:
- **macOS**: Force quit with Cmd+Option+Esc (if not captured)
- **Linux**: Switch to TTY (Ctrl+Alt+F2) and kill the process
- **Windows**: Press Ctrl+Alt+Delete and use Task Manager

For more troubleshooting help, see the [Troubleshooting Guide](troubleshooting.md).

## Tips for Parents

1. **Practice the exit sequence** before leaving your child alone with the app
2. **Set a timer** if you want to limit screen time
3. **Stay nearby** (especially for first-time use) to help if needed
4. **Explore together** - show your child the different effects
5. **Use it as a teaching opportunity** - talk about letters, colors, and cause-and-effect

## Feedback and Support

We'd love to hear from you!

- **Report bugs**: https://github.com/cek-cek/keyboard-playground/issues
- **Request features**: https://github.com/cek-cek/keyboard-playground/discussions
- **Contribute**: See [CONTRIBUTING.md](../../CONTRIBUTING.md)

## Next Steps

- **Explore all three games** to find your child's favorite
- **Read the [Troubleshooting Guide](troubleshooting.md)** if you encounter issues
- **Share feedback** - help us improve the app!

---

**Have fun and happy playing!** 🎮🎨✨
