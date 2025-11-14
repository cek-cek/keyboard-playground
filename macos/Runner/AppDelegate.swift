import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Keep app running even when window is closed
    // This is important for the "difficult exit" mechanism
    return false
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Get the main window's Flutter view controller
    let controller: FlutterViewController =
      mainFlutterWindow?.contentViewController as! FlutterViewController

    // Register the input capture plugin
    InputCapturePlugin.register(
      with: controller.registrar(forPlugin: "InputCapturePlugin")
    )

    // Register the window control plugin
    WindowControlPlugin.register(
      with: controller.registrar(forPlugin: "WindowControlPlugin")
    )
  }
}
