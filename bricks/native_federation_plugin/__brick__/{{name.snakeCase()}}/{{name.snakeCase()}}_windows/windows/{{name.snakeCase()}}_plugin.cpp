#include "{{name.snakeCase()}}_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <windows.h>
#include <memory>
#include <sstream>
#include <string>
#include <chrono>
#include <iomanip>

namespace {{name.snakeCase()}}_windows {

class {{name.pascalCase()}}Plugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  {{name.pascalCase()}}Plugin();

  virtual ~{{name.pascalCase()}}Plugin();

  {{name.pascalCase()}}Plugin(const {{name.pascalCase()}}Plugin&) = delete;
  {{name.pascalCase()}}Plugin& operator=(const {{name.pascalCase()}}Plugin&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  flutter::EncodableMap GetData();
  std::string GetCurrentTimestamp();

  flutter::EncodableMap cached_data_;
  bool has_cached_data_ = false;
};

void {{name.pascalCase()}}Plugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "{{package_prefix.snakeCase()}}_{{name.snakeCase()}}",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<{{name.pascalCase()}}Plugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

{{name.pascalCase()}}Plugin::{{name.pascalCase()}}Plugin() {}

{{name.pascalCase()}}Plugin::~{{name.pascalCase()}}Plugin() {}

std::string {{name.pascalCase()}}Plugin::GetCurrentTimestamp() {
  auto now = std::chrono::system_clock::now();
  auto itt = std::chrono::system_clock::to_time_t(now);
  std::ostringstream ss;
  ss << std::put_time(gmtime(&itt), "%FT%TZ");
  return ss.str();
}

flutter::EncodableMap {{name.pascalCase()}}Plugin::GetData() {
  if (has_cached_data_) {
    return cached_data_;
  }

  OSVERSIONINFOW osvi;
  ZeroMemory(&osvi, sizeof(OSVERSIONINFOW));
  osvi.dwOSVersionInfoSize = sizeof(OSVERSIONINFOW);
  GetVersionExW(&osvi);

  SYSTEM_INFO siSysInfo;
  GetSystemInfo(&siSysInfo);

  MEMORYSTATUSEX statex;
  statex.dwLength = sizeof(statex);
  GlobalMemoryStatusEx(&statex);

  flutter::EncodableMap additional_data;
  additional_data[flutter::EncodableValue("majorVersion")] =
      flutter::EncodableValue(static_cast<int>(osvi.dwMajorVersion));
  additional_data[flutter::EncodableValue("minorVersion")] =
      flutter::EncodableValue(static_cast<int>(osvi.dwMinorVersion));
  additional_data[flutter::EncodableValue("buildNumber")] =
      flutter::EncodableValue(static_cast<int>(osvi.dwBuildNumber));
  additional_data[flutter::EncodableValue("numberOfProcessors")] =
      flutter::EncodableValue(static_cast<int>(siSysInfo.dwNumberOfProcessors));
  additional_data[flutter::EncodableValue("totalPhysicalMemory")] =
      flutter::EncodableValue(static_cast<int64_t>(statex.ullTotalPhys));

  flutter::EncodableMap result;
  result[flutter::EncodableValue("platform")] = flutter::EncodableValue("windows");
  result[flutter::EncodableValue("timestamp")] =
      flutter::EncodableValue(GetCurrentTimestamp());
  result[flutter::EncodableValue("additionalData")] =
      flutter::EncodableValue(additional_data);

  cached_data_ = result;
  has_cached_data_ = true;

  return result;
}

void {{name.pascalCase()}}Plugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("getData") == 0) {
    try {
      auto data = GetData();
      result->Success(flutter::EncodableValue(data));
    } catch (const std::exception& e) {
      result->Error("ERROR", "Failed to get data: " + std::string(e.what()));
    }
  } else if (method_call.method_name().compare("refresh") == 0) {
    has_cached_data_ = false;
    cached_data_.clear();
    result->Success();
  } else {
    result->NotImplemented();
  }
}

}  // namespace {{name.snakeCase()}}_windows

void {{name.pascalCase()}}PluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  {{name.snakeCase()}}_windows::{{name.pascalCase()}}Plugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
