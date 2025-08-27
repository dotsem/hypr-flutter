// File: linux/my_application.cc
// This file needs to be modified in your Flutter project's linux directory

#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X11 and not using GNOME then just use a traditional title bar
  // in case the window manager does handles the header bar badly.
  g_autoptr(GdkDisplay) display = gdk_display_get_default();
  
  // IMPORTANT: Comment out or modify the header bar setup for layer shell
  // The header bar interferes with layer shell initialization
#ifdef GDK_WINDOWING_X11
  if (GDK_IS_X11_DISPLAY(display)) {
    // For X11, we might want the header bar
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "hypr_widget");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  }
#endif
  
  // For Wayland layer shell, we don't want the header bar
  if (!GDK_IS_X11_DISPLAY(display)) {
    gtk_window_set_title(window, "hypr_widget");
    // Don't set decorations for layer shell windows
    gtk_window_set_decorated(window, FALSE);
  }

  gtk_window_set_default_size(window, 1280, 720);
  
  // CRITICAL: Don't show the window immediately for layer shell
  // Comment out or conditionally call gtk_widget_show
  // gtk_widget_show(GTK_WIDGET(window));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  // IMPORTANT: Only show the window AFTER plugin registration
  // This allows the wayland_layer_shell plugin to initialize before the window is mapped
  
  // Check if this is a layer shell window by checking command line args
  bool is_layer_shell_window = false;
  if (self->dart_entrypoint_arguments) {
    for (int i = 0; self->dart_entrypoint_arguments[i] != nullptr; i++) {
      if (g_str_has_prefix(self->dart_entrypoint_arguments[i], "taskbar_")) {
        is_layer_shell_window = true;
        break;
      }
    }
  }
  
  if (!is_layer_shell_window) {
    // Show normal windows immediately
    gtk_widget_show(GTK_WIDGET(window));
  }
  // For layer shell windows, let the plugin show the window after initialization

  gtk_window_present(window);
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application, gchar ***arguments, int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
     g_warning("Failed to register: %s", error->message);
     *exit_status = 1;
     return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", "com.example.hypr_widget",
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}