# PRD-004: Input Capture System (Platform-Specific)

**Status**: ⚪ Not Started
**Dependencies**: PRD-003 (Build System & CI/CD)
**Estimated Effort**: 16 hours
**Priority**: P0 - CRITICAL (Critical path - longest task)
**Branch**: `feature/prd-004-input-capture`

## Overview

Implement platform-specific keyboard and mouse capture that intercepts ALL input events at the OS level, including system shortcuts. This is the most technically complex component and enables the safe sandbox environment.

## Context

The core requirement is to capture keyboard and mouse events *before* they reach other applications or trigger system shortcuts. This requires:
- Platform channels between Dart and native code
- OS-level APIs for global event monitoring
- Accessibility permissions (macOS, Windows)
- Event translation from native to Dart

This is the **critical path** component - most other features depend on this.

## Goals

1. ✅ Capture all keyboard events (including system shortcuts like Cmd+Tab, Alt+F4)
2. ✅ Capture all mouse events (movement, clicks, scroll)
3. ✅ Platform channel architecture for native↔Dart communication
4. ✅ Permission handling for all platforms
5. ✅ Event stream API for Dart code
6. ✅ Ability to start/stop capture
7. ✅ Works on macOS, Linux, and Windows

## Non-Goals

- Exit mechanism logic (that's PRD-005)
- UI for displaying events (that's PRD-006)
- Game-specific event handling (that's PRD-009+)

## Requirements

### Functional Requirements

**FR-001**: Platform Channel Architecture
- Define method channel for Dart→Native calls
- Define event channel for Native→Dart events
- Common interface across all platforms

**FR-002**: macOS Implementation
- Use CGEvent APIs to monitor keyboard and mouse
- Request and handle Accessibility permissions
- Capture events globally, not just in-window

**FR-003**: Linux Implementation
- Use X11 XGrabKey/XGrabButton APIs (primary)
- Support Wayland via libinput (if feasible)
- Handle input group permissions

**FR-004**: Windows Implementation
- Use SetWindowsHookEx with WH_KEYBOARD_LL and WH_MOUSE_LL
- Handle administrator elevation if needed
- Capture events globally

**FR-005**: Event Types
- KeyDown, KeyUp events with key code, modifiers
- MouseMove events with position
- MouseDown, MouseUp events with button info
- MouseScroll events with delta

**FR-006**: Start/Stop Control
- `startCapture()` - Begin monitoring
- `stopCapture()` - Stop monitoring
- `isCapturing` - Current state

### Non-Functional Requirements

**NFR-001**: Low latency
- Event delivery <16ms (60 FPS target)
- No perceptible lag between keypress and event

**NFR-002**: Reliability
- No missed events (100% capture rate)
- No crashes from native code
- Graceful handling of permission denial

**NFR-003**: Resource efficiency
- Minimal CPU usage when capturing
- No memory leaks from event stream
- Clean resource cleanup on stop

## Technical Specifications

### Architecture Diagram

```
┌──────────────────────────────────────────────────────┐
│                    Dart Layer                        │
│  ┌────────────────────────────────────────────────┐  │
│  │         lib/platform/input_capture.dart        │  │
│  │                                                │  │
│  │  class InputCapture {                          │  │
│  │    Stream<InputEvent> get events;             │  │
│  │    Future<void> startCapture();               │  │
│  │    Future<void> stopCapture();                │  │
│  │  }                                             │  │
│  └────────────────────────────────────────────────┘  │
│             ↕ MethodChannel / EventChannel           │
└──────────────────────────────────────────────────────┘
                          ↕
┌──────────────────────────────────────────────────────┐
│                  Native Layer                        │
│  ┌─────────────┬──────────────┬──────────────────┐  │
│  │   macOS     │    Linux     │     Windows      │  │
│  │  (Swift)    │    (C++)     │      (C++)       │  │
│  │             │              │                  │  │
│  │ CGEvent     │ X11/Wayland  │ SetWindowsHookEx │  │
│  │ APIs        │   libinput   │   Low-level      │  │
│  └─────────────┴──────────────┴──────────────────┘  │
└──────────────────────────────────────────────────────┘
```

### Platform Channel Definitions

#### Method Channel

```dart
// lib/platform/input_capture.dart
const MethodChannel _methodChannel =
    MethodChannel('com.keyboardplayground/input_capture');

// Methods:
// - 'startCapture': void → bool (success)
// - 'stopCapture': void → bool (success)
// - 'isCapturing': void → bool (current state)
// - 'checkPermissions': void → Map<String, bool>
// - 'requestPermissions': void → bool (granted)
```

#### Event Channel

```dart
// lib/platform/input_capture.dart
const EventChannel _eventChannel =
    EventChannel('com.keyboardplayground/input_events');

// Event stream sends Map<String, dynamic>:
// {
//   'type': 'keyDown' | 'keyUp' | 'mouseMove' | 'mouseDown' | 'mouseUp' | 'mouseScroll',
//   'timestamp': int (milliseconds since epoch),
//   'keyCode': int (for keyboard events),
//   'key': String (for keyboard events, human-readable),
//   'modifiers': List<String> (['shift', 'control', 'alt', 'meta']),
//   'x': double (for mouse events),
//   'y': double (for mouse events),
//   'button': String ('left' | 'right' | 'middle', for mouse click events),
//   'deltaX': double (for scroll events),
//   'deltaY': double (for scroll events),
// }
```

### Dart API

```dart
// lib/platform/input_events.dart
enum InputEventType {
  keyDown,
  keyUp,
  mouseMove,
  mouseDown,
  mouseUp,
  mouseScroll,
}

enum MouseButton {
  left,
  right,
  middle,
  other,
}

enum KeyModifier {
  shift,
  control,
  alt,
  meta, // Cmd on macOS, Win on Windows
}

abstract class InputEvent {
  InputEventType get type;
  DateTime get timestamp;
}

class KeyEvent extends InputEvent {
  final int keyCode;
  final String key;
  final Set<KeyModifier> modifiers;
  final bool isDown;

  KeyEvent({
    required this.keyCode,
    required this.key,
    required this.modifiers,
    required this.isDown,
    required DateTime timestamp,
  });
}

class MouseMoveEvent extends InputEvent {
  final double x;
  final double y;

  MouseMoveEvent({
    required this.x,
    required this.y,
    required DateTime timestamp,
  });
}

class MouseButtonEvent extends InputEvent {
  final MouseButton button;
  final double x;
  final double y;
  final bool isDown;

  MouseButtonEvent({
    required this.button,
    required this.x,
    required this.y,
    required this.isDown,
    required DateTime timestamp,
  });
}

class MouseScrollEvent extends InputEvent {
  final double deltaX;
  final double deltaY;

  MouseScrollEvent({
    required this.deltaX,
    required this.deltaY,
    required DateTime timestamp,
  });
}

// lib/platform/input_capture.dart
class InputCapture {
  static const _methodChannel = MethodChannel('...');
  static const _eventChannel = EventChannel('...');

  Stream<InputEvent>? _eventStream;

  /// Stream of all input events.
  Stream<InputEvent> get events {
    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map(_parseEvent)
        .cast<InputEvent>();
    return _eventStream!;
  }

  /// Starts capturing input events.
  Future<bool> startCapture() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('startCapture');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Stops capturing input events.
  Future<bool> stopCapture() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('stopCapture');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Checks if currently capturing.
  Future<bool> isCapturing() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isCapturing');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Checks permissions status.
  Future<Map<String, bool>> checkPermissions() async {
    try {
      final result = await _methodChannel.invokeMapMethod<String, bool>(
        'checkPermissions',
      );
      return result ?? {};
    } catch (e) {
      return {};
    }
  }

  /// Requests necessary permissions.
  Future<bool> requestPermissions() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'requestPermissions',
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  InputEvent _parseEvent(dynamic data) {
    final map = data as Map;
    final type = map['type'] as String;
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      map['timestamp'] as int,
    );

    switch (type) {
      case 'keyDown':
      case 'keyUp':
        return KeyEvent(
          keyCode: map['keyCode'] as int,
          key: map['key'] as String,
          modifiers: (map['modifiers'] as List)
              .map(_parseModifier)
              .toSet(),
          isDown: type == 'keyDown',
          timestamp: timestamp,
        );

      case 'mouseMove':
        return MouseMoveEvent(
          x: (map['x'] as num).toDouble(),
          y: (map['y'] as num).toDouble(),
          timestamp: timestamp,
        );

      case 'mouseDown':
      case 'mouseUp':
        return MouseButtonEvent(
          button: _parseButton(map['button'] as String),
          x: (map['x'] as num).toDouble(),
          y: (map['y'] as num).toDouble(),
          isDown: type == 'mouseDown',
          timestamp: timestamp,
        );

      case 'mouseScroll':
        return MouseScrollEvent(
          deltaX: (map['deltaX'] as num).toDouble(),
          deltaY: (map['deltaY'] as num).toDouble(),
          timestamp: timestamp,
        );

      default:
        throw UnimplementedError('Unknown event type: $type');
    }
  }

  KeyModifier _parseModifier(dynamic mod) {
    switch (mod as String) {
      case 'shift': return KeyModifier.shift;
      case 'control': return KeyModifier.control;
      case 'alt': return KeyModifier.alt;
      case 'meta': return KeyModifier.meta;
      default: throw ArgumentError('Unknown modifier: $mod');
    }
  }

  MouseButton _parseButton(String button) {
    switch (button) {
      case 'left': return MouseButton.left;
      case 'right': return MouseButton.right;
      case 'middle': return MouseButton.middle;
      default: return MouseButton.other;
    }
  }
}
```

### macOS Implementation (Swift)

```swift
// macos/Runner/InputCapturePlugin.swift
import Cocoa
import FlutterMacOS

class InputCapturePlugin: NSObject, FlutterPlugin {
  private var eventChannel: FlutterEventChannel?
  private var methodChannel: FlutterMethodChannel?
  private var eventSink: FlutterEventSink?
  private var eventTap: CFMachPort?
  private var runLoopSource: CFRunLoopSource?
  private var isCapturing = false

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = InputCapturePlugin()

    let methodChannel = FlutterMethodChannel(
      name: "com.keyboardplayground/input_capture",
      binaryMessenger: registrar.messenger
    )
    instance.methodChannel = methodChannel
    registrar.addMethodCallDelegate(instance, channel: methodChannel)

    let eventChannel = FlutterEventChannel(
      name: "com.keyboardplayground/input_events",
      binaryMessenger: registrar.messenger
    )
    instance.eventChannel = eventChannel
    eventChannel.setStreamHandler(instance)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startCapture":
      result(startCapture())
    case "stopCapture":
      stopCapture()
      result(true)
    case "isCapturing":
      result(isCapturing)
    case "checkPermissions":
      result(checkPermissions())
    case "requestPermissions":
      requestPermissions()
      result(checkPermissions()["accessibility"])
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func startCapture() -> Bool {
    guard !isCapturing else { return true }

    // Check for accessibility permissions
    let trusted = AXIsProcessTrusted()
    guard trusted else {
      print("Accessibility permissions not granted")
      return false
    }

    // Create event tap for keyboard and mouse
    let eventMask = (
      (1 << CGEventType.keyDown.rawValue) |
      (1 << CGEventType.keyUp.rawValue) |
      (1 << CGEventType.mouseMoved.rawValue) |
      (1 << CGEventType.leftMouseDown.rawValue) |
      (1 << CGEventType.leftMouseUp.rawValue) |
      (1 << CGEventType.rightMouseDown.rawValue) |
      (1 << CGEventType.rightMouseUp.rawValue) |
      (1 << CGEventType.scrollWheel.rawValue)
    )

    guard let eventTap = CGEvent.tapCreate(
      tap: .cghidEventTap,
      place: .headInsertEventTap,
      options: .defaultTap,
      eventsOfInterest: CGEventMask(eventMask),
      callback: eventTapCallback,
      userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
    ) else {
      print("Failed to create event tap")
      return false
    }

    self.eventTap = eventTap
    self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: eventTap, enable: true)

    isCapturing = true
    print("Input capture started")
    return true
  }

  private func stopCapture() {
    guard isCapturing else { return }

    if let eventTap = eventTap {
      CGEvent.tapEnable(tap: eventTap, enable: false)
      if let runLoopSource = runLoopSource {
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
      }
    }

    eventTap = nil
    runLoopSource = nil
    isCapturing = false
    print("Input capture stopped")
  }

  private func checkPermissions() -> [String: Bool] {
    return ["accessibility": AXIsProcessTrusted()]
  }

  private func requestPermissions() {
    let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
    AXIsProcessTrustedWithOptions(options)
  }

  private func handleEvent(_ event: CGEvent) {
    guard let eventSink = eventSink else { return }

    let eventData = parseEvent(event)
    eventSink(eventData)
  }

  private func parseEvent(_ event: CGEvent) -> [String: Any] {
    let type = event.type
    let timestamp = Int(Date().timeIntervalSince1970 * 1000)
    var data: [String: Any] = ["timestamp": timestamp]

    switch type {
    case .keyDown, .keyUp:
      data["type"] = type == .keyDown ? "keyDown" : "keyUp"
      data["keyCode"] = Int(event.getIntegerValueField(.keyboardEventKeycode))

      // Get character from key code
      if let chars = event.getStringValueField(.keyboardEventCharacters) {
        data["key"] = chars
      } else {
        data["key"] = ""
      }

      // Parse modifiers
      let flags = event.flags
      var modifiers: [String] = []
      if flags.contains(.maskShift) { modifiers.append("shift") }
      if flags.contains(.maskControl) { modifiers.append("control") }
      if flags.contains(.maskAlternate) { modifiers.append("alt") }
      if flags.contains(.maskCommand) { modifiers.append("meta") }
      data["modifiers"] = modifiers

    case .mouseMoved, .leftMouseDragged, .rightMouseDragged:
      data["type"] = "mouseMove"
      let location = event.location
      data["x"] = location.x
      data["y"] = location.y

    case .leftMouseDown, .leftMouseUp:
      data["type"] = type == .leftMouseDown ? "mouseDown" : "mouseUp"
      data["button"] = "left"
      let location = event.location
      data["x"] = location.x
      data["y"] = location.y

    case .rightMouseDown, .rightMouseUp:
      data["type"] = type == .rightMouseDown ? "mouseDown" : "mouseUp"
      data["button"] = "right"
      let location = event.location
      data["x"] = location.x
      data["y"] = location.y

    case .scrollWheel:
      data["type"] = "mouseScroll"
      data["deltaX"] = event.getDoubleValueField(.scrollWheelEventDeltaAxis1)
      data["deltaY"] = event.getDoubleValueField(.scrollWheelEventDeltaAxis2)

    default:
      break
    }

    return data
  }
}

// Event tap callback function
func eventTapCallback(
  proxy: CGEventTapProxy,
  type: CGEventType,
  event: CGEvent,
  refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
  guard let refcon = refcon else { return Unmanaged.passRetained(event) }

  let plugin = Unmanaged<InputCapturePlugin>.fromOpaque(refcon).takeUnretainedValue()
  plugin.handleEvent(event)

  // Return nil to prevent event propagation (consume the event)
  // Return event to allow it through
  return nil // Consume all events for sandbox behavior
}

extension InputCapturePlugin: FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }
}
```

**Important**: Also update `macos/Runner/AppDelegate.swift`:
```swift
import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false  // Keep app running even when window closes
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Register input capture plugin
    let controller = mainFlutterWindow?.contentViewController as! FlutterViewController
    InputCapturePlugin.register(with: controller.registrar(forPlugin: "InputCapturePlugin"))
  }
}
```

### Linux Implementation (C++ with X11)

Due to length constraints, I'll provide the key structure. Full implementation in code:

```cpp
// linux/input_capture_plugin.cc
#include <flutter_linux/flutter_linux.h>
#include <X11/Xlib.h>
#include <X11/extensions/record.h>

// Key functions:
// - start_capture(): XRecordCreateContext + XRecordEnableContext
// - stop_capture(): XRecordDisableContext
// - event_callback(): Handle XRecordInterceptData
// - send_event_to_dart(): Use g_autoptr with FlMethodChannel

// Similar structure to macOS but using X11 APIs
```

### Windows Implementation (C++ with Win32)

```cpp
// windows/runner/input_capture_plugin.cpp
#include <windows.h>
#include <flutter/method_channel.h>
#include <flutter/event_channel.h>

// Key functions:
// - StartCapture(): SetWindowsHookEx with WH_KEYBOARD_LL and WH_MOUSE_LL
// - StopCapture(): UnhookWindowsHookEx
// - KeyboardProc(): Handle keyboard hook callback
// - MouseProc(): Handle mouse hook callback
// - SendEventToDart(): Use method_channel to send events

// See Windows API documentation for SetWindowsHookEx
```

## Acceptance Criteria

### Platform Channel Setup

- [ ] Method channel registered on all platforms
- [ ] Event channel registered on all platforms
- [ ] Channels respond to method calls from Dart

### Dart API

- [ ] `InputCapture` class created with clean API
- [ ] Event types defined (`KeyEvent`, `MouseMoveEvent`, etc.)
- [ ] Event stream works correctly
- [ ] Start/stop methods work
- [ ] Permission methods work

### macOS Implementation

- [ ] CGEvent tap created successfully
- [ ] All keyboard events captured (including Cmd+Tab, Cmd+Q, etc.)
- [ ] All mouse events captured
- [ ] Events sent to Dart via event channel
- [ ] Accessibility permission prompt works
- [ ] Permission check works
- [ ] No crashes or memory leaks

### Linux Implementation

- [ ] X11 event monitoring works
- [ ] All keyboard events captured
- [ ] All mouse events captured
- [ ] Events sent to Dart
- [ ] Permission handling for input group

### Windows Implementation

- [ ] SetWindowsHookEx hooks installed
- [ ] All keyboard events captured (including Win key combinations)
- [ ] All mouse events captured
- [ ] Events sent to Dart
- [ ] Administrator elevation handled gracefully

### Testing

- [ ] Unit tests for event parsing
- [ ] Integration tests for start/stop
- [ ] Platform-specific tests run in CI
- [ ] Manual testing on all three platforms
- [ ] Event latency <16ms verified

## Implementation Steps

This is a large PRD. Recommend implementing one platform at a time:

### Phase 1: Dart API and macOS (8 hours)

1. Create Dart event types (2 hours)
2. Create `InputCapture` class with platform channels (2 hours)
3. Implement macOS Swift plugin (3 hours)
4. Test on macOS (1 hour)

### Phase 2: Linux (4 hours)

1. Implement Linux C++ plugin (3 hours)
2. Test on Linux (1 hour)

### Phase 3: Windows (4 hours)

1. Implement Windows C++ plugin (3 hours)
2. Test on Windows (1 hour)

## Testing Requirements

### Unit Tests

```dart
// test/unit/platform/input_capture_test.dart
void main() {
  group('InputCapture', () {
    test('parses key down event correctly', () {
      // Test event parsing
    });

    test('parses mouse move event correctly', () {
      // Test event parsing
    });

    // More tests...
  });
}
```

### Integration Tests

```dart
// test/integration/input_capture_test.dart
void main() {
  testWidgets('captures keyboard events', (tester) async {
    final capture = InputCapture();
    await capture.startCapture();

    // Simulate key press (platform-specific test)
    // Verify event received

    await capture.stopCapture();
  });
}
```

### Manual Testing Checklist

- [ ] Capture system shortcuts (Cmd+Tab on macOS, Alt+Tab on Windows/Linux)
- [ ] Capture function keys (F1-F12)
- [ ] Capture modifier-only presses
- [ ] Capture mouse movement in all screen areas
- [ ] Capture all mouse buttons
- [ ] Capture scroll wheel
- [ ] No crashes when starting/stopping repeatedly
- [ ] Memory usage stable over extended capture

## Definition of Done

- [ ] All acceptance criteria met
- [ ] Works on macOS, Linux, and Windows
- [ ] Tests pass on all platforms
- [ ] Code review completed
- [ ] Documentation updated
- [ ] No memory leaks
- [ ] CI builds pass for all platforms
- [ ] DEPENDENCIES.md updated

## Notes for AI Agents

### Platform Development Order

Recommend: **macOS → Linux → Windows**

macOS is cleanest API, develop there first, then adapt to others.

### Common Pitfalls

- ❌ Forgetting to register plugin in AppDelegate/Main
- ❌ Not handling permissions properly
- ❌ Memory leaks from event tap/hooks
- ✅ Test permissions before capture
- ✅ Clean up resources in stopCapture()

### Time Breakdown

- Dart API: 2 hours
- macOS: 6 hours
- Linux: 4 hours
- Windows: 4 hours
- **Total**: 16 hours

This is the longest PRD. It's OK if it takes longer!

## References

- [Flutter Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels)
- [macOS CGEvent](https://developer.apple.com/documentation/coregraphics/cgevent)
- [X11 Xlib Programming Manual](https://www.x.org/releases/current/doc/libX11/libX11/libX11.html)
- [Windows Hooks](https://learn.microsoft.com/en-us/windows/win32/winmsg/hooks)

---

**This is the critical path PRD. Start this first after PRD-003!**
