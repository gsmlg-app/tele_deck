#include "include/{{package_prefix.snakeCase()}}_{{name.snakeCase()}}/{{name.snakeCase()}}_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#define {{name.constantCase()}}_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), {{name.snakeCase()}}_plugin_get_type(), \
                              {{name.pascalCase()}}Plugin))

struct _{{name.pascalCase()}}Plugin {
  GObject parent_instance;
};

G_DEFINE_TYPE({{name.pascalCase()}}Plugin, {{name.snakeCase()}}_plugin, g_object_get_type())

static void {{name.snakeCase()}}_plugin_handle_method_call(
    {{name.pascalCase()}}Plugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "getData") == 0) {
    struct utsname buffer;
    uname(&buffer);

    g_autoptr(FlValue) result = fl_value_new_map();
    fl_value_set_string_take(result, "platform", fl_value_new_string("linux"));
    fl_value_set_string_take(result, "sysname", fl_value_new_string(buffer.sysname));
    fl_value_set_string_take(result, "release", fl_value_new_string(buffer.release));
    fl_value_set_string_take(result, "version", fl_value_new_string(buffer.version));
    fl_value_set_string_take(result, "machine", fl_value_new_string(buffer.machine));

    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void {{name.snakeCase()}}_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS({{name.snakeCase()}}_plugin_parent_class)->dispose(object);
}

static void {{name.snakeCase()}}_plugin_class_init({{name.pascalCase()}}PluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = {{name.snakeCase()}}_plugin_dispose;
}

static void {{name.snakeCase()}}_plugin_init({{name.pascalCase()}}Plugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  {{name.pascalCase()}}Plugin* plugin = {{name.constantCase()}}_PLUGIN(user_data);
  {{name.snakeCase()}}_plugin_handle_method_call(plugin, method_call);
}

void {{name.snakeCase()}}_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  {{name.pascalCase()}}Plugin* plugin = {{name.constantCase()}}_PLUGIN(
      g_object_new({{name.snakeCase()}}_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "{{package_prefix.snakeCase()}}_{{name.snakeCase()}}",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
