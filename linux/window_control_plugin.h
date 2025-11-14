#ifndef WINDOW_CONTROL_PLUGIN_H_
#define WINDOW_CONTROL_PLUGIN_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

/// Plugin for window control operations on Linux.
///
/// Handles fullscreen mode toggling and screen size detection using
/// GTK and X11 APIs.
G_DECLARE_FINAL_TYPE(WindowControlPlugin,
                     window_control_plugin,
                     WINDOW_CONTROL,
                     PLUGIN,
                     GObject)

/// Creates a new window control plugin instance.
///
/// @param view The Flutter view.
/// @return A new WindowControlPlugin instance.
WindowControlPlugin* window_control_plugin_new(FlView* view);

/// Registers the window control plugin with the registrar.
///
/// @param registrar The plugin registrar.
void window_control_plugin_register_with_registrar(FlPluginRegistrar* registrar);

G_END_DECLS

#endif  // WINDOW_CONTROL_PLUGIN_H_
