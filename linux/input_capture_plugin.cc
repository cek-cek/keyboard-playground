#include "input_capture_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <X11/Xlib.h>
#include <X11/extensions/record.h>
#include <X11/keysym.h>
#include <pthread.h>

#include <cstring>
#include <map>
#include <string>

#define INPUT_CAPTURE_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), input_capture_plugin_get_type(), \
                               InputCapturePlugin))

struct _InputCapturePlugin {
  GObject parent_instance;

  FlMethodChannel* method_channel;
  FlEventChannel* event_channel;
  FlEventChannelHandler* event_handler;

  Display* display;
  Display* record_display;
  XRecordContext record_context;
  pthread_t record_thread;
  bool is_capturing;
  bool thread_running;
};

G_DEFINE_TYPE(InputCapturePlugin, input_capture_plugin, g_object_get_type())

// Forward declarations
static void start_capture(InputCapturePlugin* self);
static void stop_capture(InputCapturePlugin* self);
static void* record_thread_func(void* arg);
static void record_event_callback(XPointer closure, XRecordInterceptData* data);
static void send_event_to_dart(InputCapturePlugin* self, FlValue* event_data);
static const char* keycode_to_string(KeySym keysym);

// Method channel callback
static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                          gpointer user_data) {
  InputCapturePlugin* self = INPUT_CAPTURE_PLUGIN(user_data);
  const gchar* method = fl_method_call_get_name(method_call);

  g_autoptr(FlMethodResponse) response = nullptr;

  if (strcmp(method, "startCapture") == 0) {
    start_capture(self);
    g_autoptr(FlValue) result = fl_value_new_bool(self->is_capturing);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "stopCapture") == 0) {
    stop_capture(self);
    g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "isCapturing") == 0) {
    g_autoptr(FlValue) result = fl_value_new_bool(self->is_capturing);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "checkPermissions") == 0) {
    // On Linux, we check if X11 RECORD extension is available
    int major, minor;
    bool has_record = XRecordQueryVersion(self->display, &major, &minor);

    g_autoptr(FlValue) result = fl_value_new_map();
    fl_value_set_string_take(result, "x11_record",
                            fl_value_new_bool(has_record));
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "requestPermissions") == 0) {
    // On Linux, permissions are handled by the system
    // Just return true if RECORD extension is available
    int major, minor;
    bool has_record = XRecordQueryVersion(self->display, &major, &minor);
    g_autoptr(FlValue) result = fl_value_new_bool(has_record);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

// Event channel listen callback
static FlMethodErrorResponse* listen_cb(FlEventChannel* channel,
                                       FlValue* args,
                                       gpointer user_data) {
  g_print("InputCapture: Event stream listener attached\n");
  return nullptr;
}

// Event channel cancel callback
static FlMethodErrorResponse* cancel_cb(FlEventChannel* channel,
                                       FlValue* args,
                                       gpointer user_data) {
  g_print("InputCapture: Event stream listener detached\n");
  return nullptr;
}

// Start capturing input
static void start_capture(InputCapturePlugin* self) {
  if (self->is_capturing) {
    g_print("InputCapture: Already capturing\n");
    return;
  }

  // Create a separate display connection for recording
  self->record_display = XOpenDisplay(nullptr);
  if (!self->record_display) {
    g_print("InputCapture: Failed to open display for recording\n");
    return;
  }

  // Set up the record range for all events
  XRecordClientSpec clients = XRecordAllClients;
  XRecordRange* range = XRecordAllocRange();
  if (!range) {
    g_print("InputCapture: Failed to allocate record range\n");
    XCloseDisplay(self->record_display);
    self->record_display = nullptr;
    return;
  }

  // Capture all keyboard and pointer events
  range->device_events.first = KeyPress;
  range->device_events.last = MotionNotify;

  // Create the record context
  self->record_context = XRecordCreateContext(
      self->record_display, 0, &clients, 1, &range, 1);

  XFree(range);

  if (!self->record_context) {
    g_print("InputCapture: Failed to create record context\n");
    XCloseDisplay(self->record_display);
    self->record_display = nullptr;
    return;
  }

  // Start the recording thread
  int ret = pthread_create(&self->record_thread, nullptr, record_thread_func, self);
  if (ret != 0) {
    g_print("InputCapture: Failed to create recording thread: %d\n", ret);
    XRecordFreeContext(self->record_display, self->record_context);
    XCloseDisplay(self->record_display);
    self->record_display = nullptr;
    self->record_context = 0;
    return;
  }
  self->is_capturing = true;
  self->thread_running = true;

  g_print("InputCapture: Started successfully\n");
}

// Stop capturing input
static void stop_capture(InputCapturePlugin* self) {
  if (!self->is_capturing) {
    g_print("InputCapture: Not currently capturing\n");
    return;
  }

  self->is_capturing = false;
  self->thread_running = false;

  // Disable the record context
  if (self->record_context) {
    XRecordDisableContext(self->display, self->record_context);
    XRecordFreeContext(self->display, self->record_context);
    self->record_context = 0;
  }

  // Wait for thread to finish
  pthread_join(self->record_thread, nullptr);

  // Close the record display
  if (self->record_display) {
    XCloseDisplay(self->record_display);
    self->record_display = nullptr;
  }

  g_print("InputCapture: Stopped successfully\n");
}

// Thread function for recording events
static void* record_thread_func(void* arg) {
  InputCapturePlugin* self = INPUT_CAPTURE_PLUGIN(arg);

  // Enable the record context (this blocks until disabled)
  XRecordEnableContext(self->record_display, self->record_context,
                      record_event_callback, (XPointer)self);

  return nullptr;
}

// Callback for recorded events
static void record_event_callback(XPointer closure, XRecordInterceptData* data) {
  if (data->category != XRecordFromServer) {
    XRecordFreeData(data);
    return;
  }

  InputCapturePlugin* self = INPUT_CAPTURE_PLUGIN(closure);

  // Parse the event
  unsigned char* event_data = data->data;
  int event_type = event_data[0] & 0x7F;

  g_autoptr(FlValue) event_map = fl_value_new_map();

  // Get timestamp
  gint64 timestamp = g_get_real_time() / 1000; // Convert to milliseconds
  fl_value_set_string_take(event_map, "timestamp", fl_value_new_int(timestamp));

  switch (event_type) {
    case KeyPress:
    case KeyRelease: {
      fl_value_set_string_take(event_map, "type",
                              fl_value_new_string(event_type == KeyPress ? "keyDown" : "keyUp"));

      // Extract key code (byte 1)
      unsigned char keycode = event_data[1];
      fl_value_set_string_take(event_map, "keyCode", fl_value_new_int(keycode));

      // Convert keycode to keysym
      KeySym keysym = XKeycodeToKeysym(self->display, keycode, 0);
      const char* key_string = keycode_to_string(keysym);
      fl_value_set_string_take(event_map, "key", fl_value_new_string(key_string));

      // Extract modifiers (byte 28-29)
      unsigned char modifier_state = event_data[28];
      g_autoptr(FlValue) modifiers = fl_value_new_list();
      if (modifier_state & ShiftMask) {
        fl_value_append_take(modifiers, fl_value_new_string("shift"));
      }
      if (modifier_state & ControlMask) {
        fl_value_append_take(modifiers, fl_value_new_string("control"));
      }
      if (modifier_state & Mod1Mask) {  // Alt
        fl_value_append_take(modifiers, fl_value_new_string("alt"));
      }
      if (modifier_state & Mod4Mask) {  // Super/Meta
        fl_value_append_take(modifiers, fl_value_new_string("meta"));
      }
      fl_value_set_string_take(event_map, "modifiers", modifiers);

      send_event_to_dart(self, event_map);
      break;
    }

    case ButtonPress:
    case ButtonRelease: {
      fl_value_set_string_take(event_map, "type",
                              fl_value_new_string(event_type == ButtonPress ? "mouseDown" : "mouseUp"));

      // Extract button number (byte 1)
      unsigned char button = event_data[1];
      const char* button_name = "other";
      if (button == 1) button_name = "left";
      else if (button == 2) button_name = "middle";
      else if (button == 3) button_name = "right";

      fl_value_set_string_take(event_map, "button", fl_value_new_string(button_name));

      // Extract position (bytes 24-27 for x, 28-31 for y - root coordinates)
      int16_t x = *(int16_t*)(event_data + 24);
      int16_t y = *(int16_t*)(event_data + 26);
      fl_value_set_string_take(event_map, "x", fl_value_new_float(x));
      fl_value_set_string_take(event_map, "y", fl_value_new_float(y));

      // Handle scroll wheel (buttons 4, 5 for vertical, 6, 7 for horizontal)
      if (button >= 4 && button <= 7) {
        fl_value_set_string_take(event_map, "type", fl_value_new_string("mouseScroll"));
        fl_value_remove(event_map, fl_value_new_string("button"));

        double deltaX = 0.0;
        double deltaY = 0.0;
        if (button == 4) deltaY = 1.0;      // Scroll up
        else if (button == 5) deltaY = -1.0; // Scroll down
        else if (button == 6) deltaX = 1.0;  // Scroll left
        else if (button == 7) deltaX = -1.0; // Scroll right

        fl_value_set_string_take(event_map, "deltaX", fl_value_new_float(deltaX));
        fl_value_set_string_take(event_map, "deltaY", fl_value_new_float(deltaY));
      }

      send_event_to_dart(self, event_map);
      break;
    }

    case MotionNotify: {
      fl_value_set_string_take(event_map, "type", fl_value_new_string("mouseMove"));

      // Extract position
      int16_t x = *(int16_t*)(event_data + 24);
      int16_t y = *(int16_t*)(event_data + 26);
      fl_value_set_string_take(event_map, "x", fl_value_new_float(x));
      fl_value_set_string_take(event_map, "y", fl_value_new_float(y));

      send_event_to_dart(self, event_map);
      break;
    }
  }

  XRecordFreeData(data);
}

// Send event to Dart via event channel
static void send_event_to_dart(InputCapturePlugin* self, FlValue* event_data) {
  if (self->event_handler) {
    fl_event_channel_send(self->event_channel, event_data, nullptr, nullptr);
  }
}

// Convert X11 KeySym to string
static const char* keycode_to_string(KeySym keysym) {
  // Common printable characters
  if (keysym >= XK_space && keysym <= XK_asciitilde) {
    static char buf[2];
    buf[0] = (char)keysym;
    buf[1] = '\0';
    return buf;
  }

  // Special keys
  switch (keysym) {
    case XK_Return: return "Return";
    case XK_Tab: return "Tab";
    case XK_BackSpace: return "Backspace";
    case XK_Escape: return "Escape";
    case XK_Delete: return "Delete";
    case XK_Home: return "Home";
    case XK_End: return "End";
    case XK_Page_Up: return "PageUp";
    case XK_Page_Down: return "PageDown";
    case XK_Left: return "Left";
    case XK_Right: return "Right";
    case XK_Up: return "Up";
    case XK_Down: return "Down";
    case XK_F1: return "F1";
    case XK_F2: return "F2";
    case XK_F3: return "F3";
    case XK_F4: return "F4";
    case XK_F5: return "F5";
    case XK_F6: return "F6";
    case XK_F7: return "F7";
    case XK_F8: return "F8";
    case XK_F9: return "F9";
    case XK_F10: return "F10";
    case XK_F11: return "F11";
    case XK_F12: return "F12";
    case XK_Shift_L:
    case XK_Shift_R: return "Shift";
    case XK_Control_L:
    case XK_Control_R: return "Control";
    case XK_Alt_L:
    case XK_Alt_R: return "Alt";
    case XK_Super_L:
    case XK_Super_R: return "Super";
    default:
      static char fallback[32];
      snprintf(fallback, sizeof(fallback), "Key%lu", keysym);
      return fallback;
  }
}

static void input_capture_plugin_dispose(GObject* object) {
  InputCapturePlugin* self = INPUT_CAPTURE_PLUGIN(object);

  // Stop capture if running
  if (self->is_capturing) {
    stop_capture(self);
  }

  // Clean up display connection
  if (self->display) {
    XCloseDisplay(self->display);
    self->display = nullptr;
  }

  G_OBJECT_CLASS(input_capture_plugin_parent_class)->dispose(object);
}

static void input_capture_plugin_class_init(InputCapturePluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = input_capture_plugin_dispose;
}

static void input_capture_plugin_init(InputCapturePlugin* self) {
  self->display = XOpenDisplay(nullptr);
  self->record_display = nullptr;
  self->record_context = 0;
  self->is_capturing = false;
  self->thread_running = false;
}

void input_capture_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  InputCapturePlugin* plugin = INPUT_CAPTURE_PLUGIN(
      g_object_new(input_capture_plugin_get_type(), nullptr));

  // Create method channel
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  plugin->method_channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "com.keyboardplayground/input_capture",
      FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      plugin->method_channel, method_call_cb, plugin, nullptr);

  // Create event channel
  plugin->event_channel = fl_event_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "com.keyboardplayground/input_events",
      FL_METHOD_CODEC(codec));
  plugin->event_handler = fl_event_channel_handler_new(
      listen_cb, cancel_cb, plugin, nullptr);
  fl_event_channel_set_stream_handler(plugin->event_channel,
                                     plugin->event_handler);

  g_object_unref(plugin);
}
