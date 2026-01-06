#include "{{name.snakeCase()}}_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>
#include <windows.h>

namespace {{name.snakeCase()}} {

void {{name.pascalCase()}}PluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter::PluginRegistrarManager::GetInstance()
              ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar)
              ->messenger(),
          "{{package_prefix.snakeCase()}}_{{name.snakeCase()}}",
          &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name().compare("getData") == 0) {
          OSVERSIONINFOW osvi;
          ZeroMemory(&osvi, sizeof(OSVERSIONINFOW));
          osvi.dwOSVersionInfoSize = sizeof(OSVERSIONINFOW);

          flutter::EncodableMap response;
          response[flutter::EncodableValue("platform")] =
              flutter::EncodableValue("windows");

          DWORD size = MAX_COMPUTERNAME_LENGTH + 1;
          wchar_t computerName[MAX_COMPUTERNAME_LENGTH + 1];
          if (GetComputerNameW(computerName, &size)) {
            std::wstring ws(computerName);
            std::string str(ws.begin(), ws.end());
            response[flutter::EncodableValue("computerName")] =
                flutter::EncodableValue(str);
          }

          result->Success(flutter::EncodableValue(response));
        } else {
          result->NotImplemented();
        }
      });
}

}  // namespace {{name.snakeCase()}}
