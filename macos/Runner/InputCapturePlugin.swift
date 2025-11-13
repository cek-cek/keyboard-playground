import Cocoa
import FlutterMacOS

/// Plugin that captures keyboard and mouse events at the OS level using CGEvent APIs.
///
/// This plugin requires Accessibility permissions to intercept system-wide events.
/// It uses CGEvent tap to monitor all keyboard and mouse events before they reach other applications.
class InputCapturePlugin: NSObject, FlutterPlugin {
  private var methodChannel: FlutterMethodChannel?
  private var eventChannel: FlutterEventChannel?
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
      // Re-check permissions after request
      result(checkPermissions()["accessibility"])
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func startCapture() -> Bool {
    guard !isCapturing else {
      print("InputCapture: Already capturing")
      return true
    }

    // Check for accessibility permissions
    let trusted = AXIsProcessTrusted()
    guard trusted else {
      print("InputCapture: Accessibility permissions not granted")
      return false
    }

    // Create event tap for keyboard and mouse events
    let eventMask = (
      (1 << CGEventType.keyDown.rawValue) |
      (1 << CGEventType.keyUp.rawValue) |
      (1 << CGEventType.mouseMoved.rawValue) |
      (1 << CGEventType.leftMouseDown.rawValue) |
      (1 << CGEventType.leftMouseUp.rawValue) |
      (1 << CGEventType.rightMouseDown.rawValue) |
      (1 << CGEventType.rightMouseUp.rawValue) |
      (1 << CGEventType.otherMouseDown.rawValue) |
      (1 << CGEventType.otherMouseUp.rawValue) |
      (1 << CGEventType.scrollWheel.rawValue) |
      (1 << CGEventType.leftMouseDragged.rawValue) |
      (1 << CGEventType.rightMouseDragged.rawValue) |
      (1 << CGEventType.otherMouseDragged.rawValue)
    )

    guard let eventTap = CGEvent.tapCreate(
      tap: .cghidEventTap,
      place: .headInsertEventTap,
      options: .defaultTap,
      eventsOfInterest: CGEventMask(eventMask),
      callback: eventTapCallback,
      userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
    ) else {
      print("InputCapture: Failed to create event tap")
      return false
    }

    self.eventTap = eventTap
    self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: eventTap, enable: true)

    isCapturing = true
    print("InputCapture: Started successfully")
    return true
  }

  private func stopCapture() {
    guard isCapturing else {
      print("InputCapture: Not currently capturing")
      return
    }

    if let eventTap = eventTap {
      CGEvent.tapEnable(tap: eventTap, enable: false)
      if let runLoopSource = runLoopSource {
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
      }
    }

    eventTap = nil
    runLoopSource = nil
    isCapturing = false
    print("InputCapture: Stopped successfully")
  }

  private func checkPermissions() -> [String: Bool] {
    return ["accessibility": AXIsProcessTrusted()]
  }

  private func requestPermissions() {
    let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
    AXIsProcessTrustedWithOptions(options)
    print("InputCapture: Requested accessibility permissions")
  }

  func handleEvent(_ event: CGEvent) {
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
      if let chars = event.characters {
        data["key"] = chars
      } else {
        // Fallback: try to map key code to key name
        data["key"] = keyCodeToString(Int(event.getIntegerValueField(.keyboardEventKeycode)))
      }

      // Parse modifiers
      let flags = event.flags
      var modifiers: [String] = []
      if flags.contains(.maskShift) { modifiers.append("shift") }
      if flags.contains(.maskControl) { modifiers.append("control") }
      if flags.contains(.maskAlternate) { modifiers.append("alt") }
      if flags.contains(.maskCommand) { modifiers.append("meta") }
      data["modifiers"] = modifiers

    case .mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
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

    case .otherMouseDown, .otherMouseUp:
      data["type"] = type == .otherMouseDown ? "mouseDown" : "mouseUp"
      data["button"] = "middle"
      let location = event.location
      data["x"] = location.x
      data["y"] = location.y

    case .scrollWheel:
      data["type"] = "mouseScroll"
      data["deltaX"] = event.getDoubleValueField(.scrollWheelEventPointDeltaAxis1)
      data["deltaY"] = event.getDoubleValueField(.scrollWheelEventPointDeltaAxis2)

    default:
      break
    }

    return data
  }

  /// Convert macOS key code to human-readable string.
  /// This is a simplified mapping for common keys.
  private func keyCodeToString(_ keyCode: Int) -> String {
    switch keyCode {
    case 0: return "a"
    case 1: return "s"
    case 2: return "d"
    case 3: return "f"
    case 4: return "h"
    case 5: return "g"
    case 6: return "z"
    case 7: return "x"
    case 8: return "c"
    case 9: return "v"
    case 11: return "b"
    case 12: return "q"
    case 13: return "w"
    case 14: return "e"
    case 15: return "r"
    case 16: return "y"
    case 17: return "t"
    case 31: return "o"
    case 32: return "u"
    case 34: return "i"
    case 35: return "p"
    case 36: return "Return"
    case 37: return "l"
    case 38: return "j"
    case 40: return "k"
    case 45: return "n"
    case 46: return "m"
    case 48: return "Tab"
    case 49: return "Space"
    case 51: return "Backspace"
    case 53: return "Escape"
    case 123: return "Left"
    case 124: return "Right"
    case 125: return "Down"
    case 126: return "Up"
    default: return "Key\(keyCode)"
    }
  }
}

/// Event tap callback function that intercepts all events.
///
/// This C-style callback is required by CGEvent.tapCreate.
/// It receives events and forwards them to the plugin instance.
func eventTapCallback(
  proxy: CGEventTapProxy,
  type: CGEventType,
  event: CGEvent,
  refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
  guard let refcon = refcon else {
    return Unmanaged.passRetained(event)
  }

  let plugin = Unmanaged<InputCapturePlugin>.fromOpaque(refcon).takeUnretainedValue()
  plugin.handleEvent(event)

  // Return nil to consume the event (prevent it from reaching other apps)
  // This creates the "sandbox" behavior where captured input doesn't affect the system
  return nil
}

/// Extension to make InputCapturePlugin conform to FlutterStreamHandler.
extension InputCapturePlugin: FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    print("InputCapture: Event stream listener attached")
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    print("InputCapture: Event stream listener detached")
    return nil
  }
}
