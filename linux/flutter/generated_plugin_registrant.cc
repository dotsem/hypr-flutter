//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <multi_window_linux/multi_window_linux_plugin.h>
#include <wayland_layer_shell/wayland_layer_shell_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) multi_window_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "MultiWindowLinuxPlugin");
  multi_window_linux_plugin_register_with_registrar(multi_window_linux_registrar);
  g_autoptr(FlPluginRegistrar) wayland_layer_shell_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "WaylandLayerShellPlugin");
  wayland_layer_shell_plugin_register_with_registrar(wayland_layer_shell_registrar);
}
