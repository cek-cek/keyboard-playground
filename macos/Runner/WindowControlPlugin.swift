import Cocoa
import FlutterMacOS

/// Flutter plugin for window control operations on macOS.
///
/// Handles fullscreen mode toggling and screen size detection using
/// native macOS APIs (AppKit/Cocoa).
class WindowControlPlugin: NSObject, FlutterPlugin {
    private weak var mainWindow: NSWindow?

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.keyboardplayground/window_control",
            binaryMessenger: registrar.messenger
        )
        let instance = WindowControlPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Get the main window if we don't have it yet
        if mainWindow == nil {
            mainWindow = NSApplication.shared.windows.first
        }

        guard let window = mainWindow else {
            result(FlutterError(
                code: "NO_WINDOW",
                message: "Main window not available",
                details: nil
            ))
            return
        }

        switch call.method {
        case "enterFullscreen":
            enterFullscreen(window: window, result: result)

        case "exitFullscreen":
            exitFullscreen(window: window, result: result)

        case "isFullscreen":
            let isFullscreen = window.styleMask.contains(.fullScreen)
            result(isFullscreen)

        case "getScreenSize":
            getScreenSize(result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Enters fullscreen mode.
    private func enterFullscreen(window: NSWindow, result: @escaping FlutterResult) {
        // Check if already in fullscreen
        if window.styleMask.contains(.fullScreen) {
            result(true)
            return
        }

        // Toggle fullscreen (this will animate into fullscreen)
        DispatchQueue.main.async {
            window.toggleFullScreen(nil)
            // Give it a moment to transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let success = window.styleMask.contains(.fullScreen)
                result(success)
            }
        }
    }

    /// Exits fullscreen mode.
    private func exitFullscreen(window: NSWindow, result: @escaping FlutterResult) {
        // Check if not in fullscreen
        if !window.styleMask.contains(.fullScreen) {
            result(true)
            return
        }

        // Toggle fullscreen (this will animate out of fullscreen)
        DispatchQueue.main.async {
            window.toggleFullScreen(nil)
            // Give it a moment to transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let success = !window.styleMask.contains(.fullScreen)
                result(success)
            }
        }
    }

    /// Gets the screen size of the main display.
    private func getScreenSize(result: @escaping FlutterResult) {
        guard let screen = NSScreen.main else {
            result(FlutterError(
                code: "NO_SCREEN",
                message: "Main screen not available",
                details: nil
            ))
            return
        }

        let frame = screen.frame
        let screenSize: [String: Double] = [
            "width": Double(frame.width),
            "height": Double(frame.height)
        ]

        result(screenSize)
    }
}
