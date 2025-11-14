#include "window_control_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

/// Plugin structure.
struct _WindowControlPlugin {
  GObject parent_instance;
  FlView* view;
};

G_DEFINE_TYPE(WindowControlPlugin, window_control_plugin, G_TYPE_OBJECT)

/// Method channel name.
static constexpr char kChannelName[] = "com.keyboardplayground/window_control";

/// Gets the GTK window from the Flutter view.
static GtkWindow* get_window(WindowControlPlugin* self) {
  if (self->view == nullptr) {
    return nullptr;
  }

  GtkWidget* widget = GTK_WIDGET(self->view);
  GtkWidget* toplevel = gtk_widget_get_toplevel(widget);

  if (GTK_IS_WINDOW(toplevel)) {
    return GTK_WINDOW(toplevel);
  }

  return nullptr;
}

/// Handles the "enterFullscreen" method call.
static FlMethodResponse* enter_fullscreen(WindowControlPlugin* self) {
  GtkWindow* window = get_window(self);
  if (window == nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "NO_WINDOW",
        "Main window not available",
        nullptr));
  }

  // Enter fullscreen mode
  gtk_window_fullscreen(window);

  g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

/// Handles the "exitFullscreen" method call.
static FlMethodResponse* exit_fullscreen(WindowControlPlugin* self) {
  GtkWindow* window = get_window(self);
  if (window == nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "NO_WINDOW",
        "Main window not available",
        nullptr));
  }

  // Exit fullscreen mode
  gtk_window_unfullscreen(window);

  g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

/// Handles the "isFullscreen" method call.
static FlMethodResponse* is_fullscreen(WindowControlPlugin* self) {
  GtkWindow* window = get_window(self);
  if (window == nullptr) {
    g_autoptr(FlValue) result = fl_value_new_bool(FALSE);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  }

  // Check if window is in fullscreen
  GdkWindow* gdk_window = gtk_widget_get_window(GTK_WIDGET(window));
  if (gdk_window == nullptr) {
    g_autoptr(FlValue) result = fl_value_new_bool(FALSE);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  }

  GdkWindowState state = gdk_window_get_state(gdk_window);
  gboolean fullscreen = (state & GDK_WINDOW_STATE_FULLSCREEN) != 0;

  g_autoptr(FlValue) result = fl_value_new_bool(fullscreen);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

/// Handles the "getScreenSize" method call.
static FlMethodResponse* get_screen_size(WindowControlPlugin* self) {
  GdkDisplay* display = gdk_display_get_default();
  if (display == nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "NO_DISPLAY",
        "Default display not available",
        nullptr));
  }

  // Get the primary monitor
  GdkMonitor* monitor = gdk_display_get_primary_monitor(display);
  if (monitor == nullptr) {
    // Fallback to the first monitor if no primary monitor is set
    gint n_monitors = gdk_display_get_n_monitors(display);
    if (n_monitors > 0) {
      monitor = gdk_display_get_monitor(display, 0);
    }
  }

  if (monitor == nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "NO_MONITOR",
        "No monitor available",
        nullptr));
  }

  GdkRectangle geometry;
  gdk_monitor_get_geometry(monitor, &geometry);

  g_autoptr(FlValue) result = fl_value_new_map();
  fl_value_set_string_take(result, "width", fl_value_new_float(geometry.width));
  fl_value_set_string_take(result, "height",
                           fl_value_new_float(geometry.height));

  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

/// Handles method calls on the window control channel.
static void method_call_cb(FlMethodChannel* channel,
                           FlMethodCall* method_call,
                           gpointer user_data) {
  WindowControlPlugin* self = WINDOW_CONTROL_PLUGIN(user_data);

  const gchar* method = fl_method_call_get_name(method_call);
  FlMethodResponse* response = nullptr;

  if (strcmp(method, "enterFullscreen") == 0) {
    response = enter_fullscreen(self);
  } else if (strcmp(method, "exitFullscreen") == 0) {
    response = exit_fullscreen(self);
  } else if (strcmp(method, "isFullscreen") == 0) {
    response = is_fullscreen(self);
  } else if (strcmp(method, "getScreenSize") == 0) {
    response = get_screen_size(self);
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(method_call, response, &error)) {
    g_warning("Failed to send method call response: %s", error->message);
  }
}

/// Disposes of the plugin instance.
static void window_control_plugin_dispose(GObject* object) {
  WindowControlPlugin* self = WINDOW_CONTROL_PLUGIN(object);

  if (self->view != nullptr) {
    g_object_remove_weak_pointer(G_OBJECT(self->view),
                                  reinterpret_cast<gpointer*>(&(self->view)));
    self->view = nullptr;
  }

  G_OBJECT_CLASS(window_control_plugin_parent_class)->dispose(object);
}

/// Initializes the WindowControlPlugin class.
static void window_control_plugin_class_init(WindowControlPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = window_control_plugin_dispose;
}

/// Initializes a WindowControlPlugin instance.
static void window_control_plugin_init(WindowControlPlugin* self) {}

/// Creates a new WindowControlPlugin instance.
WindowControlPlugin* window_control_plugin_new(FlView* view) {
  WindowControlPlugin* self = WINDOW_CONTROL_PLUGIN(
      g_object_new(window_control_plugin_get_type(), nullptr));

  self->view = view;
  g_object_add_weak_pointer(G_OBJECT(view),
                            reinterpret_cast<gpointer*>(&(self->view)));

  return self;
}

/// Registers the plugin with the Flutter engine.
void window_control_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  WindowControlPlugin* plugin = window_control_plugin_new(
      fl_plugin_registrar_get_view(registrar));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      kChannelName,
      FL_METHOD_CODEC(codec));

  fl_method_channel_set_method_call_handler(
      channel, method_call_cb, g_object_ref(plugin), g_object_unref);

  g_object_unref(plugin);
}
